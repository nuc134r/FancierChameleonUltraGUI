import 'dart:typed_data';

import 'package:chameleonultragui/fork/device/slot_upload.dart';
import 'package:chameleonultragui/fork/library/card_picker.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/menu/dialogs/confirm_delete.dart';
import 'package:chameleonultragui/gui/menu/dialogs/slot/edit.dart';
import 'package:chameleonultragui/gui/menu/dialogs/slot/export.dart';
import 'package:chameleonultragui/gui/menu/pages/dump_editor.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/mifare_classic/general.dart';
import 'package:chameleonultragui/helpers/mifare_ultralight/general.dart';
import 'package:chameleonultragui/helpers/slot_dump.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Uploads [card] into [slot] with a progress dialog, then confirms with a snackbar.
// Returns true when the card was loaded.
Future<bool> uploadCardWithProgress(
  BuildContext context,
  int slot,
  CardSave card,
) async {
  final appState = context.read<ChameleonGUIState>();
  final strings = ForkStrings.of(context);
  final localizations = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final progress = ValueNotifier<double?>(null);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.uploading_dump),
            const SizedBox(height: 16),
            ValueListenableBuilder<double?>(
              valueListenable: progress,
              builder: (_, value, _) => LinearProgressIndicator(value: value),
            ),
          ],
        ),
      ),
    ),
  );

  var ok = false;
  try {
    ok = await loadCardToSlot(
      appState.communicator!,
      slot,
      card,
      fallbackName: localizations.no_name,
      onProgress: (p) => progress.value = p,
    );
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? strings.loadedToSlot(slot + 1) : strings.noEmulation,
        ),
      ),
    );
  } catch (e) {
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('${localizations.error}: $e')),
    );
  } finally {
    progress.dispose();
    appState.changesMade();
  }
  return ok;
}

// Asks which slot (1-8) to load [card] into, then uploads it.
Future<void> loadCardToChosenSlot(BuildContext context, CardSave card) async {
  final strings = ForkStrings.of(context);
  final appState = context.read<ChameleonGUIState>();
  if (!(appState.connector?.connected ?? false) ||
      appState.communicator == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(strings.connectFirst)));
    return;
  }
  var active = 0;
  try {
    active = await appState.communicator!.getActiveSlot();
  } catch (_) {}
  if (!context.mounted) return;

  final slot = await showModalBottomSheet<int>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              strings.pickSlot,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                for (var i = 0; i < 8; i++)
                  i == active
                      ? FilledButton(
                          onPressed: () => Navigator.pop(context, i),
                          child: Text('${i + 1}', style: monoStyle(context)),
                        )
                      : OutlinedButton(
                          onPressed: () => Navigator.pop(context, i),
                          child: Text('${i + 1}', style: monoStyle(context)),
                        ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  if (slot == null || !context.mounted) return;
  await uploadCardWithProgress(context, slot, card);
}

// One slot: HF and LF sides, each with its card, Load from library / Edit / Clear and an
// enable switch. Emulation options and Mfkey32 live in the (upstream) Edit dialog.
class SlotPage extends StatefulWidget {
  final int slot;

  const SlotPage({super.key, required this.slot});

  @override
  State<SlotPage> createState() => _SlotPageState();
}

class _SlotPageState extends State<SlotPage> {
  SlotTypes types = SlotTypes();
  SlotNames names = SlotNames();
  EnabledSlotInfo enabled = EnabledSlotInfo();
  bool active = false;
  bool loading = true;
  int? previousActive;
  bool keepActive = false;

  @override
  void dispose() {
    // Opening the page selected this slot; give the device back its previous active slot
    // unless the user loaded a card here (that is meant to become active).
    final previous = previousActive;
    if (!keepActive && previous != null && previous != widget.slot) {
      final appState = context.read<ChameleonGUIState>();
      if (appState.connector?.connected ?? false) {
        appState.communicator?.activateSlot(previous);
      }
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final c = context.read<ChameleonGUIState>().communicator!;
    setState(() => loading = true);
    try {
      final current = await c.getActiveSlot();
      previousActive ??= current;
      // Upstream's slot commands act on the active slot, so select this one.
      await c.activateSlot(widget.slot);
      final hfName = (await c.getSlotTagName(
        widget.slot,
        TagFrequency.hf,
      )).trim();
      final lfName = (await c.getSlotTagName(
        widget.slot,
        TagFrequency.lf,
      )).trim();
      final allTypes = await c.getSlotTagTypes();
      final allEnabled = await c.getEnabledSlots();
      if (!mounted) return;
      setState(() {
        active = previousActive == widget.slot || keepActive;
        names = SlotNames(hf: hfName, lf: lfName);
        types = allTypes[widget.slot];
        enabled = allEnabled[widget.slot];
        loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _updated(String name, TagFrequency frequency, TagType type) {
    setState(() {
      if (frequency == TagFrequency.hf) {
        names.hf = name;
        types.hf = type;
      } else {
        names.lf = name;
        types.lf = type;
      }
    });
  }

  Future<void> _loadFromLibrary(TagFrequency frequency) async {
    final card = await pickCard(context, frequency: frequency);
    if (card == null || !mounted) return;
    if (await uploadCardWithProgress(context, widget.slot, card)) {
      keepActive = true;
    }
    if (mounted) _load();
  }

  Future<void> _edit(TagFrequency frequency) async {
    final hf = frequency == TagFrequency.hf;
    await showDialog<void>(
      context: context,
      builder: (_) => SlotEditMenu(
        name: hf ? names.hf : names.lf,
        isEnabled: hf ? enabled.hf : enabled.lf,
        slotType: hf ? types.hf : types.lf,
        frequency: frequency,
        slot: widget.slot,
        update: _updated,
      ),
    );
  }

  Future<void> _clear(TagFrequency frequency) async {
    final appState = context.read<ChameleonGUIState>();
    final localizations = AppLocalizations.of(context)!;
    final hf = frequency == TagFrequency.hf;
    if (appState.sharedPreferencesProvider.getConfirmDelete()) {
      final confirm = await showDialog(
        context: context,
        builder: (_) =>
            ConfirmDeletionMenu(thingBeingDeleted: hf ? names.hf : names.lf),
      );
      if (confirm != true) return;
    }
    final c = appState.communicator!;
    await c.deleteSlotInfo(widget.slot, frequency);
    await c.setSlotTagName(widget.slot, localizations.empty, frequency);
    await c.saveSlotData();
    _load();
  }

  Future<void> _setEnabled(TagFrequency frequency, bool value) async {
    await context.read<ChameleonGUIState>().communicator!.enableSlot(
      widget.slot,
      frequency,
      value,
    );
    setState(() {
      if (frequency == TagFrequency.hf) {
        enabled.hf = value;
      } else {
        enabled.lf = value;
      }
    });
  }

  Future<void> _viewData() async {
    final appState = context.read<ChameleonGUIState>();
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(localizations.please_wait)),
          ],
        ),
      ),
    );
    CardSave card;
    try {
      await appState.communicator!.activateSlot(widget.slot);
      card = await readHfDumpFromSlot(
        appState.communicator!,
        names.hf,
        types.hf,
      );
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${localizations.error}: $e')),
      );
      return;
    }
    navigator.pop();
    if (!mounted) return;

    List<Uint8List>? edited;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            DumpEditor(cardSave: card, onSave: (dump) => edited = dump),
      ),
    );
    if (edited == null || !mounted) return;

    final progress = ValueNotifier<double?>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.uploading_dump),
            const SizedBox(height: 16),
            ValueListenableBuilder<double?>(
              valueListenable: progress,
              builder: (_, value, _) => LinearProgressIndicator(value: value),
            ),
          ],
        ),
      ),
    );
    try {
      await writeHfDumpToSlot(
        appState.communicator!,
        widget.slot,
        types.hf,
        edited!,
        onProgress: (p) => progress.value = p / 100,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${localizations.error}: $e')),
      );
    } finally {
      navigator.pop();
      progress.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasData = isMifareClassic(types.hf) || isMifareUltralight(types.hf);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.slotN(widget.slot + 1)),
        actions: [
          if (types.notMatch())
            IconButton(
              tooltip: strings.saveToLibrary,
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SlotExportMenu(
                  names: names,
                  enabledSlotInfo: enabled,
                  slotTypes: types,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: loading
              ? const LinearProgressIndicator(minHeight: 2)
              : const SizedBox(height: 2),
        ),
      ),
      body: loading && types.hf == TagType.unknown && names.hf.isEmpty
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Side(
                  label: 'HF · 13.56 MHz',
                  type: types.hf,
                  name: names.hf,
                  enabled: enabled.hf,
                  onEnabled: (v) => _setEnabled(TagFrequency.hf, v),
                  onLoad: () => _loadFromLibrary(TagFrequency.hf),
                  onEdit: () => _edit(TagFrequency.hf),
                  onClear: () => _clear(TagFrequency.hf),
                  onViewData: hasData ? _viewData : null,
                ),
                const Divider(height: 32),
                _Side(
                  label: 'LF · 125 kHz',
                  type: types.lf,
                  name: names.lf,
                  enabled: enabled.lf,
                  onEnabled: (v) => _setEnabled(TagFrequency.lf, v),
                  onLoad: () => _loadFromLibrary(TagFrequency.lf),
                  onEdit: () => _edit(TagFrequency.lf),
                  onClear: () => _clear(TagFrequency.lf),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Text(
                    strings.emulationOptions,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Side extends StatelessWidget {
  final String label;
  final TagType type;
  final String name;
  final bool enabled;
  final ValueChanged<bool> onEnabled;
  final VoidCallback onLoad;
  final VoidCallback onEdit;
  final VoidCallback onClear;
  final VoidCallback? onViewData;

  const _Side({
    required this.label,
    required this.type,
    required this.name,
    required this.enabled,
    required this.onEnabled,
    required this.onLoad,
    required this.onEdit,
    required this.onClear,
    this.onViewData,
  });

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final empty = type == TagType.unknown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          label,
          trailing: Switch(value: enabled, onChanged: onEnabled),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                empty
                    ? strings.slotEmpty
                    : (name.isEmpty ? localizations.no_name : name),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: empty ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
              if (!empty)
                Text(
                  chameleonTagToString(type, localizations),
                  style: monoStyle(
                    context,
                    size: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onLoad,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: Text(strings.loadFromLibrary),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(strings.editSlot),
              ),
              if (onViewData != null)
                OutlinedButton.icon(
                  onPressed: onViewData,
                  icon: const Icon(Icons.grid_on),
                  label: Text(strings.viewData),
                ),
              if (!empty)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: onClear,
                  icon: const Icon(Icons.clear),
                  label: Text(strings.clearSlot),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
