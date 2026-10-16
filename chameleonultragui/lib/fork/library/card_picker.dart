import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Bottom sheet to pick a saved card (search across all folders). [frequency] limits the list,
// e.g. to HF cards for a slot's HF side.
Future<CardSave?> pickCard(BuildContext context, {TagFrequency? frequency}) {
  return showModalBottomSheet<CardSave>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CardPicker(frequency: frequency),
  );
}

class _CardPicker extends StatefulWidget {
  final TagFrequency? frequency;

  const _CardPicker({this.frequency});

  @override
  State<_CardPicker> createState() => _CardPickerState();
}

class _CardPickerState extends State<_CardPicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<ChameleonGUIState>().sharedPreferencesProvider;
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final folders = {for (final f in prefs.getCardFolders()) f.id: f.name};
    final q = query.trim().toLowerCase();

    final cards =
        prefs
            .getCards()
            .where(
              (c) =>
                  widget.frequency == null ||
                  chameleonTagToFrequency(c.tag) == widget.frequency,
            )
            .where(
              (c) =>
                  q.isEmpty ||
                  c.name.toLowerCase().contains(q) ||
                  c.uid
                      .toLowerCase()
                      .replaceAll(' ', '')
                      .contains(q.replaceAll(' ', '')),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: false,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                isDense: true,
                hintText: strings.searchCards,
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: scheme.surfaceContainer,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: cards.isEmpty
                ? EmptyState(
                    icon: Icons.style_outlined,
                    title: q.isEmpty
                        ? strings.noCardsYet
                        : strings.nothingFound,
                  )
                : ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, i) {
                      final card = cards[i];
                      final folder = folders[card.folderId];
                      return ListTile(
                        leading: Icon(Icons.credit_card, color: card.color),
                        title: Text(
                          card.name.isEmpty ? '—' : card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          [
                            card.uid,
                            chameleonTagToString(card.tag, localizations),
                            ?folder,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: monoStyle(
                            context,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, card),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
