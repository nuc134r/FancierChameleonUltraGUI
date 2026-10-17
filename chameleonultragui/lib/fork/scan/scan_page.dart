import 'dart:async';

import 'package:chameleonultragui/connector/serial_abstract.dart';
import 'package:chameleonultragui/fork/library/save_card_sheet.dart';
import 'package:chameleonultragui/fork/shell.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/component/mifare/classic.dart';
import 'package:chameleonultragui/gui/component/mifare/ultralight.dart';
import 'package:chameleonultragui/gui/page/read_card.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/mifare_classic/general.dart';
import 'package:chameleonultragui/helpers/mifare_ultralight/general.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Scan tab: HF | LF switch, one Scan button, Keep scanning toggle, and the result as a card
// with copyable identifiers. Saving goes through the Save to library sheet. For MIFARE Classic
// and Ultralight the follow-up steps are upstream's own panels, shown unchanged under the result.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  static bool lf = false; // remembered across tab switches

  HFCardInfo? hf;
  MifareClassicInfo mfc = MifareClassicInfo();
  MifareUltralightInfo mfu = MifareUltralightInfo();
  LFCard? lfCard;
  bool notFound = false;
  bool busy = false;
  Timer? timer;
  DateTime? timerStarted;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  ChameleonGUIState get appState => context.read<ChameleonGUIState>();

  void _clear() {
    hf = null;
    mfc = MifareClassicInfo();
    mfu = MifareUltralightInfo();
    lfCard = null;
    notFound = false;
  }

  Future<bool> _readOnce() async {
    if (lf) {
      final c = appState.communicator!;
      if (!await c.isReaderDeviceMode()) await c.setReaderDeviceMode(true);
      LFCard? card = await c.readEM410X();
      card ??= await c.readHIDProx();
      card ??= await c.readViking();
      card ??= await c.readPac();
      card ??= await c.readIoProx();
      if (!mounted) return false;
      setState(() {
        lfCard = card;
        notFound = card == null;
      });
      return card != null;
    }
    final info = await readHFInfo(context, () {
      if (mounted) setState(() {});
    });
    if (!mounted) return false;
    final found = info.$1.cardExist && info.$1.uid.isNotEmpty;
    setState(() {
      hf = found ? info.$1 : null;
      mfc = info.$2;
      mfu = info.$3;
      notFound = !found;
    });
    return found;
  }

  Future<void> _scan() async {
    if (busy) return;
    setState(() {
      busy = true;
      _clear();
    });
    try {
      await _readOnce();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _toggleKeepScanning() {
    if (timer != null) {
      _stopKeepScanning();
      return;
    }
    setState(() {
      _clear();
      timerStarted = DateTime.now();
      timer = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (busy) return;
        if (!mounted ||
            DateTime.now().difference(timerStarted!) >
                const Duration(minutes: 1)) {
          _stopKeepScanning();
          return;
        }
        busy = true;
        try {
          if (await _readOnce()) _stopKeepScanning();
        } catch (_) {
        } finally {
          busy = false;
        }
      });
    });
  }

  void _stopKeepScanning() {
    timer?.cancel();
    if (mounted) setState(() => timer = null);
  }

  String _defaultName(TagType type, String uid) {
    final localizations = AppLocalizations.of(context)!;
    final short = chameleonTagToString(
      type,
      localizations,
    ).replaceAll('Mifare Classic', 'MFC').replaceAll(' ', '');
    final name = '$short ${uid.replaceAll(' ', '')}';
    return name.length > 19 ? name.substring(0, 19) : name;
  }

  Future<void> _saveIdentifiers() {
    final localizations = AppLocalizations.of(context)!;
    final info = hf!;
    final type = info.type != TagType.unknown ? info.type : TagType.mifare1K;
    return saveCardToLibrary(
      context,
      CardSave(
        uid: info.uid,
        sak: hexToBytes(info.sak)[0],
        atqa: hexToBytes(info.atqa),
        ats: info.ats != localizations.no ? hexToBytes(info.ats) : Uint8List(0),
        name: _defaultName(type, info.uid),
        tag: type,
        data: [],
        extraData: CardSaveExtra(
          ultralightSignature: mfu.signature,
          ultralightVersion: mfu.version,
          ultralightCounters: [],
        ),
      ),
    );
  }

  Future<void> _saveLf() => saveCardToLibrary(
    context,
    CardSave(
      uid: lfCard.toString(),
      name: _defaultName(lfCard!.type, lfCard.toString()),
      tag: lfCard!.type,
    ),
  );

  Future<void> _overrideType() async {
    final localizations = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<TagType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text(
                localizations.override_card_type,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(localizations.override_card_type_description),
            ),
            for (final t in getTagTypesByFrequency(TagFrequency.hf))
              ListTile(
                title: Text(chameleonTagToString(t, localizations)),
                trailing: t == hf!.type ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, t),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final c = appState.communicator!;
    setState(() {
      hf!.type = picked;
      hf!.tech = chameleonTagToString(picked, localizations);
    });
    if (isMifareClassic(picked)) {
      final info = await performMifareClassicScan(
        c,
        mfc,
        context,
        () => setState(() {}),
        override: picked,
      );
      if (mounted) setState(() => mfc = info.$2);
    } else if (isMifareUltralight(picked)) {
      final info = await performMifareUltralightScan(c, mfu, override: picked);
      if (mounted) setState(() => mfu = info.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final lite = appState.connector!.device == ChameleonDevice.lite;
    final scanning = busy || timer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.scan),
        actions: [
          if (hf != null && !lf)
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.tune),
                  onPressed: _overrideType,
                  child: Text(localizations.override_card_type),
                ),
              ],
              builder: (context, controller, _) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          const SettingsButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: scanning
              ? const LinearProgressIndicator(minHeight: 2)
              : const SizedBox(height: 2),
        ),
      ),
      body: lite
          ? EmptyState(
              icon: Icons.sensors_off_outlined,
              title: localizations.no_supported,
              hint: localizations.lite_no_read,
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('HF · 13.56 MHz'),
                      ),
                      ButtonSegment(value: true, label: Text('LF · 125 kHz')),
                    ],
                    selected: {lf},
                    onSelectionChanged: scanning
                        ? null
                        : (v) => setState(() {
                            lf = v.first;
                            _clear();
                          }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: scanning ? null : _scan,
                          icon: const Icon(Icons.sensors),
                          label: Text(
                            hf != null || lfCard != null
                                ? strings.scanAgain
                                : strings.scanAction,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: busy && timer == null
                              ? null
                              : _toggleKeepScanning,
                          icon: Icon(
                            timer != null
                                ? Icons.stop_circle_outlined
                                : Icons.autorenew,
                          ),
                          label: Text(
                            timer != null
                                ? strings.stopScanning
                                : strings.keepScanning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._result(context),
              ],
            ),
    );
  }

  List<Widget> _result(BuildContext context) {
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;

    if (notFound && timer == null) {
      return [
        const SizedBox(height: 40),
        EmptyState(
          icon: Icons.search_off,
          title: localizations.no_card_found,
          hint: strings.tryAnotherCard,
        ),
      ];
    }

    if (lf && lfCard != null) {
      final card = lfCard!;
      return [
        _ResultHeader(
          title: chameleonTagToString(card.type, localizations),
          freq: 'LF · 125 kHz',
        ),
        _CopyRow(label: localizations.uid, value: card.toString()),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: _saveLf,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(strings.saveToLibrary),
          ),
        ),
      ];
    }

    if (!lf && hf != null) {
      final info = hf!;
      final classic = isMifareClassic(info.type);
      final ultralight = isMifareUltralight(info.type);
      final chips = <String>[
        if (classic && mfc.ntLevel != null)
          '${localizations.prng_type}: ${mfClassicGetPrngType(mfc.ntLevel!, localizations)}',
        if (classic && mfc.hasBackdoor == true) strings.backdoor,
        if (mfc.isEV1) strings.ev1,
      ];
      return [
        _ResultHeader(
          title: info.tech.isEmpty
              ? chameleonTagToString(info.type, localizations)
              : info.tech,
          freq: 'HF · 13.56 MHz',
          chips: chips,
        ),
        _CopyRow(label: localizations.uid, value: info.uid),
        _CopyRow(label: localizations.sak, value: info.sak),
        _CopyRow(label: localizations.atqa, value: info.atqa),
        _CopyRow(
          label: localizations.ats,
          value: info.ats == localizations.no ? '' : info.ats,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: _saveIdentifiers,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(
              classic || ultralight
                  ? localizations.save_only_uid
                  : strings.saveToLibrary,
            ),
          ),
        ),
        if (classic) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MifareClassicHelper(hfInfo: info, mfcInfo: mfc),
          ),
        ],
        if (ultralight) ...[
          SectionLabel(localizations.dump_card),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MifareUltralightHelper(hfInfo: info),
          ),
        ],
      ];
    }

    if (timer != null || busy) return const [];
    return [
      const SizedBox(height: 40),
      EmptyState(
        icon: Icons.contactless_outlined,
        title: strings.holdCard,
        hint: lf ? strings.holdCardLf : strings.holdCardHf,
      ),
    ];
  }
}

class _ResultHeader extends StatelessWidget {
  final String title;
  final String freq;
  final List<String> chips;

  const _ResultHeader({
    required this.title,
    required this.freq,
    this.chips = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            freq.toUpperCase(),
            style: monoStyle(
              context,
              size: 11.5,
              color: scheme.primary,
            ).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final c in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      c,
                      style: monoStyle(
                        context,
                        size: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ForkStrings.of(context);
    return InkWell(
      onTap: value.isEmpty
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('${strings.copied}: $value'),
                    duration: const Duration(seconds: 1),
                  ),
                );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                label,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? '—' : value,
                style: monoStyle(context, size: 15),
              ),
            ),
            if (value.isNotEmpty)
              Icon(Icons.copy, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
