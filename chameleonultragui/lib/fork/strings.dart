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
  String get groupFirmware => _get('groupFirmware');
  String get groupButtons => _get('groupButtons');
  String get groupLed => _get('groupLed');
  String get groupBluetooth => _get('groupBluetooth');
  String get groupPower => _get('groupPower');
  String get dangerZone => _get('dangerZone');
  String get press => _get('press');
  String get longPressSuffix => _get('longPressSuffix');
  String get pairingRequired => _get('pairingRequired');
  String get pairingHint => _get('pairingHint');
  String get notSupported => _get('notSupported');
  String get enterDfuHint => _get('enterDfuHint');
  String get flashLatestHint => _get('flashLatestHint');
  String get flashZipHint => _get('flashZipHint');
  String get resetSettingsHint => _get('resetSettingsHint');
  String get factoryResetHint => _get('factoryResetHint');
  String get seconds => _get('seconds');
  String get ms => _get('ms');
  String get scanAction => _get('scanAction');
  String get scanAgain => _get('scanAgain');
  String get keepScanning => _get('keepScanning');
  String get stopScanning => _get('stopScanning');
  String get holdCard => _get('holdCard');
  String get holdCardHf => _get('holdCardHf');
  String get holdCardLf => _get('holdCardLf');
  String get stepKeys => _get('stepKeys');
  String get stepRecover => _get('stepRecover');
  String get stepDump => _get('stepDump');
  String get saved => _get('saved');
  String get open => _get('open');
  String get folder => _get('folder');
  String get backdoor => _get('backdoor');
  String get ev1 => _get('ev1');
  String get dictionary => _get('dictionary');
  String get skipDefault => _get('skipDefault');
  String get tryAnotherCard => _get('tryAnotherCard');
  String get searchKeys => _get('searchKeys');
  String get mergeInto => _get('mergeInto');
  String get merge => _get('merge');
  String get copyAll => _get('copyAll');
  String get keysHint => _get('keysHint');
  String get noKeysEntered => _get('noKeysEntered');
  String get save => _get('save');
  String ignoredLines(int n) => _get('ignoredLines').replaceAll('{n}', '$n');
  String mergedKeys(int n) => _get('mergedKeys').replaceAll('{n}', '$n');

  String selectedCount(int n) => _get('selectedCount').replaceAll('{n}', '$n');
  String deletedCount(int n) => _get('deletedCount').replaceAll('{n}', '$n');
  String get selectAll => _get('selectAll');
  String get groupAppearance => _get('groupAppearance');
  String get groupConnection => _get('groupConnection');
  String get groupBackup => _get('groupBackup');
  String get groupAbout => _get('groupAbout');
  String get groupDeveloper => _get('groupDeveloper');
  String get accent => _get('accent');
  String get pcbGold => _get('pcbGold');
  String get autoScanHint => _get('autoScanHint');
  String get autoConnectHint => _get('autoConnectHint');
  String get confirmDeleteHint => _get('confirmDeleteHint');
  String get exportHint => _get('exportHint');
  String get importHint => _get('importHint');
  String get demoHint => _get('demoHint');
  String get debugHint => _get('debugHint');
  String get forkNote => _get('forkNote');
  String get sourceCode => _get('sourceCode');
  String get upstreamProject => _get('upstreamProject');
  String get cardType => _get('cardType');
  String get identifiers => _get('identifiers');
  String get ultralightExtras => _get('ultralightExtras');
  String get hidFields => _get('hidFields');
  String get appearance => _get('appearance');
  String get editCard => _get('editCard');

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
  'groupFirmware': 'Firmware',
  'groupButtons': 'Buttons',
  'groupLed': 'LEDs',
  'groupBluetooth': 'Bluetooth',
  'groupPower': 'Power',
  'dangerZone': 'Danger zone',
  'press': 'press',
  'longPressSuffix': 'long press',
  'pairingRequired': 'Require pairing',
  'pairingHint': 'Ask for a PIN before a phone can connect over BLE',
  'notSupported': 'Not supported by this firmware',
  'enterDfuHint': 'Reboots into firmware update mode',
  'flashLatestHint': 'Download and install the newest firmware',
  'flashZipHint': 'Install firmware from a .zip file',
  'resetSettingsHint': 'Animations, buttons and BLE back to defaults',
  'factoryResetHint': 'Erases all slots and settings',
  'seconds': 's',
  'ms': 'ms',
  'scanAction': 'Scan',
  'scanAgain': 'Scan again',
  'keepScanning': 'Keep scanning',
  'stopScanning': 'Stop scanning',
  'holdCard': 'Hold a card to the Chameleon',
  'holdCardHf': 'HF reads 13.56 MHz cards: MIFARE Classic, Ultralight, NTAG.',
  'holdCardLf':
      'LF reads 125 kHz cards: EM410x, HID Prox, Viking, PAC, ioProx.',
  'stepKeys': 'Keys',
  'stepRecover': 'Recover',
  'stepDump': 'Dump',
  'saved': 'Saved to library',
  'open': 'Open',
  'folder': 'Folder',
  'backdoor': 'Backdoor',
  'ev1': 'EV1',
  'dictionary': 'Dictionary',
  'skipDefault': 'Skip built-in keys',
  'tryAnotherCard': 'Move the card a little or try another one.',
  'searchKeys': 'Search keys',
  'mergeInto': 'Merge other dictionaries in…',
  'merge': 'Merge',
  'copyAll': 'Copy all keys',
  'keysHint': 'One hex key per line. Text after # or a space is ignored.',
  'noKeysEntered': 'Add at least one valid key.',
  'save': 'Save',
  'ignoredLines': 'Saved. {n} lines were not valid keys and were skipped.',
  'mergedKeys': 'Added {n} new keys',
  'selectedCount': '{n} selected',
  'deletedCount': 'Deleted {n} cards',
  'selectAll': 'Select all',
  'groupAppearance': 'Appearance',
  'groupConnection': 'Connection',
  'groupBackup': 'Backup',
  'groupAbout': 'About',
  'groupDeveloper': 'Developer',
  'accent': 'Accent colour',
  'pcbGold': 'PCB gold',
  'autoScanHint': 'Look for a Chameleon every few seconds',
  'autoConnectHint': 'Connect to the first Chameleon found',
  'confirmDeleteHint': 'Ask before deleting; Undo is always offered',
  'exportHint': 'Cards, dictionaries and settings to a QR code or a file',
  'importHint': 'Restore from a QR code or a file',
  'demoHint': 'A fake Chameleon for trying the app',
  'debugHint': 'Shows Debug tools under the gear menu',
  'forkNote': 'This build is a fork with a redesigned interface.',
  'sourceCode': 'Source code',
  'upstreamProject': 'Original project',
  'cardType': 'Card type',
  'identifiers': 'Identifiers',
  'ultralightExtras': 'Ultralight extras',
  'hidFields': 'HID Prox fields',
  'appearance': 'Look',
  'editCard': 'Edit card',
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
  'groupFirmware': 'Прошивка',
  'groupButtons': 'Кнопки',
  'groupLed': 'Светодиоды',
  'groupBluetooth': 'Bluetooth',
  'groupPower': 'Питание',
  'dangerZone': 'Опасная зона',
  'press': 'нажатие',
  'longPressSuffix': 'долгое нажатие',
  'pairingRequired': 'Требовать сопряжение',
  'pairingHint': 'Спрашивать PIN перед подключением телефона по BLE',
  'notSupported': 'Не поддерживается этой прошивкой',
  'enterDfuHint': 'Перезагрузка в режим обновления прошивки',
  'flashLatestHint': 'Скачать и установить свежую прошивку',
  'flashZipHint': 'Установить прошивку из .zip-файла',
  'resetSettingsHint': 'Анимации, кнопки и BLE — по умолчанию',
  'factoryResetHint': 'Стирает все слоты и настройки',
  'seconds': 'с',
  'ms': 'мс',
  'scanAction': 'Сканировать',
  'scanAgain': 'Ещё раз',
  'keepScanning': 'Сканировать непрерывно',
  'stopScanning': 'Остановить',
  'holdCard': 'Поднесите карту к Chameleon',
  'holdCardHf': 'HF читает карты 13,56 МГц: MIFARE Classic, Ultralight, NTAG.',
  'holdCardLf':
      'LF читает карты 125 кГц: EM410x, HID Prox, Viking, PAC, ioProx.',
  'stepKeys': 'Ключи',
  'stepRecover': 'Подбор',
  'stepDump': 'Дамп',
  'saved': 'Сохранено в библиотеку',
  'open': 'Открыть',
  'folder': 'Папка',
  'backdoor': 'Бэкдор',
  'ev1': 'EV1',
  'dictionary': 'Словарь',
  'skipDefault': 'Без встроенных ключей',
  'tryAnotherCard': 'Сдвиньте карту или попробуйте другую.',
  'searchKeys': 'Поиск ключей',
  'mergeInto': 'Добавить ключи из других словарей…',
  'merge': 'Объединить',
  'copyAll': 'Скопировать все ключи',
  'keysHint':
      'Один hex-ключ на строку. Текст после # или пробела игнорируется.',
  'noKeysEntered': 'Добавьте хотя бы один корректный ключ.',
  'save': 'Сохранить',
  'ignoredLines': 'Сохранено. Пропущено строк с неверными ключами: {n}.',
  'mergedKeys': 'Добавлено новых ключей: {n}',
  'selectedCount': 'Выбрано: {n}',
  'deletedCount': 'Удалено карт: {n}',
  'selectAll': 'Выбрать все',
  'groupAppearance': 'Оформление',
  'groupConnection': 'Подключение',
  'groupBackup': 'Резервная копия',
  'groupAbout': 'О приложении',
  'groupDeveloper': 'Для разработчиков',
  'accent': 'Цвет акцента',
  'pcbGold': 'Золото платы',
  'autoScanHint': 'Искать Chameleon каждые несколько секунд',
  'autoConnectHint': 'Подключаться к первому найденному Chameleon',
  'confirmDeleteHint': 'Спрашивать перед удалением; отмена доступна всегда',
  'exportHint': 'Карты, словари и настройки в QR-код или файл',
  'importHint': 'Восстановить из QR-кода или файла',
  'demoHint': 'Ненастоящий Chameleon, чтобы попробовать приложение',
  'debugHint': 'Показывает «Отладку» в меню шестерёнки',
  'forkNote': 'Это сборка-форк с переработанным интерфейсом.',
  'sourceCode': 'Исходный код',
  'upstreamProject': 'Оригинальный проект',
  'cardType': 'Тип карты',
  'identifiers': 'Идентификаторы',
  'ultralightExtras': 'Параметры Ultralight',
  'hidFields': 'Поля HID Prox',
  'appearance': 'Вид',
  'editCard': 'Изменить карту',
};
