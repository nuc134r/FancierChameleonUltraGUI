import 'package:chameleonultragui/fork/library/card_form_page.dart';
import 'package:chameleonultragui/fork/library/card_page.dart';
import 'package:chameleonultragui/fork/library/dictionary_page.dart';
import 'package:chameleonultragui/fork/library/library_actions.dart';
import 'package:chameleonultragui/fork/shell.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/menu/tools/dictionary_download.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef _Folder = ({String id, String name, Color color, String? parentId});

enum _Freq { all, hf, lf }

// Kept outside the widget so switching bottom tabs doesn't lose the open folder or search.
class _LibraryMemory {
  static int tab = 0;
  static String? cardFolder;
  static String? dictionaryFolder;
  static String cardQuery = '';
  static String dictionaryQuery = '';
  static _Freq freq = _Freq.all;
  static final Set<String> selected = {}; // card ids in multi-select mode
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabs =
      TabController(length: 2, vsync: this, initialIndex: _LibraryMemory.tab)
        ..addListener(() {
          _LibraryMemory.tab = tabs.index;
          setState(() {});
        });

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  CardFolderStore _cardStore(BuildContext context) =>
      CardFolderStore()..rootName = ForkStrings.of(context).library;

  DictionaryFolderStore _dictStore(BuildContext context) =>
      DictionaryFolderStore()
        ..rootName = AppLocalizations.of(context)!.dictionaries;

  // Back goes up one folder before it leaves the page.
  bool get _inFolder => tabs.index == 0
      ? _LibraryMemory.cardFolder != null
      : _LibraryMemory.dictionaryFolder != null;

  void _goUp(SharedPreferencesProvider prefs) {
    setState(() {
      if (tabs.index == 0) {
        final folders = prefs.getCardFolders();
        _LibraryMemory.cardFolder = folders
            .where((f) => f.id == _LibraryMemory.cardFolder)
            .firstOrNull
            ?.parentId;
      } else {
        final folders = prefs.getDictionaryFolders();
        _LibraryMemory.dictionaryFolder = folders
            .where((f) => f.id == _LibraryMemory.dictionaryFolder)
            .firstOrNull
            ?.parentId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final prefs = appState.sharedPreferencesProvider;
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Drop selections of cards that no longer exist (deleted elsewhere).
    final existing = prefs.getCards().map((c) => c.id).toSet();
    _LibraryMemory.selected.retainWhere(existing.contains);
    final selecting = _LibraryMemory.selected.isNotEmpty && tabs.index == 0;
    final selected = _LibraryMemory.selected;

    return PopScope(
      canPop: !_inFolder && !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (selecting) {
          setState(selected.clear);
        } else {
          _goUp(prefs);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: selecting
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(selected.clear),
                )
              : null,
          title: Text(
            selecting
                ? strings.selectedCount(selected.length)
                : strings.library,
          ),
          actions: selecting
              ? [
                  IconButton(
                    tooltip: strings.move,
                    icon: const Icon(Icons.drive_file_move_outline),
                    onPressed: () async {
                      await LibraryActions.moveCards(context, {...selected});
                      setState(selected.clear);
                    },
                  ),
                  IconButton(
                    tooltip: strings.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await LibraryActions.deleteCards(context, {
                        ...selected,
                      })) {
                        setState(selected.clear);
                      }
                    },
                  ),
                ]
              : const [SettingsButton()],
          bottom: TabBar(
            controller: tabs,
            tabs: [
              Tab(text: localizations.cards),
              Tab(text: strings.keys),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabs,
          children: [
            _CardsTab(
              store: _cardStore(context),
              onFolderChanged: () => setState(() {}),
            ),
            _DictionariesTab(
              store: _dictStore(context),
              onFolderChanged: () => setState(() {}),
            ),
          ],
        ),
        floatingActionButton: selecting
            ? null
            : tabs.index == 0
            ? _AddButton(
                items: [
                  (
                    Icons.add_card_outlined,
                    strings.newCard,
                    () => openCardForm(
                      context,
                      folderId: _LibraryMemory.cardFolder,
                    ),
                  ),
                  (
                    Icons.create_new_folder_outlined,
                    strings.newFolder,
                    () => LibraryActions.editFolder(
                      context,
                      _cardStore(context),
                      parentId: _LibraryMemory.cardFolder,
                    ),
                  ),
                  (
                    Icons.file_open_outlined,
                    strings.importFile,
                    () => LibraryActions.importCardFile(
                      context,
                      _LibraryMemory.cardFolder,
                    ),
                  ),
                ],
              )
            : _AddButton(
                items: [
                  (
                    Icons.key_outlined,
                    strings.newDictionary,
                    () => createDictionary(
                      context,
                      _LibraryMemory.dictionaryFolder,
                    ),
                  ),
                  (
                    Icons.create_new_folder_outlined,
                    strings.newFolder,
                    () => LibraryActions.editFolder(
                      context,
                      _dictStore(context),
                      parentId: _LibraryMemory.dictionaryFolder,
                    ),
                  ),
                  (
                    Icons.file_open_outlined,
                    strings.importFile,
                    () => LibraryActions.importDictionaryFile(
                      context,
                      _LibraryMemory.dictionaryFolder,
                    ),
                  ),
                  (
                    Icons.cloud_download_outlined,
                    strings.downloadDictionaries,
                    () => showDialog(
                      context: context,
                      builder: (_) => const DictionaryDownloadMenu(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final List<(IconData, String, VoidCallback)> items;

  const _AddButton({required this.items});

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-120, 8),
      menuChildren: [
        for (final (icon, label, action) in items)
          MenuItemButton(
            leadingIcon: Icon(icon),
            onPressed: action,
            child: Text(label),
          ),
      ],
      builder: (context, controller, _) => FloatingActionButton(
        tooltip: AppLocalizations.of(context)!.create,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Search field plus a breadcrumb (Library / Office / …) shown inside folders.
class _ListHeader extends StatelessWidget {
  final String hint;
  final String query;
  final ValueChanged<String> onQuery;
  final List<_Folder> path;
  final String rootName;
  final ValueChanged<String?> onOpen;
  final Widget? filters;

  const _ListHeader({
    required this.hint,
    required this.query,
    required this.onQuery,
    required this.path,
    required this.rootName,
    required this.onOpen,
    this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final crumbStyle = monoStyle(context, size: 12.5);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SearchField(hint: hint, query: query, onQuery: onQuery),
          if (filters != null) ...[const SizedBox(height: 8), filters!],
          if (path.isNotEmpty && query.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => onOpen(null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          rootName,
                          style: crumbStyle.copyWith(color: scheme.primary),
                        ),
                      ),
                    ),
                    for (var i = 0; i < path.length; i++) ...[
                      Text(
                        '  /  ',
                        style: crumbStyle.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      InkWell(
                        onTap: i == path.length - 1
                            ? null
                            : () => onOpen(path[i].id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            path[i].name,
                            style: crumbStyle.copyWith(
                              color: i == path.length - 1
                                  ? scheme.onSurface
                                  : scheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final String hint;
  final String query;
  final ValueChanged<String> onQuery;

  const _SearchField({
    required this.hint,
    required this.query,
    required this.onQuery,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final controller = TextEditingController(text: widget.query);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: widget.onQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  widget.onQuery('');
                },
              ),
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

List<_Folder> _pathTo(String? id, List<_Folder> folders) {
  final path = <_Folder>[];
  var current = id;
  while (current != null) {
    final folder = folders.where((f) => f.id == current).firstOrNull;
    if (folder == null) break;
    path.insert(0, folder);
    current = folder.parentId;
  }
  return path;
}

class _FolderRow extends StatelessWidget {
  final _Folder folder;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _FolderRow({
    required this.folder,
    required this.subtitle,
    required this.onOpen,
    required this.onRename,
    required this.onMove,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    return ListTile(
      leading: Icon(Icons.folder, color: folder.color),
      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle,
        style: monoStyle(
          context,
          size: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onOpen,
      trailing: _Overflow(
        items: [
          (Icons.edit_outlined, strings.rename, onRename, false),
          (Icons.drive_file_move_outline, strings.move, onMove, false),
          (Icons.file_download_outlined, strings.export, onExport, false),
          (Icons.delete_outline, strings.delete, onDelete, true),
        ],
      ),
    );
  }
}

class _Overflow extends StatelessWidget {
  final List<(IconData, String, VoidCallback, bool)> items;

  const _Overflow({required this.items});

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return MenuAnchor(
      menuChildren: [
        for (final (icon, label, action, destructive) in items)
          MenuItemButton(
            leadingIcon: Icon(icon, color: destructive ? error : null),
            onPressed: action,
            child: Text(
              label,
              style: destructive ? TextStyle(color: error) : null,
            ),
          ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _FreqTag extends StatelessWidget {
  final String text;

  const _FreqTag(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: monoStyle(context, size: 10.5, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _CardsTab extends StatelessWidget {
  final CardFolderStore store;
  final VoidCallback onFolderChanged;

  const _CardsTab({required this.store, required this.onFolderChanged});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final prefs = appState.sharedPreferencesProvider;
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final allCards = prefs.getCards();
    final allFolders = store.all(prefs);
    if (_LibraryMemory.cardFolder != null &&
        !allFolders.any((f) => f.id == _LibraryMemory.cardFolder)) {
      _LibraryMemory.cardFolder = null;
    }
    final current = _LibraryMemory.cardFolder;
    final query = _LibraryMemory.cardQuery.trim().toLowerCase();
    final freq = _LibraryMemory.freq;

    bool matchesFreq(CardSave card) {
      if (freq == _Freq.all) return true;
      final f = chameleonTagToFrequency(card.tag);
      return freq == _Freq.hf ? f == TagFrequency.hf : f == TagFrequency.lf;
    }

    // A search looks through every folder; otherwise show the open folder.
    final folders = query.isEmpty
        ? (allFolders.where((f) => f.parentId == current).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ))
        : <_Folder>[];
    final cards =
        allCards
            .where(
              (c) => query.isEmpty
                  ? c.folderId == current
                  : c.name.toLowerCase().contains(query) ||
                        c.uid
                            .toLowerCase()
                            .replaceAll(' ', '')
                            .contains(query.replaceAll(' ', '')) ||
                        chameleonTagToString(
                          c.tag,
                          localizations,
                        ).toLowerCase().contains(query),
            )
            .where(matchesFreq)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    void open(String? id) {
      _LibraryMemory.cardFolder = id;
      onFolderChanged();
    }

    final header = _ListHeader(
      hint: strings.searchCards,
      query: _LibraryMemory.cardQuery,
      onQuery: (value) {
        _LibraryMemory.cardQuery = value;
        onFolderChanged();
      },
      path: _pathTo(current, allFolders),
      rootName: strings.library,
      onOpen: open,
      filters: Wrap(
        spacing: 8,
        children: [
          for (final (value, label) in [
            (_Freq.all, localizations.all),
            (_Freq.hf, 'HF · 13.56 MHz'),
            (_Freq.lf, 'LF · 125 kHz'),
          ])
            ChoiceChip(
              label: Text(label),
              selected: freq == value,
              visualDensity: VisualDensity.compact,
              onSelected: (_) {
                _LibraryMemory.freq = value;
                onFolderChanged();
              },
            ),
        ],
      ),
    );

    if (allCards.isEmpty && allFolders.isEmpty) {
      return EmptyState(
        icon: Icons.style_outlined,
        title: strings.noCardsYet,
        hint: strings.noCardsHint,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        header,
        if (folders.isEmpty && cards.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              query.isEmpty ? localizations.empty : strings.nothingFound,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final folder in folders)
          _FolderRow(
            folder: folder,
            subtitle: AppLocalizations.of(context)!.folder_card_count(() {
              final ids = folderTreeIds(
                folder.id,
                allFolders.map((f) => (id: f.id, parentId: f.parentId)),
              );
              return allCards.where((c) => ids.contains(c.folderId)).length;
            }()),
            onOpen: () => open(folder.id),
            onRename: () =>
                LibraryActions.editFolder(context, store, folder: folder),
            onMove: () => LibraryActions.moveFolder(context, store, folder),
            onExport: () => store.exportTree(context, folder.id, folder.name),
            onDelete: () => LibraryActions.deleteFolder(
              context,
              store,
              folder,
              message: localizations.delete_card_folder_confirmation,
            ),
          ),
        if (folders.isNotEmpty && cards.isNotEmpty) const Divider(indent: 16),
        for (final card in cards)
          _CardRow(
            card: card,
            selected: _LibraryMemory.selected.contains(card.id),
            selecting: _LibraryMemory.selected.isNotEmpty,
            onToggle: () {
              final s = _LibraryMemory.selected;
              s.contains(card.id) ? s.remove(card.id) : s.add(card.id);
              onFolderChanged();
            },
          ),
      ],
    );
  }
}

class _CardRow extends StatelessWidget {
  final CardSave card;
  final bool selected;
  final bool selecting;
  final VoidCallback onToggle;

  const _CardRow({
    required this.card,
    required this.selected,
    required this.selecting,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hf = chameleonTagToFrequency(card.tag) == TagFrequency.hf;

    return ListTile(
      selected: selected,
      selectedTileColor: scheme.primary.withValues(alpha: 0.10),
      onLongPress: onToggle,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : card.color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          selected
              ? Icons.check
              : hf
              ? Icons.credit_card
              : Icons.wifi_tethering,
          color: selected ? scheme.onPrimary : card.color,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              card.name.isEmpty ? '—' : card.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _FreqTag(hf ? 'HF' : 'LF'),
        ],
      ),
      subtitle: Text(
        '${card.uid.isEmpty ? '—' : card.uid} · ${chameleonTagToString(card.tag, localizations)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: monoStyle(context, size: 12, color: scheme.onSurfaceVariant),
      ),
      onTap: selecting ? onToggle : () => openCardPage(context, card),
      trailing: selecting
          ? null
          : _Overflow(
              items: [
                (
                  Icons.drive_file_move_outline,
                  strings.move,
                  () => LibraryActions.moveCard(context, card),
                  false,
                ),
                (
                  Icons.copy_all_outlined,
                  strings.duplicate,
                  () => LibraryActions.duplicateCard(context, card),
                  false,
                ),
                (
                  Icons.file_download_outlined,
                  strings.exportJson,
                  () => saveTag(card, context, false),
                  false,
                ),
                if (card.data.isNotEmpty)
                  (
                    Icons.file_download_outlined,
                    strings.exportBin,
                    () => saveTag(card, context, true),
                    false,
                  ),
                (
                  Icons.delete_outline,
                  strings.delete,
                  () => LibraryActions.deleteCard(context, card),
                  true,
                ),
              ],
            ),
    );
  }
}

class _DictionariesTab extends StatelessWidget {
  final DictionaryFolderStore store;
  final VoidCallback onFolderChanged;

  const _DictionariesTab({required this.store, required this.onFolderChanged});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final prefs = appState.sharedPreferencesProvider;
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final allDictionaries = prefs.getDictionaries();
    final allFolders = store.all(prefs);
    if (_LibraryMemory.dictionaryFolder != null &&
        !allFolders.any((f) => f.id == _LibraryMemory.dictionaryFolder)) {
      _LibraryMemory.dictionaryFolder = null;
    }
    final current = _LibraryMemory.dictionaryFolder;
    final query = _LibraryMemory.dictionaryQuery.trim().toLowerCase();

    final folders = query.isEmpty
        ? (allFolders.where((f) => f.parentId == current).toList()..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ))
        : <_Folder>[];
    final dictionaries =
        allDictionaries
            .where(
              (d) => query.isEmpty
                  ? d.folderId == current
                  : d.name.toLowerCase().contains(query),
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    void open(String? id) {
      _LibraryMemory.dictionaryFolder = id;
      onFolderChanged();
    }

    if (allDictionaries.isEmpty && allFolders.isEmpty) {
      return EmptyState(
        icon: Icons.key_off_outlined,
        title: strings.noDictionariesYet,
        hint: strings.noDictionariesHint,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _ListHeader(
          hint: strings.searchDictionaries,
          query: _LibraryMemory.dictionaryQuery,
          onQuery: (value) {
            _LibraryMemory.dictionaryQuery = value;
            onFolderChanged();
          },
          path: _pathTo(current, allFolders),
          rootName: localizations.dictionaries,
          onOpen: open,
        ),
        if (folders.isEmpty && dictionaries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              query.isEmpty ? localizations.empty : strings.nothingFound,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        for (final folder in folders)
          _FolderRow(
            folder: folder,
            subtitle: localizations.folder_dictionary_count(() {
              final ids = folderTreeIds(
                folder.id,
                allFolders.map((f) => (id: f.id, parentId: f.parentId)),
              );
              return allDictionaries
                  .where((d) => ids.contains(d.folderId))
                  .length;
            }()),
            onOpen: () => open(folder.id),
            onRename: () =>
                LibraryActions.editFolder(context, store, folder: folder),
            onMove: () => LibraryActions.moveFolder(context, store, folder),
            onExport: () => store.exportTree(context, folder.id, folder.name),
            onDelete: () => LibraryActions.deleteFolder(
              context,
              store,
              folder,
              message: localizations.delete_dictionary_folder_confirmation,
            ),
          ),
        if (folders.isNotEmpty && dictionaries.isNotEmpty)
          const Divider(indent: 16),
        for (final dictionary in dictionaries)
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dictionary.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.key, color: dictionary.color, size: 20),
            ),
            title: Text(
              dictionary.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${strings.keyCount(dictionary.keys.length)} · ${dictionary.keyLength ~/ 2} B',
              style: monoStyle(
                context,
                size: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
            onTap: () => openDictionaryPage(context, dictionary),
            trailing: _Overflow(
              items: [
                (
                  Icons.edit_outlined,
                  strings.edit,
                  () => openDictionaryPage(context, dictionary),
                  false,
                ),
                (
                  Icons.drive_file_move_outline,
                  strings.move,
                  () => LibraryActions.moveDictionary(context, dictionary),
                  false,
                ),
                (
                  Icons.file_download_outlined,
                  strings.exportDic,
                  () => LibraryActions.exportDictionary(context, dictionary),
                  false,
                ),
                (
                  Icons.delete_outline,
                  strings.delete,
                  () => LibraryActions.deleteDictionary(context, dictionary),
                  true,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
