import 'package:chameleonultragui/fork/library/library_actions.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/component/mifare/vanity_sak_checkbox.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/mifare_classic/general.dart';
import 'package:chameleonultragui/helpers/mifare_classic/vanity_sak.dart';
import 'package:chameleonultragui/helpers/mifare_ultralight/general.dart';
import 'package:chameleonultragui/helpers/validators.dart';
import 'package:chameleonultragui/main.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> openCardForm(
  BuildContext context, {
  CardSave? card,
  String? folderId,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CardFormPage(card: card, folderId: folderId),
    ),
  );
}

// Create or edit a saved card on one page (replaces upstream's Create / Edit card dialogs in
// the fork). Same rules as upstream: HID Prox fields, Ultralight extras, vanity SAK, and on edit
// an offer to patch block 0 / the first pages when identifiers change.
class CardFormPage extends StatefulWidget {
  final CardSave? card; // null = new card
  final String? folderId;

  const CardFormPage({super.key, this.card, this.folderId});

  @override
  State<CardFormPage> createState() => _CardFormPageState();
}

class _CardFormPageState extends State<CardFormPage> {
  final formKey = GlobalKey<FormState>();
  late TagType type = widget.card?.tag ?? TagType.mifare1K;
  late Color color = widget.card?.color ?? swatchColors.first;
  final name = TextEditingController();
  final uid = TextEditingController();
  final sak = TextEditingController();
  final atqa = TextEditingController();
  final ats = TextEditingController();
  final ulVersion = TextEditingController();
  final ulSignature = TextEditingController();
  List<TextEditingController> counters = [];
  final hidType = TextEditingController(text: '1');
  final facilityCode = TextEditingController();
  final issueLevel = TextEditingController();
  final oem = TextEditingController();

  bool vanitySak = false;
  bool? originalVanitySak;
  String originalUid = '';
  String originalSak = '';
  String originalAtqa = '';
  int originalUidBytes = 0;

  bool get isNew => widget.card == null;
  bool get lf => chameleonTagToFrequency(type) == TagFrequency.lf;

  bool get showVanitySak => isNew
      ? isMifareClassic(type)
      : mfClassicVanitySakVisibleInEdit(type, widget.card!.data);

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    if (card != null) {
      name.text = card.name;
      uid.text = card.uid;
      sak.text = bytesToHexSpace(u8ToBytes(card.sak));
      atqa.text = bytesToHexSpace(card.atqa);
      ats.text = bytesToHexSpace(card.ats);
      ulVersion.text = bytesToHexSpace(card.extraData.ultralightVersion);
      ulSignature.text = bytesToHexSpace(card.extraData.ultralightSignature);
      originalUid = card.uid;
      originalSak = sak.text;
      originalAtqa = atqa.text;
      originalUidBytes = hexToBytes(card.uid).length;
      if (type == TagType.hidProx) _initHid(card.uid);
      if (showVanitySak) {
        vanitySak =
            mfClassicVanitySakFromData(
              uid: hexToBytes(card.uid),
              sak: card.sak,
              block0: card.data[0],
            ) ??
            mfClassicVanitySakFromUidHex(card.uid) ??
            false;
        originalVanitySak = vanitySak;
      }
    }
    _initCounters();
  }

  @override
  void dispose() {
    for (final c in [
      name,
      uid,
      sak,
      atqa,
      ats,
      ulVersion,
      ulSignature,
      hidType,
      facilityCode,
      issueLevel,
      oem,
      ...counters,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initHid(String uidText) {
    final hid = HIDCard.fromUID(uidText);
    uid.text = bytesToHexSpace(hid.uid);
    hidType.text = hid.hidType.toString();
    facilityCode.text = hid.facilityCode.toString();
    issueLevel.text = hid.issueLevel.toString();
    oem.text = hid.oem.toString();
  }

  void _initCounters() {
    final existing = widget.card?.extraData.ultralightCounters ?? const <int>[];
    counters = [
      for (var i = 0; i < mfUltralightGetCounterCount(type); i++)
        TextEditingController(
          text: i < existing.length ? '${existing[i]}' : '0',
        ),
    ];
  }

  void _refreshVanitySak() {
    final fromUid = mfClassicVanitySakFromUidHex(uid.text);
    if (fromUid == null) return;
    final bytes = uid.text.replaceAll(' ', '').length ~/ 2;
    setState(() {
      vanitySak = !isNew && bytes == originalUidBytes
          ? (originalVanitySak ?? fromUid)
          : fromUid;
    });
  }

  Future<void> _pickType() async {
    final localizations = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<TagType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: ListView(
          children: [
            for (final (label, freq) in [
              ('HF · 13.56 MHz', TagFrequency.hf),
              ('LF · 125 kHz', TagFrequency.lf),
            ]) ...[
              SectionLabel(label),
              for (final t in getTagTypesByFrequency(freq))
                ListTile(
                  title: Text(chameleonTagToString(t, localizations)),
                  trailing: t == type ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, t),
                ),
            ],
          ],
        ),
      ),
    );
    if (picked == null || picked == type) return;
    setState(() {
      type = picked;
      for (final c in counters) {
        c.dispose();
      }
      _initCounters();
    });
    if (originalVanitySak == null) {
      _refreshVanitySak();
      originalVanitySak = vanitySak;
    }
  }

  String _finalUid() {
    if (type == TagType.hidProx) {
      try {
        return HIDCard(
          hidType: int.parse(hidType.text),
          facilityCode: int.parse(facilityCode.text),
          uid: hexToBytes(uid.text.replaceAll(' ', '')),
          issueLevel: int.parse(issueLevel.text),
          oem: int.parse(oem.text),
        ).toString();
      } catch (_) {}
    }
    return bytesToHexSpace(hexToBytes(uid.text));
  }

  List<Uint8List> _newBlocks() {
    if (lf) return [];
    if (isMifareClassic(type)) {
      final blocks = <Uint8List>[];
      final sectors = mfClassicGetSectorCount(
        chameleonTagTypeGetMfClassicType(type),
      );
      for (var sector = 0; sector < sectors; sector++) {
        for (var b = 0; b < mfClassicGetBlockCountBySector(sector) - 1; b++) {
          blocks.add(Uint8List(16));
        }
        blocks.add(
          Uint8List.fromList([
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x07, //
            0x80, 0x69, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
          ]),
        );
      }
      blocks[0] = mfClassicGenerateFirstBlock(
        hexToBytes(uid.text),
        hexToBytes(sak.text)[0],
        hexToBytes(atqa.text),
        vanitySak,
      );
      return blocks;
    }
    if (isMifareUltralight(type)) {
      final blocks = mfUltralightGenerateFirstBlocks(
        hexToBytes(uid.text),
        type,
      );
      blocks.add(
        Uint8List.fromList([
          0xE1,
          0x10,
          (getMemorySizeForTagType(type) ~/ 8) & 0xFF,
          0x00,
        ]),
      );
      for (var i = 4; i < getBlockCountForTagType(type); i++) {
        blocks.add(Uint8List(4));
      }
      return blocks;
    }
    return [];
  }

  Future<List<Uint8List>> _editedBlocks() async {
    final card = widget.card!;
    final changed =
        uid.text != originalUid ||
        sak.text != originalSak ||
        atqa.text != originalAtqa ||
        (originalVanitySak != null && vanitySak != originalVanitySak);
    final patchable =
        card.data.isNotEmpty &&
        (isMifareClassic(type) || isMifareUltralight(type));
    if (!changed || !patchable) return card.data;

    final localizations = AppLocalizations.of(context)!;
    final update =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.update_data_title),
            content: Text(localizations.update_data_message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.no),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations.yes),
              ),
            ],
          ),
        ) ??
        false;
    if (!update) return card.data;

    final data = List<Uint8List>.from(card.data);
    if (isMifareClassic(type)) {
      data[0] = mfClassicPatchFirstBlock(
        data[0],
        hexToBytes(uid.text),
        hexToBytes(sak.text)[0],
        hexToBytes(atqa.text),
        vanitySak,
      );
    } else {
      final first = mfUltralightGenerateFirstBlocks(hexToBytes(uid.text), type);
      for (var i = 0; i < first.length && i < data.length; i++) {
        data[i] = first[i];
      }
    }
    return data;
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final appState = context.read<ChameleonGUIState>();
    final prefs = appState.sharedPreferencesProvider;
    final data = isNew ? _newBlocks() : await _editedBlocks();
    if (!mounted) return;

    final card = CardSave(
      id: widget.card?.id,
      folderId: widget.card?.folderId ?? widget.folderId,
      name: name.text,
      tag: type,
      uid: _finalUid(),
      sak: lf ? (widget.card?.sak ?? 0) : hexToBytes(sak.text)[0],
      atqa: lf && isNew ? Uint8List(0) : hexToBytes(atqa.text),
      ats: lf && isNew ? Uint8List(0) : hexToBytes(ats.text),
      data: data,
      color: color,
      extraData: CardSaveExtra(
        ultralightSignature: hexToBytes(ulSignature.text),
        ultralightVersion: hexToBytes(ulVersion.text),
        ultralightCounters: counters
            .map((c) => int.tryParse(c.text) ?? 0)
            .toList(),
      ),
    );

    final cards = prefs.getCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    prefs.setCards(cards);
    appState.changesMade();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final mono = monoStyle(context, size: 15);

    Widget gap() => const SizedBox(height: 14);
    Widget hexField(
      TextEditingController c,
      String label,
      String? Function(String?) validator, {
      ValueChanged<String>? onChanged,
    }) => TextFormField(
      controller: c,
      style: mono,
      inputFormatters: hexFormatter,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
    Widget numberField(
      TextEditingController c,
      String label,
      int min,
      int max, {
      String? empty,
    }) => TextFormField(
      controller: c,
      style: mono,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => validateIntRange(
        v,
        localizations,
        min: min,
        max: max,
        emptyMessage: empty,
      ),
      decoration: InputDecoration(labelText: label),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? localizations.create_card : strings.editCard),
        actions: [
          IconButton(
            tooltip: localizations.save,
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SectionLabel(strings.appearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: name,
                    autofocus: isNew,
                    validator: (v) => validateName(v, localizations),
                    decoration: InputDecoration(
                      labelText: localizations.name,
                      prefixIcon: Icon(
                        lf ? Icons.wifi_tethering : Icons.credit_card,
                        color: color,
                      ),
                    ),
                  ),
                  gap(),
                  SwatchPicker(
                    value: color,
                    onChanged: (c) => setState(() => color = c),
                  ),
                ],
              ),
            ),
            SectionLabel(strings.cardType),
            ListTile(
              title: Text(chameleonTagToString(type, localizations)),
              subtitle: Text(
                lf ? 'LF · 125 kHz' : 'HF · 13.56 MHz',
                style: monoStyle(context, size: 12),
              ),
              trailing: const Icon(Icons.unfold_more),
              onTap: _pickType,
            ),
            SectionLabel(strings.identifiers),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  hexField(
                    uid,
                    localizations.uid,
                    (v) => validateUid(v, localizations, type),
                    onChanged: (_) => _refreshVanitySak(),
                  ),
                  if (!lf) ...[
                    gap(),
                    hexField(
                      sak,
                      localizations.sak,
                      (v) => validateHex(
                        v,
                        localizations,
                        exactBytes: 1,
                        fieldName: localizations.sak,
                        required: true,
                      ),
                    ),
                    if (showVanitySak)
                      VanitySakCheckbox(
                        value: vanitySak,
                        onChanged: (v) => setState(() => vanitySak = v!),
                      ),
                    gap(),
                    hexField(
                      atqa,
                      localizations.atqa,
                      (v) => validateHex(
                        v,
                        localizations,
                        exactBytes: 2,
                        fieldName: localizations.atqa,
                        required: true,
                      ),
                    ),
                    gap(),
                    hexField(
                      ats,
                      localizations.ats,
                      (v) => validateHex(v, localizations),
                    ),
                  ],
                ],
              ),
            ),
            if (type == TagType.hidProx) ...[
              SectionLabel(strings.hidFields),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: int.tryParse(hidType.text) ?? 1,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Format'),
                      items: [
                        for (var t = 1; t <= 30; t++)
                          DropdownMenuItem(
                            value: t,
                            child: Text(getNameForHIDProxType(t)),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => hidType.text = '${v ?? 1}'),
                    ),
                    gap(),
                    numberField(
                      facilityCode,
                      localizations.facility_code,
                      0,
                      4294967295,
                    ),
                    gap(),
                    numberField(issueLevel, localizations.issue_level, 0, 255),
                    gap(),
                    numberField(oem, 'OEM', 0, 65535),
                  ],
                ),
              ),
            ],
            if (isMifareUltralight(type)) ...[
              SectionLabel(strings.ultralightExtras),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    hexField(
                      ulVersion,
                      localizations.ultralight_version,
                      (v) => validateHex(
                        v,
                        localizations,
                        exactBytes: 8,
                        fieldName: localizations.ultralight_version,
                      ),
                    ),
                    gap(),
                    hexField(
                      ulSignature,
                      localizations.ultralight_signature,
                      (v) => validateHex(v, localizations),
                    ),
                    if (!isNew && mfUltralightHasCounters(type))
                      for (var i = 0; i < counters.length; i++) ...[
                        gap(),
                        numberField(
                          counters[i],
                          localizations.ultralight_counter(i),
                          0,
                          16777215,
                          empty: localizations.counter_value_empty,
                        ),
                      ],
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _save,
                child: Text(isNew ? localizations.create : localizations.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
