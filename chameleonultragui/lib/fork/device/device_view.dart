import 'package:chameleonultragui/connector/serial_abstract.dart';
import 'package:chameleonultragui/fork/device/device_settings_page.dart';
import 'package:chameleonultragui/fork/device/slot_page.dart';
import 'package:chameleonultragui/fork/shell.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/flash.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/github.dart';
import 'package:chameleonultragui/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SlotInfo {
  TagType hf;
  TagType lf;
  String hfName;
  String lfName;
  bool hfEnabled;
  bool lfEnabled;

  SlotInfo(
    this.hf,
    this.lf,
    this.hfName,
    this.lfName,
    this.hfEnabled,
    this.lfEnabled,
  );

  bool get used => hf != TagType.unknown || lf != TagType.unknown;
}

class _DeviceStatus {
  final BatteryCharge? battery;
  final FirmwareVersion firmware;
  final String commit;
  final bool capabilitiesOk;
  final bool readerMode;
  final int activeSlot;
  final List<SlotInfo> slots;

  _DeviceStatus(
    this.battery,
    this.firmware,
    this.commit,
    this.capabilitiesOk,
    this.readerMode,
    this.activeSlot,
    this.slots,
  );
}

// Device tab while connected: status header with the mode icon, and the 8 slots.
class DeviceView extends StatefulWidget {
  const DeviceView({super.key});

  @override
  State<DeviceView> createState() => _DeviceViewState();
}

class _DeviceViewState extends State<DeviceView> {
  late Future<_DeviceStatus> status = _load();

  Future<_DeviceStatus> _load() async {
    final appState = context.read<ChameleonGUIState>();
    final c = appState.communicator!;

    BatteryCharge? battery;
    try {
      battery = await c.getBatteryCharge();
    } catch (_) {}
    final firmware = await c.getFirmwareVersion();
    var commit = '';
    try {
      commit = await c.getGitCommitHash();
    } catch (_) {}

    var capabilitiesOk = true;
    try {
      final caps = await c.getDeviceCapabilities();
      final needed = appState.connector!.device == ChameleonDevice.lite
          ? ChameleonCommand.setIdteckEmulatorID.value
          : ChameleonCommand.mf0UlcAuth.value;
      capabilitiesOk = caps.contains(needed);
    } catch (_) {
      capabilitiesOk = false;
    }

    final readerMode = await c.isReaderDeviceMode();
    var active = 0;
    try {
      active = await c.getActiveSlot();
    } catch (_) {}

    final types = await c.getSlotTagTypes();
    final enabled = await c.getEnabledSlots();
    final names = await c.getSlotTagNames();
    final slots = [
      for (var i = 0; i < 8; i++)
        SlotInfo(
          types[i].hf,
          types[i].lf,
          names[i].hf.trim(),
          names[i].lf.trim(),
          enabled[i].hf,
          enabled[i].lf,
        ),
    ];
    return _DeviceStatus(
      battery,
      firmware,
      commit,
      capabilitiesOk,
      readerMode,
      active,
      slots,
    );
  }

  void reload() => setState(() => status = _load());

  Future<void> _setReaderMode(bool reader) async {
    await context.read<ChameleonGUIState>().communicator!.setReaderDeviceMode(
      reader,
    );
    reload();
  }

  Future<void> _showModeSheet(bool readerMode) async {
    final reader = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ModeSheet(readerMode: readerMode),
    );
    if (reader != null && reader != readerMode) await _setReaderMode(reader);
  }

  Future<void> _setActive(int slot) async {
    await context.read<ChameleonGUIState>().communicator!.activateSlot(slot);
    reload();
  }

  Future<void> _checkForUpdate(String currentCommit) async {
    final appState = context.read<ChameleonGUIState>();
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final model = chameleonDeviceName(appState.connector!.device);
    try {
      final latest = await latestAvailableCommit(appState.connector!.device);
      var current = currentCommit;
      try {
        current = await resolveCommit(currentCommit);
      } catch (_) {}
      if (latest.isEmpty) return;
      if (current.isNotEmpty && latest.startsWith(current)) {
        messenger.showSnackBar(
          SnackBar(content: Text(localizations.up_to_date(model))),
        );
        return;
      }
      await _flashLatest();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${localizations.update_error}: $e')),
      );
    }
  }

  Future<void> _flashLatest() async {
    final appState = context.read<ChameleonGUIState>();
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          localizations.downloading_fw(
            chameleonDeviceName(appState.connector!.device),
          ),
        ),
      ),
    );
    try {
      await flashFirmware(appState, scaffoldMessenger: messenger);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${localizations.update_error}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<_DeviceStatus>(
      future: status,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.device),
            actions: [
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.tune),
                    onPressed: () => pushDeviceRoute(
                      context,
                      'settings',
                      const DeviceSettingsPage(),
                    ),
                    child: Text(localizations.device_settings),
                  ),
                  if (appState.connector!.portName != 'Demo')
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.system_update),
                      onPressed: data == null
                          ? null
                          : () => _checkForUpdate(data.commit),
                      child: Text(localizations.check_updates),
                    ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.link_off),
                    onPressed: () => appState.disconnect(manual: true),
                    child: Text(strings.disconnect),
                  ),
                ],
                builder: (context, controller, _) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                ),
              ),
              const SettingsButton(),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox(height: 2),
            ),
          ),
          body: snapshot.hasError
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: strings.connectionFailed,
                  hint: snapshot.error.toString(),
                  action: FilledButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.retry),
                  ),
                )
              : data == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: () async {
                    reload();
                    await status;
                  },
                  child: _content(context, appState, data),
                ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    ChameleonGUIState appState,
    _DeviceStatus data,
  ) {
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final connector = appState.connector!;
    final demo = connector.portName == 'Demo';
    final used = data.slots.where((s) => s.used).length;
    final ble = connector.connectionType == ConnectionType.ble;

    final details = [
      connector.portName,
      ble ? 'BLE' : 'USB',
      if (data.battery != null) '${data.battery!.percent}%',
      'fw ${numToVerCode(data.firmware.version)}'
          '${data.commit.isEmpty ? '' : ' (${data.commit})'}',
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  ble ? Icons.bluetooth : Icons.usb,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chameleon ${chameleonDeviceName(connector.device)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: monoStyle(
                        context,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _ModeButton(
                readerMode: data.readerMode,
                onPressed: () => _showModeSheet(data.readerMode),
              ),
            ],
          ),
        ),
        if (demo)
          _Banner(icon: Icons.science_outlined, text: strings.demoDevice)
        else if (data.firmware.legacyProtocol || !data.capabilitiesOk)
          _Banner(
            icon: Icons.system_update,
            text: data.firmware.legacyProtocol
                ? strings.outdatedProtocol
                : localizations.please_update_firmware,
            action: TextButton(
              onPressed: _flashLatest,
              child: Text(localizations.update),
            ),
          ),
        SectionLabel(strings.slotsUsed(used)),
        for (var i = 0; i < 8; i++)
          _SlotRow(
            index: i,
            slot: data.slots[i],
            active: i == data.activeSlot,
            onOpen: () async {
              await pushDeviceRoute(context, 'slot', SlotPage(slot: i));
              if (mounted) reload();
            },
            onSetActive: () => _setActive(i),
          ),
      ],
    );
  }
}

IconData _modeIcon(bool readerMode) =>
    readerMode ? Icons.barcode_reader : Icons.contactless_outlined;

// Small Emulate / Read status icon in the header; opens the mode sheet.
class _ModeButton extends StatelessWidget {
  final bool readerMode;
  final VoidCallback onPressed;

  const _ModeButton({required this.readerMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message:
          '${strings.deviceMode}: '
          '${readerMode ? strings.modeRead : strings.modeEmulate}',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_modeIcon(readerMode), size: 20, color: scheme.primary),
              const SizedBox(height: 2),
              Text(
                (readerMode ? strings.modeRead : strings.modeEmulate)
                    .toUpperCase(),
                style: monoStyle(
                  context,
                  size: 9,
                  color: scheme.onSurfaceVariant,
                ).copyWith(letterSpacing: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Explains the two modes and lets the user pick one; pops with the choice.
class _ModeSheet extends StatelessWidget {
  final bool readerMode;

  const _ModeSheet({required this.readerMode});

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget option(bool reader, String title, String hint) {
      final selected = reader == readerMode;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Material(
          color: selected
              ? scheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => Navigator.pop(context, reader),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _modeIcon(reader),
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.check, color: scheme.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              strings.deviceMode,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          option(false, strings.modeEmulate, strings.modeEmulateHint),
          option(true, strings.modeRead, strings.modeReadHint),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.modeAutoHint,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Banner({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final int index;
  final SlotInfo slot;
  final bool active;
  final VoidCallback onOpen;
  final VoidCallback onSetActive;

  const _SlotRow({
    required this.index,
    required this.slot,
    required this.active,
    required this.onOpen,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    String side(TagType type, String name, bool enabled) {
      if (type == TagType.unknown) return strings.slotEmpty;
      final label = name.isEmpty ? localizations.no_name : name;
      final off = enabled ? '' : ' · ${strings.slotDisabled}';
      return '$label · ${chameleonTagToString(type, localizations)}$off';
    }

    Widget line(String freq, TagType type, String name, bool enabled) {
      final empty = type == TagType.unknown;
      return Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              freq,
              style: monoStyle(
                context,
                size: 10.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              side(type, name, enabled),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: empty || !enabled
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onOpen,
      onLongPress: active ? null : onSetActive,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 3,
              color: active ? scheme.primary : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? scheme.primary
                    : slot.used
                    ? scheme.surfaceContainerHigh
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active ? scheme.primary : scheme.outlineVariant,
                ),
              ),
              child: Text(
                '${index + 1}',
                style: monoStyle(
                  context,
                  size: 15,
                  color: active ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line('HF', slot.hf, slot.hfName, slot.hfEnabled),
                  const SizedBox(height: 2),
                  line('LF', slot.lf, slot.lfName, slot.lfEnabled),
                ],
              ),
            ),
            if (active)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  strings.active.toUpperCase(),
                  style: monoStyle(
                    context,
                    size: 10.5,
                    color: scheme.primary,
                  ).copyWith(letterSpacing: 1),
                ),
              ),
            MenuAnchor(
              menuChildren: [
                if (!active)
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.radio_button_checked),
                    onPressed: onSetActive,
                    child: Text(strings.setActive),
                  ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.chevron_right),
                  onPressed: onOpen,
                  child: Text(strings.editSlot),
                ),
              ],
              builder: (context, controller, _) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
