import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/gui/menu/pages/ndef_editor.dart';
import 'package:chameleonultragui/helpers/ndef.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

String ndefKindLabel(NdefRecordKind kind) => switch (kind) {
  NdefRecordKind.text => 'Text',
  NdefRecordKind.uri => 'URI',
  NdefRecordKind.mime => 'MIME',
  NdefRecordKind.external => 'External',
  NdefRecordKind.raw => 'Raw',
};

// Opens upstream's NDEF editor and writes the result back into the saved card's dump.
Future<void> editNdef(BuildContext context, CardSave card) async {
  final blocks = [for (final b in card.data) Uint8List.fromList(b)];
  final container = NdefContainer.detect(card.tag, blocks);
  if (container == null) return;
  var records = <NdefRecord>[];
  String? warning;
  try {
    records = NdefCodec.decodeMessage(container.message);
  } catch (e) {
    warning = e.toString();
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => NdefEditorPage(
        records: records,
        capacity: container.capacity,
        mappingName: container.mappingName,
        parseWarning: warning,
        onSave: (message) {
          container.writeMessage(blocks, message);
          final appState = context.read<ChameleonGUIState>();
          final cards = appState.sharedPreferencesProvider.getCards();
          for (final c in cards.where((c) => c.id == card.id)) {
            c.data = blocks;
          }
          appState.sharedPreferencesProvider.setCards(cards);
          appState.changesMade();
        },
      ),
    ),
  );
}

// Read-only view of the NDEF records stored in a card's dump; the pencil opens the editor.
class NdefTab extends StatelessWidget {
  final CardSave card;

  const NdefTab({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final container = NdefContainer.detect(card.tag, card.data);
    if (container == null) return const SizedBox.shrink();

    List<NdefRecord> records = [];
    String? warning;
    try {
      records = NdefCodec.decodeMessage(container.message);
    } catch (e) {
      warning = e.toString();
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SectionLabel(
          container.mappingName,
          trailing: Text(
            '${container.message.length} / ${container.capacity} B',
            style: monoStyle(context, size: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        if (warning != null)
          ListTile(
            leading: Icon(Icons.warning_amber, color: scheme.error),
            title: Text(warning),
          ),
        if (records.isEmpty && warning == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              strings.slotEmpty,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        for (var i = 0; i < records.length; i++)
          ListTile(
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              child: Text(
                '${i + 1}',
                style: monoStyle(context, size: 12, color: scheme.primary),
              ),
            ),
            title: Text(ndefKindLabel(records[i].kind)),
            subtitle: Text(
              records[i].displayValue,
              style: monoStyle(context, size: 13),
            ),
            trailing: Icon(
              Icons.copy,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            onTap: () {
              Clipboard.setData(ClipboardData(text: records[i].displayValue));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(strings.copied),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
      ],
    );
  }
}
