import 'package:chameleonultragui/fork/library/library_actions.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/validators.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> openDictionaryPage(BuildContext context, Dictionary dictionary) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DictionaryPage(dictionaryId: dictionary.id),
    ),
  );
}

// Asks for a name and colour, then opens an empty dictionary in edit mode. It is stored only
// when saved with at least one key.
Future<void> createDictionary(BuildContext context, String? folderId) async {
  final result = await renameDialog(context, '', swatchColors.first);
  if (result == null || !context.mounted) return;
  final draft = Dictionary(
    name: result.$1,
    color: result.$2,
    keys: [],
    folderId: folderId,
  );
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DictionaryPage(dictionaryId: draft.id, draft: draft),
    ),
  );
}

Future<(String, Color)?> renameDialog(
  BuildContext context,
  String name,
  Color color,
) {
  final localizations = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: name);
  final formKey = GlobalKey<FormState>();
  var picked = color;
  return showDialog<(String, Color)>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(
          name.isEmpty
              ? localizations.create_dictionary
              : localizations.edit_dictionary,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                validator: (v) => validateName(v, localizations),
                decoration: InputDecoration(
                  labelText: localizations.name,
                  prefixIcon: Icon(Icons.key, color: picked),
                ),
              ),
              const SizedBox(height: 16),
              SwatchPicker(
                value: picked,
                onChanged: (c) => setDialogState(() => picked = c),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, (controller.text.trim(), picked));
              }
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    ),
  );
}

// One page per dictionary: searchable numbered key list; the pencil switches to a text editor.
class DictionaryPage extends StatefulWidget {
  final String dictionaryId;

  // Set for a dictionary that is not stored yet (created from the Library).
  final Dictionary? draft;

  const DictionaryPage({super.key, required this.dictionaryId, this.draft});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  late bool editing = widget.draft != null;
  String query = '';
  final editor = TextEditingController();

  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  Dictionary? _find(SharedPreferencesProvider prefs) =>
      prefs
          .getDictionaries()
          .where((d) => d.id == widget.dictionaryId)
          .firstOrNull ??
      widget.draft;

  bool _isStored(SharedPreferencesProvider prefs) =>
      prefs.getDictionaries().any((d) => d.id == widget.dictionaryId);

  void _store(Dictionary dictionary) {
    final appState = context.read<ChameleonGUIState>();
    final prefs = appState.sharedPreferencesProvider;
    final all = prefs.getDictionaries();
    final index = all.indexWhere((d) => d.id == dictionary.id);
    if (index >= 0) {
      all[index] = dictionary;
    } else {
      all.add(dictionary);
    }
    prefs.setDictionaries(all);
    appState.changesMade();
  }

  void _startEditing(Dictionary dictionary) {
    editor.text = dictionary.toString();
    setState(() => editing = true);
  }

  void _saveEdits(Dictionary dictionary) {
    final strings = ForkStrings.of(context);
    final parsed = Dictionary.fromString(
      editor.text,
      name: dictionary.name,
      color: dictionary.color,
    );
    if (parsed.keys.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.noKeysEntered)));
      return;
    }
    final lines = editor.text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;
    parsed
      ..id = dictionary.id
      ..folderId = dictionary.folderId;
    _store(parsed);
    setState(() => editing = false);
    final ignored = lines - parsed.keys.length;
    if (ignored > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.ignoredLines(ignored))));
    }
  }

  Future<void> _merge(Dictionary target) async {
    final strings = ForkStrings.of(context);
    final prefs = context.read<ChameleonGUIState>().sharedPreferencesProvider;
    final others =
        prefs
            .getDictionaries()
            .where((d) => d.id != target.id && d.keyLength == target.keyLength)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final selected = <String>{};

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  strings.mergeInto,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final d in others)
                      CheckboxListTile(
                        value: selected.contains(d.id),
                        onChanged: (v) => setSheetState(
                          () => v == true
                              ? selected.add(d.id)
                              : selected.remove(d.id),
                        ),
                        secondary: Icon(Icons.key, color: d.color),
                        title: Text(d.name),
                        subtitle: Text(
                          strings.keyCount(d.keys.length),
                          style: monoStyle(context, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(strings.merge),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || selected.isEmpty || !mounted) return;

    final seen = {for (final k in target.keys) bytesToHex(k)};
    final merged = [...target.keys];
    for (final d in others.where((d) => selected.contains(d.id))) {
      for (final key in d.keys) {
        if (seen.add(bytesToHex(key))) merged.add(key);
      }
    }
    final added = merged.length - target.keys.length;
    target.keys = merged;
    _store(target);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(strings.mergedKeys(added))));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final prefs = appState.sharedPreferencesProvider;
    final dictionary = _find(prefs);
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (dictionary == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold();
    }
    final stored = _isStored(prefs);
    if (editing && editor.text.isEmpty && dictionary.keys.isNotEmpty) {
      editor.text = dictionary.toString();
    }

    return PopScope(
      canPop: !editing || !stored,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => editing = false);
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Icon(Icons.key, color: dictionary.color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dictionary.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${strings.keyCount(dictionary.keys.length)}'
                      '${dictionary.keyLength > 0 ? ' · ${dictionary.keyLength ~/ 2} B' : ''}',
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
            if (editing)
              IconButton(
                tooltip: strings.save,
                icon: const Icon(Icons.check),
                onPressed: () => _saveEdits(dictionary),
              )
            else ...[
              IconButton(
                tooltip: strings.edit,
                icon: const Icon(Icons.edit_note),
                onPressed: () => _startEditing(dictionary),
              ),
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final r = await renameDialog(
                        context,
                        dictionary.name,
                        dictionary.color,
                      );
                      if (r == null) return;
                      dictionary
                        ..name = r.$1
                        ..color = r.$2;
                      _store(dictionary);
                    },
                    child: Text(strings.rename),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.merge),
                    onPressed: () => _merge(dictionary),
                    child: Text(strings.mergeInto),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.copy_all_outlined),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: dictionary.toString()),
                      );
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(strings.copied)));
                    },
                    child: Text(strings.copyAll),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.drive_file_move_outline),
                    onPressed: () =>
                        LibraryActions.moveDictionary(context, dictionary),
                    child: Text(strings.move),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.file_download_outlined),
                    onPressed: () =>
                        LibraryActions.exportDictionary(context, dictionary),
                    child: Text(strings.exportDic),
                  ),
                  MenuItemButton(
                    leadingIcon: Icon(
                      Icons.delete_outline,
                      color: scheme.error,
                    ),
                    onPressed: () =>
                        LibraryActions.deleteDictionary(context, dictionary),
                    child: Text(
                      strings.delete,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ],
                builder: (context, controller, _) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                ),
              ),
            ],
          ],
        ),
        body: editing ? _editor(context) : _list(context, dictionary),
      ),
    );
  }

  Widget _editor(BuildContext context) {
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.keysHint,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: editor,
              autofocus: true,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: monoStyle(context, size: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: scheme.surfaceContainerLowest,
                hintText: 'FFFFFFFFFFFF\nA0A1A2A3A4A5',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, Dictionary dictionary) {
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final q = query.trim().toUpperCase().replaceAll(' ', '');
    final rows = <(int, String)>[
      for (var i = 0; i < dictionary.keys.length; i++)
        (i + 1, bytesToHex(dictionary.keys[i]).toUpperCase()),
    ].where((r) => q.isEmpty || r.$2.contains(q)).toList();
    final digits = '${dictionary.keys.length}'.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            style: monoStyle(context, size: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: strings.searchKeys,
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
          child: rows.isEmpty
              ? EmptyState(icon: Icons.search_off, title: strings.nothingFound)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: rows.length,
                  itemExtent: 36,
                  itemBuilder: (context, i) {
                    final (n, key) = rows[i];
                    return InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: key));
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('${strings.copied}: $key'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12.0 * digits + 16,
                              child: Text(
                                '$n'.padLeft(digits),
                                style: monoStyle(
                                  context,
                                  size: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(key, style: monoStyle(context, size: 14.5)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
