import 'package:chameleonultragui/fork/device/slot_page.dart';
import 'package:chameleonultragui/fork/library/card_form_page.dart';
import 'package:chameleonultragui/fork/library/library_actions.dart';
import 'package:chameleonultragui/fork/shell.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/menu/dialogs/dictionary/export.dart';
import 'package:chameleonultragui/gui/menu/pages/dump_editor.dart';
import 'package:chameleonultragui/gui/page/write_card.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/mifare_classic/dump_highlighter.dart';
import 'package:chameleonultragui/helpers/mifare_classic/general.dart';
import 'package:chameleonultragui/helpers/mifare_ultralight/dump_highlighter.dart';
import 'package:chameleonultragui/helpers/mifare_ultralight/general.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:chameleonultragui/fork/library/ndef_tab.dart';
import 'package:chameleonultragui/helpers/ndef.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> openCardPage(BuildContext context, CardSave card) {
  return Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => CardPage(cardId: card.id)));
}

// One page per saved card: Info (identifiers), Data (the dump, the only way into it) and,
// for MIFARE Classic, Keys. Editing the dump opens upstream's Dump Editor from the Data tab.
class CardPage extends StatefulWidget {
  final String cardId;

  const CardPage({super.key, required this.cardId});

  @override
  State<CardPage> createState() => _CardPageState();
}

enum _CardTab { info, data, keys, ndef }

class _CardPageState extends State<CardPage> with TickerProviderStateMixin {
  TabController? tabs;
  List<_CardTab> tabList = const [];

  void _syncTabs(List<_CardTab> wanted) {
    if (tabs != null && listEquals(wanted, tabList)) return;
    final previous = tabs?.index ?? 0;
    tabs?.dispose();
    tabList = wanted;
    tabs = TabController(
      length: wanted.length,
      vsync: this,
      initialIndex: previous.clamp(0, wanted.length - 1),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    tabs?.dispose();
    super.dispose();
  }

  void _editData(CardSave card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DumpEditor(
          cardSave: card,
          onSave: (dump) {
            final appState = context.read<ChameleonGUIState>();
            final cards = appState.sharedPreferencesProvider.getCards();
            for (final c in cards.where((c) => c.id == card.id)) {
              c.data = dump;
            }
            appState.sharedPreferencesProvider.setCards(cards);
            appState.changesMade();
          },
        ),
      ),
    );
  }

  void _writeToTag(CardSave card) {
    final appState = context.read<ChameleonGUIState>();
    if (!(appState.connector?.connected ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ForkStrings.of(context).connectFirst)),
      );
      return;
    }
    pushDeviceRoute(context, 'write', WriteCardPage(initialCard: card));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final card = appState.sharedPreferencesProvider
        .getCards()
        .where((c) => c.id == widget.cardId)
        .firstOrNull;

    if (card == null) {
      // Deleted (here or elsewhere): leave the page.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }

    final classic = isMifareClassic(card.tag);
    _syncTabs([
      _CardTab.info,
      if (card.data.isNotEmpty) _CardTab.data,
      if (classic && card.data.isNotEmpty) _CardTab.keys,
      if (card.data.isNotEmpty &&
          NdefContainer.detect(card.tag, card.data) != null)
        _CardTab.ndef,
    ]);
    final current = tabList[tabs!.index];
    final canEditData =
        card.data.isNotEmpty && (classic || isMifareUltralight(card.tag));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: card.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name.isEmpty ? '—' : card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    chameleonTagToString(card.tag, localizations),
                    style: monoStyle(
                      context,
                      size: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (current == _CardTab.ndef)
            IconButton(
              tooltip: strings.edit,
              icon: const Icon(Icons.edit_note),
              onPressed: () => editNdef(context, card),
            )
          else if (current == _CardTab.data && canEditData)
            IconButton(
              tooltip: strings.editData,
              icon: const Icon(Icons.edit_note),
              onPressed: () => _editData(card),
            )
          else
            IconButton(
              tooltip: strings.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => openCardForm(context, card: card),
            ),
          MenuAnchor(
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.copy_all_outlined),
                onPressed: () {
                  final copy = LibraryActions.duplicateCard(context, card);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => CardPage(cardId: copy.id),
                    ),
                  );
                },
                child: Text(strings.duplicate),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.drive_file_move_outline),
                onPressed: () => LibraryActions.moveCard(context, card),
                child: Text(strings.move),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.file_download_outlined),
                onPressed: () => saveTag(card, context, false),
                child: Text(strings.exportJson),
              ),
              if (card.data.isNotEmpty)
                MenuItemButton(
                  leadingIcon: const Icon(Icons.file_download_outlined),
                  onPressed: () => saveTag(card, context, true),
                  child: Text(strings.exportBin),
                ),
              MenuItemButton(
                leadingIcon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: () => LibraryActions.deleteCard(context, card),
                child: Text(
                  strings.delete,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
            builder: (context, controller, _) => IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            ),
          ),
        ],
        bottom: tabList.length > 1
            ? TabBar(
                controller: tabs,
                tabs: [
                  for (final t in tabList)
                    Tab(
                      text: switch (t) {
                        _CardTab.info => strings.info,
                        _CardTab.data => strings.data,
                        _CardTab.keys => strings.keys,
                        _CardTab.ndef => strings.ndef,
                      },
                    ),
                ],
              )
            : null,
      ),
      body: TabBarView(
        controller: tabs,
        children: [
          for (final t in tabList)
            switch (t) {
              _CardTab.info => _InfoTab(card: card),
              _CardTab.data => _DataTab(card: card),
              _CardTab.keys => _KeysTab(card: card),
              _CardTab.ndef => NdefTab(card: card),
            },
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => loadCardToChosenSlot(context, card),
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: Text(strings.loadToSlot),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _writeToTag(card),
                  icon: const Icon(Icons.system_update_alt),
                  label: Text(strings.writeToTag),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _copy(BuildContext context, String value) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${ForkStrings.of(context).copied}: $value'),
      duration: const Duration(seconds: 2),
    ),
  );
}

class _InfoTab extends StatelessWidget {
  final CardSave card;

  const _InfoTab({required this.card});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hf = chameleonTagToFrequency(card.tag) == TagFrequency.hf;
    final extra = card.extraData;

    final rows = <(String, String?)>[
      (localizations.tag_type, chameleonTagToString(card.tag, localizations)),
      (localizations.uid, card.uid.isEmpty ? null : card.uid),
      if (hf) ...[
        (localizations.sak, bytesToHex(u8ToBytes(card.sak))),
        (
          localizations.atqa,
          card.atqa.isEmpty ? null : bytesToHexSpace(card.atqa),
        ),
        (
          localizations.ats,
          card.ats.isEmpty ? null : bytesToHexSpace(card.ats),
        ),
      ],
      if (isMifareUltralight(card.tag)) ...[
        (
          localizations.ultralight_version,
          extra.ultralightVersion.isEmpty
              ? null
              : bytesToHexSpace(extra.ultralightVersion),
        ),
        (
          localizations.ultralight_signature,
          extra.ultralightSignature.isEmpty
              ? null
              : bytesToHexSpace(extra.ultralightSignature),
        ),
      ],
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionLabel(
          hf ? 'HF · 13.56 MHz' : 'LF · 125 kHz',
          trailing: Text(
            strings.tapToCopy,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        for (final (label, value) in rows)
          InkWell(
            onTap: value == null ? null : () => _copy(context, value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      label,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value ?? localizations.unavailable,
                      style: monoStyle(
                        context,
                        size: 14.5,
                        color: value == null
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (value != null)
                    Icon(Icons.copy, size: 16, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        if (card.data.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.noData,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

String _ascii(Uint8List block) =>
    String.fromCharCodes(block.map((b) => b >= 0x20 && b < 0x7F ? b : 0x2E));

class _DataTab extends StatefulWidget {
  final CardSave card;

  const _DataTab({required this.card});

  @override
  State<_DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<_DataTab> {
  bool ascii = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final classic = isMifareClassic(card.tag);
    final ultralight = isMifareUltralight(card.tag);

    TextSpan line(int index, Uint8List block, int sector, bool trailer) {
      final hex = bytesToHexSpace(block);
      List<TextSpan> spans;
      if (ascii || block.isEmpty) {
        spans = [TextSpan(text: block.isEmpty ? '--' : _ascii(block))];
      } else if (classic) {
        spans = trailer
            ? MifareClassicDumpHighlighter.highlightSectorTrailer(hex, context)
            : index == 0
            ? MifareClassicDumpHighlighter.highlightFirstBlock(hex, context)
            : MifareClassicDumpHighlighter.highlightDataBlock(hex, context);
      } else if (ultralight) {
        spans = MifareUltralightDumpHighlighter.highlightBlock(
          hex,
          index,
          context,
          card,
        );
      } else {
        spans = [TextSpan(text: hex)];
      }
      return TextSpan(
        children: [
          TextSpan(
            text: '${index.toString().padLeft(3)} ',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          ...spans,
        ],
      );
    }

    Widget block(List<TextSpan> lines) => Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText.rich(
          TextSpan(
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const TextSpan(text: '\n'),
                lines[i],
              ],
            ],
          ),
          style: monoStyle(context, size: 11.5, color: scheme.onSurface),
        ),
      ),
    );

    final sections = <Widget>[];
    if (classic) {
      var sector = 0;
      var first = 0;
      while (first < card.data.length) {
        final count = mfClassicGetBlockCountBySector(sector);
        final last = (first + count - 1).clamp(0, card.data.length - 1);
        sections
          ..add(SectionLabel(strings.sectorLabel(sector, first, last)))
          ..add(
            block([
              for (var b = first; b <= last; b++)
                line(b, card.data[b], sector, b == first + count - 1),
            ]),
          );
        first += count;
        sector++;
      }
    } else {
      sections
        ..add(SectionLabel(strings.pages(card.data.length)))
        ..add(
          block([
            for (var i = 0; i < card.data.length; i++)
              line(i, card.data[i], 0, false),
          ]),
        );
    }

    // The HEX / ASCII bar stays pinned; only the dump scrolls.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(strings.hex)),
                  ButtonSegment(value: true, label: Text(strings.ascii)),
                ],
                selected: {ascii},
                onSelectionChanged: (value) =>
                    setState(() => ascii = value.first),
              ),
              const Spacer(),
              if (classic || ultralight)
                IconButton(
                  tooltip: strings.legend,
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showLegend(context, classic),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: sections,
          ),
        ),
      ],
    );
  }

  void _showLegend(BuildContext context, bool classic) {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final entries = classic
        ? [
            (
              localizations.uid,
              MifareClassicDumpHighlighter.getUidColor(context),
            ),
            (
              localizations.value_block,
              MifareClassicDumpHighlighter.getValueBlockColor(context),
            ),
            (strings.keyA, MifareClassicDumpHighlighter.getKeyAColor(context)),
            (
              localizations.access_conditions,
              MifareClassicDumpHighlighter.getAccessConditionsColor(context),
            ),
            (strings.keyB, MifareClassicDumpHighlighter.getKeyBColor(context)),
          ]
        : [
            (
              localizations.uid,
              MifareUltralightDumpHighlighter.getUidColor(context),
            ),
            (
              localizations.bcc,
              MifareUltralightDumpHighlighter.getBccColor(context),
            ),
            (
              localizations.lock_bytes,
              MifareUltralightDumpHighlighter.getLockColor(context),
            ),
            (
              localizations.password,
              MifareUltralightDumpHighlighter.getPasswordColor(context),
            ),
          ];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, color) in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(label),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeysTab extends StatelessWidget {
  final CardSave card;

  const _KeysTab({required this.card});

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final rows = <(int, Uint8List, Uint8List)>[];
    for (var sector = 0; sector < 40; sector++) {
      final trailer = mfClassicGetSectorTrailerBlockBySector(sector);
      if (trailer >= card.data.length) break;
      final block = card.data[trailer];
      if (block.length < 16) continue;
      rows.add((sector, block.sublist(0, 6), block.sublist(10, 16)));
    }
    if (rows.isEmpty) {
      return EmptyState(icon: Icons.key_off_outlined, title: strings.noKeys);
    }

    final keyStyle = monoStyle(context, size: 13.5);
    Widget keyCell(Uint8List key, Color color) => InkWell(
      onTap: () => _copy(context, bytesToHex(key).toUpperCase()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          bytesToHex(key).toUpperCase(),
          style: keyStyle.copyWith(color: color),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.key_outlined),
              label: Text(strings.saveKeysTo),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => DictionaryExportMenu(
                  defaultName: card.name,
                  keys: mfClassicGetKeysFromDump(card.data),
                ),
              ),
            ),
          ),
        ),
        SectionLabel(
          '${localizations.sector} · ${strings.keyA} · ${strings.keyB}',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: scheme.outlineVariant),
            ),
            children: [
              for (final (sector, a, b) in rows)
                TableRow(
                  children: [
                    Text(
                      sector.toString().padLeft(2, '0'),
                      style: keyStyle.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    keyCell(
                      a,
                      MifareClassicDumpHighlighter.getKeyAColor(context),
                    ),
                    keyCell(
                      b,
                      MifareClassicDumpHighlighter.getKeyBColor(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
