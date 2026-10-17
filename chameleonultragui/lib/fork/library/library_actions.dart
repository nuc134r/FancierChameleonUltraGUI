import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/menu/dialogs/confirm_delete.dart';
import 'package:chameleonultragui/helpers/card_save_converters.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/mifare_classic/general.dart';
import 'package:chameleonultragui/helpers/mifare_ultralight/general.dart';
import 'package:chameleonultragui/helpers/validators.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

// Colours offered for cards, folders and dictionaries (instead of a full colour picker).
const swatchColors = <Color>[
  Colors.deepOrange,
  Color(0xFFD9A93A),
  Colors.amber,
  Colors.lightGreen,
  Colors.teal,
  Colors.cyan,
  Colors.blue,
  Colors.indigo,
  Colors.deepPurple,
  Colors.pink,
  Colors.red,
  Colors.blueGrey,
];

class SwatchPicker extends StatelessWidget {
  final Color value;
  final ValueChanged<Color> onChanged;

  const SwatchPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final color in swatchColors)
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onChanged(color),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  width: 2,
                  color: color.toARGB32() == value.toARGB32()
                      ? scheme.onSurface
                      : Colors.transparent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Folders of cards and of dictionaries share the same shape; this adapts both.
abstract class FolderStore {
  String get rootName;
  List<({String id, String name, Color color, String? parentId})> all(
    SharedPreferencesProvider prefs,
  );
  void create(
    SharedPreferencesProvider prefs,
    String name,
    Color color,
    String? parentId,
  );
  void update(
    SharedPreferencesProvider prefs,
    String id, {
    String? name,
    Color? color,
    String? parentId,
    bool toRoot = false,
  });
  void deleteTree(SharedPreferencesProvider prefs, Set<String> ids);
  Future<void> exportTree(BuildContext context, String id, String name);
}

Set<String> folderTreeIds(
  String rootId,
  Iterable<({String id, String? parentId})> folders,
) {
  final result = <String>{rootId};
  var changed = true;
  while (changed) {
    changed = false;
    for (final folder in folders) {
      if (folder.parentId != null &&
          result.contains(folder.parentId) &&
          result.add(folder.id)) {
        changed = true;
      }
    }
  }
  return result;
}

class CardFolderStore extends FolderStore {
  @override
  String rootName = '';

  @override
  List<({String id, String name, Color color, String? parentId})> all(
    SharedPreferencesProvider prefs,
  ) => prefs
      .getCardFolders()
      .map(
        (f) => (id: f.id, name: f.name, color: f.color, parentId: f.parentId),
      )
      .toList();

  @override
  void create(
    SharedPreferencesProvider prefs,
    String name,
    Color color,
    String? parentId,
  ) {
    final folders = prefs.getCardFolders();
    folders.add(CardFolder(name: name, color: color, parentId: parentId));
    prefs.setCardFolders(folders);
  }

  @override
  void update(
    SharedPreferencesProvider prefs,
    String id, {
    String? name,
    Color? color,
    String? parentId,
    bool toRoot = false,
  }) {
    final folders = prefs.getCardFolders();
    for (final folder in folders.where((f) => f.id == id)) {
      folder.name = name ?? folder.name;
      folder.color = color ?? folder.color;
      if (toRoot || parentId != null) folder.parentId = parentId;
    }
    prefs.setCardFolders(folders);
  }

  @override
  void deleteTree(SharedPreferencesProvider prefs, Set<String> ids) {
    prefs.setCardFolders(
      prefs.getCardFolders().where((f) => !ids.contains(f.id)).toList(),
    );
    prefs.setCards(
      prefs.getCards().where((c) => !ids.contains(c.folderId)).toList(),
    );
  }

  @override
  Future<void> exportTree(BuildContext context, String id, String name) async {
    final localizations = AppLocalizations.of(context)!;
    final prefs = context.read<ChameleonGUIState>().sharedPreferencesProvider;
    final folders = prefs.getCardFolders();
    final ids = folderTreeIds(
      id,
      folders.map((f) => (id: f.id, parentId: f.parentId)),
    );
    final bundle = CardFolderBundle(
      rootFolderId: id,
      folders: folders.where((f) => ids.contains(f.id)).toList(),
      cards: prefs.getCards().where((c) => ids.contains(c.folderId)).toList(),
    );
    await FilePicker.saveFile(
      dialogTitle: localizations.export_folder,
      fileName: '$name.json',
      bytes: const Utf8Encoder().convert(bundle.toJson()),
    );
  }
}

class DictionaryFolderStore extends FolderStore {
  @override
  String rootName = '';

  @override
  List<({String id, String name, Color color, String? parentId})> all(
    SharedPreferencesProvider prefs,
  ) => prefs
      .getDictionaryFolders()
      .map(
        (f) => (id: f.id, name: f.name, color: f.color, parentId: f.parentId),
      )
      .toList();

  @override
  void create(
    SharedPreferencesProvider prefs,
    String name,
    Color color,
    String? parentId,
  ) {
    final folders = prefs.getDictionaryFolders();
    folders.add(DictionaryFolder(name: name, color: color, parentId: parentId));
    prefs.setDictionaryFolders(folders);
  }

  @override
  void update(
    SharedPreferencesProvider prefs,
    String id, {
    String? name,
    Color? color,
    String? parentId,
    bool toRoot = false,
  }) {
    final folders = prefs.getDictionaryFolders();
    for (final folder in folders.where((f) => f.id == id)) {
      folder.name = name ?? folder.name;
      folder.color = color ?? folder.color;
      if (toRoot || parentId != null) folder.parentId = parentId;
    }
    prefs.setDictionaryFolders(folders);
  }

  @override
  void deleteTree(SharedPreferencesProvider prefs, Set<String> ids) {
    prefs.setDictionaryFolders(
      prefs.getDictionaryFolders().where((f) => !ids.contains(f.id)).toList(),
    );
    prefs.setDictionaries(
      prefs.getDictionaries().where((d) => !ids.contains(d.folderId)).toList(),
    );
  }

  @override
  Future<void> exportTree(BuildContext context, String id, String name) async {
    final localizations = AppLocalizations.of(context)!;
    final prefs = context.read<ChameleonGUIState>().sharedPreferencesProvider;
    final folders = prefs.getDictionaryFolders();
    final ids = folderTreeIds(
      id,
      folders.map((f) => (id: f.id, parentId: f.parentId)),
    );
    final bundle = DictionaryFolderBundle(
      rootFolderId: id,
      folders: folders.where((f) => ids.contains(f.id)).toList(),
      dictionaries: prefs
          .getDictionaries()
          .where((d) => ids.contains(d.folderId))
          .toList(),
    );
    await FilePicker.saveFile(
      dialogTitle: localizations.export_dictionary_folder,
      fileName: '$name.json',
      bytes: const Utf8Encoder().convert(bundle.toJson()),
    );
  }
}

class LibraryActions {
  static ChameleonGUIState _state(BuildContext context) =>
      context.read<ChameleonGUIState>();

  // Create (folder == null) or rename/recolour a folder.
  static Future<void> editFolder(
    BuildContext context,
    FolderStore store, {
    String? parentId,
    ({String id, String name, Color color, String? parentId})? folder,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final name = TextEditingController(text: folder?.name ?? '');
    var color = folder?.color ?? swatchColors.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(folder == null ? strings.newFolder : strings.rename),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: localizations.name,
                  prefixIcon: Icon(Icons.folder, color: color),
                ),
                onSubmitted: (_) =>
                    Navigator.pop(dialogContext, name.text.trim().isNotEmpty),
              ),
              const SizedBox(height: 16),
              SwatchPicker(
                value: color,
                onChanged: (value) => setDialogState(() => color = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, name.text.trim().isNotEmpty),
              child: Text(
                folder == null ? localizations.create : localizations.save,
              ),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;
    if (folder == null) {
      store.create(prefs, name.text.trim(), color, parentId);
    } else {
      store.update(prefs, folder.id, name: name.text.trim(), color: color);
    }
    appState.changesMade();
  }

  // Bottom sheet listing every folder (indented by depth). Returns '' for the root,
  // a folder id, or null when dismissed.
  static Future<String?> pickFolder(
    BuildContext context,
    FolderStore store, {
    String? excludeTreeOf,
  }) {
    final strings = ForkStrings.of(context);
    final folders = store.all(_state(context).sharedPreferencesProvider);
    final excluded = excludeTreeOf == null
        ? <String>{}
        : folderTreeIds(
            excludeTreeOf,
            folders.map((f) => (id: f.id, parentId: f.parentId)),
          );

    final rows =
        <(int, ({String id, String name, Color color, String? parentId}))>[];
    void walk(String? parent, int depth) {
      final children = folders.where((f) => f.parentId == parent).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      for (final folder in children) {
        if (excluded.contains(folder.id)) continue;
        rows.add((depth, folder));
        walk(folder.id, depth + 1);
      }
    }

    walk(null, 0);

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  strings.move,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(
                  store.rootName.isEmpty ? strings.library : store.rootName,
                ),
                onTap: () => Navigator.pop(context, ''),
              ),
              for (final (depth, folder) in rows)
                ListTile(
                  contentPadding: EdgeInsets.only(
                    left: 16.0 + 24 * (depth + 1),
                    right: 16,
                  ),
                  leading: Icon(Icons.folder, color: folder.color),
                  title: Text(folder.name),
                  onTap: () => Navigator.pop(context, folder.id),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> moveFolder(
    BuildContext context,
    FolderStore store,
    ({String id, String name, Color color, String? parentId}) folder,
  ) async {
    final destination = await pickFolder(
      context,
      store,
      excludeTreeOf: folder.id,
    );
    if (destination == null || !context.mounted) return;
    final appState = _state(context);
    store.update(
      appState.sharedPreferencesProvider,
      folder.id,
      parentId: destination.isEmpty ? null : destination,
      toRoot: destination.isEmpty,
    );
    appState.changesMade();
  }

  static Future<void> deleteFolder(
    BuildContext context,
    FolderStore store,
    ({String id, String name, Color color, String? parentId}) folder, {
    required String message,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.delete_folder_title(folder.name)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;
    final ids = folderTreeIds(
      folder.id,
      store.all(prefs).map((f) => (id: f.id, parentId: f.parentId)),
    );
    store.deleteTree(prefs, ids);
    appState.changesMade();
  }

  static Future<void> moveCard(BuildContext context, CardSave card) async {
    final destination = await pickFolder(context, CardFolderStore());
    if (destination == null || !context.mounted) return;
    final appState = _state(context);
    final cards = appState.sharedPreferencesProvider.getCards();
    for (final c in cards.where((c) => c.id == card.id)) {
      c.folderId = destination.isEmpty ? null : destination;
    }
    card.folderId = destination.isEmpty ? null : destination;
    appState.sharedPreferencesProvider.setCards(cards);
    appState.changesMade();
  }

  static CardSave duplicateCard(BuildContext context, CardSave card) {
    final localizations = AppLocalizations.of(context)!;
    final appState = _state(context);
    final cards = appState.sharedPreferencesProvider.getCards();
    final copy = CardSave.fromJson(card.toJson());
    copy.id = const Uuid().v4();
    copy.name = '${card.name} (${localizations.copy})';
    cards.add(copy);
    appState.sharedPreferencesProvider.setCards(cards);
    appState.changesMade();
    return copy;
  }

  // Asks first when "Confirm deletions" is on; always offers Undo. Returns true if deleted.
  static Future<bool> deleteCard(BuildContext context, CardSave card) async {
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;
    if (prefs.getConfirmDelete()) {
      final confirm = await showDialog(
        context: context,
        builder: (context) => ConfirmDeletionMenu(thingBeingDeleted: card.name),
      );
      if (confirm != true || !context.mounted) return false;
    }
    final strings = ForkStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cards = prefs.getCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index < 0) return false;
    final removed = cards.removeAt(index);
    prefs.setCards(cards);
    appState.changesMade();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.deleted(card.name)),
        action: SnackBarAction(
          label: strings.undo,
          onPressed: () {
            final current = prefs.getCards();
            current.insert(index.clamp(0, current.length), removed);
            prefs.setCards(current);
            appState.changesMade();
          },
        ),
      ),
    );
    return true;
  }

  static Future<void> moveCards(BuildContext context, Set<String> ids) async {
    final destination = await pickFolder(context, CardFolderStore());
    if (destination == null || !context.mounted) return;
    final appState = _state(context);
    final cards = appState.sharedPreferencesProvider.getCards();
    for (final c in cards.where((c) => ids.contains(c.id))) {
      c.folderId = destination.isEmpty ? null : destination;
    }
    appState.sharedPreferencesProvider.setCards(cards);
    appState.changesMade();
  }

  // Deletes several cards at once (asks first when "Confirm deletions" is on), with Undo.
  static Future<bool> deleteCards(BuildContext context, Set<String> ids) async {
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;
    final strings = ForkStrings.of(context);
    if (prefs.getConfirmDelete()) {
      final confirm = await showDialog(
        context: context,
        builder: (context) => ConfirmDeletionMenu(
          thingBeingDeleted: strings.selectedCount(ids.length),
        ),
      );
      if (confirm != true || !context.mounted) return false;
    }
    final messenger = ScaffoldMessenger.of(context);
    final before = prefs.getCards();
    prefs.setCards(before.where((c) => !ids.contains(c.id)).toList());
    appState.changesMade();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.deletedCount(ids.length)),
        action: SnackBarAction(
          label: strings.undo,
          onPressed: () {
            final restored = before.where((c) => ids.contains(c.id));
            prefs.setCards([...prefs.getCards(), ...restored]);
            appState.changesMade();
          },
        ),
      ),
    );
    return true;
  }

  static Future<bool> deleteDictionary(
    BuildContext context,
    Dictionary dictionary,
  ) async {
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;
    if (prefs.getConfirmDelete()) {
      final confirm = await showDialog(
        context: context,
        builder: (context) =>
            ConfirmDeletionMenu(thingBeingDeleted: dictionary.name),
      );
      if (confirm != true || !context.mounted) return false;
    }
    final strings = ForkStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final dictionaries = prefs.getDictionaries();
    final index = dictionaries.indexWhere((d) => d.id == dictionary.id);
    if (index < 0) return false;
    final removed = dictionaries.removeAt(index);
    prefs.setDictionaries(dictionaries);
    appState.changesMade();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.deleted(dictionary.name)),
        action: SnackBarAction(
          label: strings.undo,
          onPressed: () {
            final current = prefs.getDictionaries();
            current.insert(index.clamp(0, current.length), removed);
            prefs.setDictionaries(current);
            appState.changesMade();
          },
        ),
      ),
    );
    return true;
  }

  static Future<void> moveDictionary(
    BuildContext context,
    Dictionary dictionary,
  ) async {
    final store = DictionaryFolderStore()
      ..rootName = AppLocalizations.of(context)!.dictionaries;
    final destination = await pickFolder(context, store);
    if (destination == null || !context.mounted) return;
    final appState = _state(context);
    final dictionaries = appState.sharedPreferencesProvider.getDictionaries();
    for (final d in dictionaries.where((d) => d.id == dictionary.id)) {
      d.folderId = destination.isEmpty ? null : destination;
    }
    appState.sharedPreferencesProvider.setDictionaries(dictionaries);
    appState.changesMade();
  }

  static Future<void> exportDictionary(
    BuildContext context,
    Dictionary dictionary,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    await FilePicker.saveFile(
      dialogTitle: '${localizations.output_file}:',
      fileName: '${dictionary.name}.dic',
      bytes: dictionary.toFile(),
    );
  }

  // Imports a card file: folder bundle, app JSON, Proxmark3 JSON, Flipper NFC / RFID, MIFARE
  // Classic Tool, or a raw binary dump (asks for the identifiers).
  static Future<void> importCardFile(
    BuildContext context,
    String? folderId,
  ) async {
    final result = await FilePicker.pickFile();
    if (result == null || !context.mounted) return;
    final file = File(result.path!);
    final contents = await file.readAsBytes();
    if (!context.mounted) return;
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;
    final name = basename(file.path).split('.').first;

    String? text;
    try {
      text = const Utf8Decoder().convert(contents);
    } catch (_) {}

    if (text != null) {
      dynamic decoded;
      try {
        decoded = jsonDecode(text);
      } catch (_) {}
      if (decoded is Map && decoded['format'] == 'chameleon-ultra-gui-folder') {
        _importCardFolderBundle(context, text, folderId);
        return;
      }
      try {
        CardSave card;
        if (text.contains("\"Created\": \"proxmark3\",")) {
          card = pm3JsonToCardSave(text);
        } else if (text.contains("Filetype: Flipper NFC device")) {
          card = flipperNfcToCardSave(text);
        } else if (text.contains("+Sector: 0")) {
          card = mctToCardSave(text);
        } else if (text.contains("Filetype: Flipper RFID key")) {
          card = flipperRfidToCardSave(text);
        } else {
          card = CardSave.fromJson(text);
        }
        card.name = name;
        card.folderId = folderId;
        final cards = prefs.getCards()..add(card);
        prefs.setCards(cards);
        appState.changesMade();
        return;
      } catch (_) {
        // Not a structured format: try it as a raw dump below.
      }
    }

    final card = await _askRawDumpDetails(context, contents, name, folderId);
    if (card == null || !context.mounted) return;
    final cards = prefs.getCards()..add(card);
    prefs.setCards(cards);
    appState.changesMade();
  }

  static void _importCardFolderBundle(
    BuildContext context,
    String source,
    String? parentId,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;
    try {
      final bundle = CardFolderBundle.fromJson(source);
      final folders = prefs.getCardFolders();
      final cards = prefs.getCards();
      final idMap = <String, String>{
        for (final f in bundle.folders) f.id: const Uuid().v4(),
      };
      for (final imported in bundle.folders) {
        folders.add(
          CardFolder(
            id: idMap[imported.id],
            name: imported.name,
            color: imported.color,
            parentId: imported.id == bundle.rootFolderId
                ? parentId
                : idMap[imported.parentId],
          ),
        );
      }
      for (final imported in bundle.cards) {
        final copy = CardSave.fromJson(imported.toJson());
        copy.id = const Uuid().v4();
        copy.folderId = idMap[imported.folderId];
        cards.add(copy);
      }
      prefs.setCardFolders(folders);
      prefs.setCards(cards);
      appState.changesMade();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.invalid_folder_export)),
      );
    }
  }

  static Future<CardSave?> _askRawDumpDetails(
    BuildContext context,
    Uint8List contents,
    String name,
    String? folderId,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    var type = getTagTypeByDumpSize(contents.length);
    if (type == TagType.unknown) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.importFailed)));
      return null;
    }

    final classic = isMifareClassic(type);
    // Defaults read from block 0 (MIFARE Classic) or pages 0-1 (Ultralight).
    var uidBytes = 4;
    final uid = TextEditingController();
    final sak = TextEditingController();
    final atqa = TextEditingController();
    void fillFromDump() {
      if (classic) {
        uid.text = bytesToHexSpace(contents.sublist(0, uidBytes));
        sak.text = uidBytes == 4 ? bytesToHex(contents.sublist(5, 6)) : '00';
        atqa.text = uidBytes == 4
            ? bytesToHexSpace(Uint8List.fromList([contents[7], contents[6]]))
            : '00 00';
      } else if (isMifareUltralight(type)) {
        uid.text = bytesToHexSpace(
          Uint8List.fromList([
            ...contents.sublist(0, 3),
            ...contents.sublist(4, 8),
          ]),
        );
        sak.text = '00';
        atqa.text = '00 44';
      }
    }

    fillFromDump();
    final nameController = TextEditingController(text: name);
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.importRawTitle),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    validator: (value) => validateName(value, localizations),
                    decoration: InputDecoration(labelText: localizations.name),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TagType>(
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: localizations.tag_type,
                    ),
                    items: getTagTypesByFrequency(TagFrequency.hf)
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(chameleonTagToString(t, localizations)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => type = value ?? type),
                  ),
                  if (classic) ...[
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 4,
                          label: Text(localizations.x_byte_uid(4)),
                        ),
                        ButtonSegment(
                          value: 7,
                          label: Text(localizations.x_byte_uid(7)),
                        ),
                      ],
                      selected: {uidBytes},
                      onSelectionChanged: (value) => setDialogState(() {
                        uidBytes = value.first;
                        fillFromDump();
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: uid,
                    style: monoStyle(context),
                    inputFormatters: hexFormatter,
                    validator: (value) => validateHex(
                      value,
                      localizations,
                      required: true,
                      fieldName: localizations.uid,
                    ),
                    decoration: InputDecoration(labelText: localizations.uid),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sak,
                    style: monoStyle(context),
                    inputFormatters: hexFormatter,
                    validator: (value) => validateHex(
                      value,
                      localizations,
                      exactBytes: 1,
                      required: true,
                      fieldName: localizations.sak,
                    ),
                    decoration: InputDecoration(labelText: localizations.sak),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: atqa,
                    style: monoStyle(context),
                    inputFormatters: hexFormatter,
                    validator: (value) => validateHex(
                      value,
                      localizations,
                      exactBytes: 2,
                      required: true,
                      fieldName: localizations.atqa,
                    ),
                    decoration: InputDecoration(labelText: localizations.atqa),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(localizations.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(localizations.save),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;

    final blockSize = isMifareClassic(type) ? 16 : 4;
    final blocks = <Uint8List>[
      for (var i = 0; i + blockSize <= contents.length; i += blockSize)
        contents.sublist(i, i + blockSize),
    ];
    return CardSave(
      name: nameController.text,
      uid: uid.text.toUpperCase(),
      sak: hexToBytes(sak.text)[0],
      atqa: hexToBytes(atqa.text),
      tag: type,
      data: blocks,
      folderId: folderId,
    );
  }

  static Future<void> importDictionaryFile(
    BuildContext context,
    String? folderId,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFile();
    if (result == null || !context.mounted) return;
    String contents;
    try {
      contents = const Utf8Decoder().convert(
        await File(result.path!).readAsBytes(),
      );
    } catch (_) {
      return;
    }
    if (!context.mounted) return;
    final appState = _state(context);
    final prefs = appState.sharedPreferencesProvider;

    dynamic decoded;
    try {
      decoded = jsonDecode(contents);
    } catch (_) {}
    if (decoded is Map &&
        decoded['format'] == 'chameleon-ultra-gui-dictionary-folder') {
      try {
        final bundle = DictionaryFolderBundle.fromJson(contents);
        final folders = prefs.getDictionaryFolders();
        final dictionaries = prefs.getDictionaries();
        final idMap = <String, String>{
          for (final f in bundle.folders) f.id: const Uuid().v4(),
        };
        for (final imported in bundle.folders) {
          folders.add(
            DictionaryFolder(
              id: idMap[imported.id],
              name: imported.name,
              color: imported.color,
              parentId: imported.id == bundle.rootFolderId
                  ? folderId
                  : idMap[imported.parentId],
            ),
          );
        }
        for (final imported in bundle.dictionaries) {
          final copy = Dictionary.fromJson(imported.toJson());
          copy.id = const Uuid().v4();
          copy.folderId = idMap[imported.folderId];
          dictionaries.add(copy);
        }
        prefs.setDictionaryFolders(folders);
        prefs.setDictionaries(dictionaries);
        appState.changesMade();
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.invalid_dictionary_folder_export),
          ),
        );
      }
      return;
    }

    final dictionary = Dictionary.fromString(
      contents,
      name: result.name.split('.').first,
    );
    if (dictionary.keys.isEmpty) return;
    dictionary.folderId = folderId;
    prefs.setDictionaries(prefs.getDictionaries()..add(dictionary));
    appState.changesMade();
  }
}
