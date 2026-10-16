import 'package:flutter/widgets.dart';

// Strings for the fork's redesigned UI. They live here instead of lib/l10n/*.arb so that
// upstream's Crowdin-managed translation files can be merged without conflicts.
// Existing upstream keys are still used through AppLocalizations wherever they fit.
class ForkStrings {
  final Map<String, String> _values;

  const ForkStrings._(this._values);

  static ForkStrings of(BuildContext context) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    return ForkStrings._(_translations[code] ?? _en);
  }

  String _get(String key) => _values[key] ?? _en[key]!;

  String get device => _get('device');
  String get scan => _get('scan');
  String get library => _get('library');
  String get tools => _get('tools');
  String get settings => _get('settings');
  String get debugTools => _get('debugTools');
  String get slots => _get('slots');
  String get noDevice => _get('noDevice');
  String get noDeviceScan => _get('noDeviceScan');
  String get goToDevice => _get('goToDevice');
  String get searchCards => _get('searchCards');
  String get searchDictionaries => _get('searchDictionaries');
  String get newCard => _get('newCard');
  String get newFolder => _get('newFolder');
  String get newDictionary => _get('newDictionary');
  String get importFile => _get('importFile');
  String get downloadDictionaries => _get('downloadDictionaries');
  String get noCardsYet => _get('noCardsYet');
  String get noCardsHint => _get('noCardsHint');
  String get noDictionariesYet => _get('noDictionariesYet');
  String get noDictionariesHint => _get('noDictionariesHint');
  String get nothingFound => _get('nothingFound');
  String get info => _get('info');
  String get data => _get('data');
  String get keys => _get('keys');
  String get ndef => _get('ndef');
  String get loadToSlot => _get('loadToSlot');
  String get writeToTag => _get('writeToTag');
  String get edit => _get('edit');
  String get editData => _get('editData');
  String get duplicate => _get('duplicate');
  String get move => _get('move');
  String get exportJson => _get('exportJson');
  String get exportBin => _get('exportBin');
  String get exportDic => _get('exportDic');
  String get export => _get('export');
  String get delete => _get('delete');
  String get rename => _get('rename');
  String get undo => _get('undo');
  String get copied => _get('copied');
  String get tapToCopy => _get('tapToCopy');
  String get noData => _get('noData');
  String get noKeys => _get('noKeys');
  String get saveKeysTo => _get('saveKeysTo');
  String get keyA => _get('keyA');
  String get keyB => _get('keyB');
  String get pickSlot => _get('pickSlot');
  String get connectFirst => _get('connectFirst');
  String get legend => _get('legend');
  String get hex => _get('hex');
  String get ascii => _get('ascii');
  String get importRawTitle => _get('importRawTitle');
  String get importFailed => _get('importFailed');
  String get uidLength => _get('uidLength');
  String get noDeviceFound => _get('noDeviceFound');
  String get searchingHint => _get('searchingHint');
  String get tryDemo => _get('tryDemo');
  String get connectByPort => _get('connectByPort');
  String get foundDevices => _get('foundDevices');
  String get retry => _get('retry');
  String get connectionFailed => _get('connectionFailed');
  String get refresh => _get('refresh');
  String get firmwareBroken => _get('firmwareBroken');
  String get modeEmulate => _get('modeEmulate');
  String get modeRead => _get('modeRead');
  String get active => _get('active');
  String get setActive => _get('setActive');
  String get loadCard => _get('loadCard');
  String get disconnect => _get('disconnect');
  String get demoDevice => _get('demoDevice');
  String get clearSlot => _get('clearSlot');
  String get viewData => _get('viewData');
  String get saveToLibrary => _get('saveToLibrary');
  String get slotEmpty => _get('slotEmpty');
  String get slotDisabled => _get('slotDisabled');
  String get loadFromLibrary => _get('loadFromLibrary');
  String get editSlot => _get('editSlot');
  String get emulationOptions => _get('emulationOptions');
  String get noEmulation => _get('noEmulation');
  String get outdatedProtocol => _get('outdatedProtocol');
  String slotsUsed(int used) => _get('slotsUsed').replaceAll('{used}', '$used');

  String deleted(String name) => _get('deleted').replaceAll('{name}', name);
  String loadedToSlot(int slot) =>
      _get('loadedToSlot').replaceAll('{slot}', '$slot');
  String cardCount(int count) =>
      _get('cardCount').replaceAll('{count}', '$count');
  String keyCount(int count) =>
      _get('keyCount').replaceAll('{count}', '$count');
  String sectorLabel(int sector, int first, int last) =>
      _get('sectorLabel')
          .replaceAll('{sector}', sector.toString().padLeft(2, '0'))
          .replaceAll('{first}', '$first')
          .replaceAll('{last}', '$last');
  String pages(int count) => _get('pages').replaceAll('{count}', '$count');
  String slotN(int slot) => _get('slotN').replaceAll('{slot}', '$slot');
}

const Map<String, Map<String, String>> _translations = {'en': _en, 'ru': _ru};

const Map<String, String> _en = {
  'device': 'Device',
  'scan': 'Scan',
  'library': 'Library',
  'tools': 'Tools',
  'settings': 'Settings',
  'debugTools': 'Debug tools',
  'slots': 'Slots',
  'noDevice': 'No device connected',
  'noDeviceScan': 'Connect a Chameleon to read cards.',
  'goToDevice': 'Connect device',
  'searchCards': 'Search cards',
  'searchDictionaries': 'Search dictionaries',
  'newCard': 'New card',
  'newFolder': 'New folder',
  'newDictionary': 'New dictionary',
  'importFile': 'Import file',
  'downloadDictionaries': 'Download dictionaries',
  'noCardsYet': 'No cards yet',
  'noCardsHint': 'Scan a card, import a dump, or create one with +.',
  'noDictionariesYet': 'No dictionaries yet',
  'noDictionariesHint': 'Import a .dic file or download a public one with +.',
  'nothingFound': 'Nothing matches your search.',
  'info': 'Info',
  'data': 'Data',
  'keys': 'Keys',
  'ndef': 'NDEF',
  'loadToSlot': 'Load to slot',
  'writeToTag': 'Write to tag',
  'edit': 'Edit',
  'editData': 'Edit data',
  'duplicate': 'Duplicate',
  'move': 'Move to folder',
  'exportJson': 'Export .json',
  'exportBin': 'Export .bin',
  'exportDic': 'Export .dic',
  'export': 'Export',
  'delete': 'Delete',
  'rename': 'Rename',
  'undo': 'Undo',
  'copied': 'Copied',
  'tapToCopy': 'Tap a value to copy it',
  'noData': 'This card has no data blocks, only its identifiers.',
  'noKeys': 'No keys in this dump.',
  'saveKeysTo': 'Save keys to…',
  'keyA': 'Key A',
  'keyB': 'Key B',
  'pickSlot': 'Load into slot',
  'connectFirst': 'Connect a Chameleon first.',
  'legend': 'Legend',
  'hex': 'HEX',
  'ascii': 'ASCII',
  'importRawTitle': 'Import raw dump',
  'importFailed': 'This file is not a dump the app can read.',
  'uidLength': 'UID length',
  'deleted': 'Deleted "{name}"',
  'loadedToSlot': 'Loaded into slot {slot}',
  'cardCount': '{count} cards',
  'keyCount': '{count} keys',
  'sectorLabel': 'SECTOR {sector} · blocks {first}–{last}',
  'pages': '{count} pages',
  'slotN': 'Slot {slot}',
  'noDeviceFound': 'No Chameleon found',
  'searchingHint': 'Plug it in over USB or switch it on for Bluetooth. Searching every few seconds.',
  'tryDemo': 'Try demo mode',
  'connectByPort': 'Connect by port',
  'foundDevices': 'Found devices',
  'retry': 'Try again',
  'connectionFailed': 'Could not connect',
  'refresh': 'Refresh',
  'firmwareBroken': 'Needs firmware',
  'modeEmulate': 'Emulate',
  'modeRead': 'Read',
  'active': 'Active',
  'setActive': 'Set as active',
  'loadCard': 'Load card…',
  'disconnect': 'Disconnect',
  'demoDevice': 'Demo device: data is fake. Turn it off in Settings.',
  'clearSlot': 'Clear',
  'viewData': 'View data',
  'saveToLibrary': 'Save to library',
  'slotEmpty': 'Empty',
  'slotDisabled': 'Off',
  'loadFromLibrary': 'Load from library',
  'editSlot': 'Edit',
  'emulationOptions': 'Magic modes, PRNG, write mode and Mfkey32 nonce collection are under HF › Edit.',
  'noEmulation': 'This card type cannot be emulated yet.',
  'outdatedProtocol':
      'This firmware uses an old protocol. Update it to use the app fully.',
  'slotsUsed': 'Slots · {used}/8 used',
};

const Map<String, String> _ru = {
  'device': 'Устройство',
  'scan': 'Сканер',
  'library': 'Библиотека',
  'tools': 'Инструменты',
  'settings': 'Настройки',
  'debugTools': 'Отладка',
  'slots': 'Слоты',
  'noDevice': 'Устройство не подключено',
  'noDeviceScan': 'Подключите Chameleon, чтобы читать карты.',
  'goToDevice': 'Подключить',
  'searchCards': 'Поиск карт',
  'searchDictionaries': 'Поиск словарей',
  'newCard': 'Новая карта',
  'newFolder': 'Новая папка',
  'newDictionary': 'Новый словарь',
  'importFile': 'Импорт файла',
  'downloadDictionaries': 'Скачать словари',
  'noCardsYet': 'Карт пока нет',
  'noCardsHint':
      'Отсканируйте карту, импортируйте дамп или создайте карту кнопкой +.',
  'noDictionariesYet': 'Словарей пока нет',
  'noDictionariesHint':
      'Импортируйте файл .dic или скачайте готовый кнопкой +.',
  'nothingFound': 'Ничего не найдено.',
  'info': 'Инфо',
  'data': 'Данные',
  'keys': 'Ключи',
  'ndef': 'NDEF',
  'loadToSlot': 'В слот',
  'writeToTag': 'Записать на метку',
  'edit': 'Изменить',
  'editData': 'Редактировать данные',
  'duplicate': 'Дублировать',
  'move': 'Переместить в папку',
  'exportJson': 'Экспорт .json',
  'exportBin': 'Экспорт .bin',
  'exportDic': 'Экспорт .dic',
  'export': 'Экспорт',
  'delete': 'Удалить',
  'rename': 'Переименовать',
  'undo': 'Отменить',
  'copied': 'Скопировано',
  'tapToCopy': 'Нажмите на значение, чтобы скопировать',
  'noData': 'У этой карты нет блоков данных, только идентификаторы.',
  'noKeys': 'В дампе нет ключей.',
  'saveKeysTo': 'Сохранить ключи…',
  'keyA': 'Ключ A',
  'keyB': 'Ключ B',
  'pickSlot': 'Загрузить в слот',
  'connectFirst': 'Сначала подключите Chameleon.',
  'legend': 'Легенда',
  'hex': 'HEX',
  'ascii': 'ASCII',
  'importRawTitle': 'Импорт сырого дампа',
  'importFailed': 'Не удалось прочитать дамп из этого файла.',
  'uidLength': 'Длина UID',
  'deleted': 'Удалено: «{name}»',
  'loadedToSlot': 'Загружено в слот {slot}',
  'cardCount': 'Карт: {count}',
  'keyCount': 'Ключей: {count}',
  'sectorLabel': 'СЕКТОР {sector} · блоки {first}–{last}',
  'pages': 'Страниц: {count}',
  'slotN': 'Слот {slot}',
  'noDeviceFound': 'Chameleon не найден',
  'searchingHint': 'Подключите его по USB или включите для Bluetooth. Поиск идёт каждые несколько секунд.',
  'tryDemo': 'Демо-режим',
  'connectByPort': 'Подключить по порту',
  'foundDevices': 'Найденные устройства',
  'retry': 'Повторить',
  'connectionFailed': 'Не удалось подключиться',
  'refresh': 'Обновить',
  'firmwareBroken': 'Нужна прошивка',
  'modeEmulate': 'Эмуляция',
  'modeRead': 'Чтение',
  'active': 'Активен',
  'setActive': 'Сделать активным',
  'loadCard': 'Загрузить карту…',
  'disconnect': 'Отключить',
  'demoDevice':
      'Демо-устройство: данные ненастоящие. Отключается в настройках.',
  'clearSlot': 'Очистить',
  'viewData': 'Данные',
  'saveToLibrary': 'В библиотеку',
  'slotEmpty': 'Пусто',
  'slotDisabled': 'Выкл',
  'loadFromLibrary': 'Из библиотеки',
  'editSlot': 'Изменить',
  'emulationOptions': 'Magic-режимы, PRNG, режим записи и сбор nonce для Mfkey32 — в HF › Изменить.',
  'noEmulation': 'Этот тип карты пока нельзя эмулировать.',
  'outdatedProtocol': 'Прошивка использует старый протокол. Обновите её для полной работы приложения.',
  'slotsUsed': 'Слоты · занято {used}/8',
};
