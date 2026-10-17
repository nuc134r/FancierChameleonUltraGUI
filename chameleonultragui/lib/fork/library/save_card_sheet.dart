import 'package:chameleonultragui/fork/library/card_page.dart';
import 'package:chameleonultragui/fork/library/library_actions.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/helpers/validators.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// "Save to library" sheet: name (prefilled), folder and colour, then a snackbar with Open.
Future<void> saveCardToLibrary(BuildContext context, CardSave card) async {
  final saved = await showModalBottomSheet<CardSave>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SaveSheet(card: card),
  );
  if (saved == null || !context.mounted) return;
  final strings = ForkStrings.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(strings.saved),
      action: SnackBarAction(
        label: strings.open,
        onPressed: () => openCardPage(context, saved),
      ),
    ),
  );
}

class _SaveSheet extends StatefulWidget {
  final CardSave card;

  const _SaveSheet({required this.card});

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  late final name = TextEditingController(text: widget.card.name);
  final formKey = GlobalKey<FormState>();
  String? folderId;
  late Color color = widget.card.color;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _save() {
    if (!formKey.currentState!.validate()) return;
    final appState = context.read<ChameleonGUIState>();
    final card = widget.card
      ..name = name.text.trim()
      ..folderId = folderId
      ..color = color;
    final cards = appState.sharedPreferencesProvider.getCards()..add(card);
    appState.sharedPreferencesProvider.setCards(cards);
    appState.changesMade();
    Navigator.pop(context, card);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final folders = context
        .read<ChameleonGUIState>()
        .sharedPreferencesProvider
        .getCardFolders();
    final folderName = folders.where((f) => f.id == folderId).firstOrNull?.name;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.saveToLibrary,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              autofocus: true,
              validator: (value) => validateName(value, localizations),
              decoration: InputDecoration(labelText: localizations.name),
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                folderName == null ? Icons.home_outlined : Icons.folder,
              ),
              title: Text(strings.folder),
              subtitle: Text(folderName ?? strings.library),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final picked = await LibraryActions.pickFolder(
                  context,
                  CardFolderStore()..rootName = strings.library,
                );
                if (picked != null) {
                  setState(() => folderId = picked.isEmpty ? null : picked);
                }
              },
            ),
            const SizedBox(height: 8),
            SwatchPicker(
              value: color,
              onChanged: (c) => setState(() => color = c),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _save,
              child: Text(localizations.save),
            ),
          ],
        ),
      ),
    );
  }
}
