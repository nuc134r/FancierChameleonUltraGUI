import 'dart:typed_data';

import 'package:chameleonultragui/bridge/chameleon.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/hf14a4_slot.dart';
import 'package:chameleonultragui/helpers/mifare_classic/general.dart';
import 'package:chameleonultragui/helpers/mifare_ultralight/general.dart';
import 'package:chameleonultragui/sharedprefsprovider.dart';

// Uploads a saved card into a slot (0-based) and makes that slot active. Same device
// commands as upstream's SlotManagerPage.onTap, without its UI. Returns false for card types
// the firmware cannot emulate yet.
Future<bool> loadCardToSlot(
  ChameleonCommunicator communicator,
  int slot,
  CardSave card, {
  required String fallbackName,
  void Function(double progress)? onProgress,
}) async {
  final name = card.name.isEmpty ? fallbackName : card.name;
  final lfSetters = <TagType, Future<void> Function()>{
    TagType.hidProx: () => communicator.setHIDProxEmulatorID(
      hexToBytes(HIDCard.fromUID(card.uid).toString()),
    ),
    TagType.viking: () =>
        communicator.setVikingEmulatorID(hexToBytes(card.uid)),
    TagType.pac: () => communicator.setPacEmulatorID(hexToBytes(card.uid)),
    TagType.ioProx: () =>
        communicator.setIoProxEmulatorID(hexToBytes(card.uid)),
    TagType.idteck: () =>
        communicator.setIdteckEmulatorID(hexToBytes(card.uid)),
  };

  Future<void> prepare(TagFrequency frequency, TagType type) async {
    await communicator.setReaderDeviceMode(false);
    await communicator.enableSlot(slot, frequency, true);
    await communicator.activateSlot(slot);
    await communicator.setSlotType(slot, type);
    await communicator.setDefaultDataToSlot(slot, type);
  }

  Future<void> finish(TagFrequency frequency) async {
    onProgress?.call(1);
    await communicator.setSlotTagName(slot, name, frequency);
    await communicator.saveSlotData();
  }

  CardData antiCollision() => CardData(
    uid: hexToBytes(card.uid),
    atqa: card.atqa,
    sak: card.sak,
    ats: card.ats,
  );

  if (isMifareClassic(card.tag)) {
    var tag = card.tag;
    if (chameleonTagSaveCheckForMifareClassicEV1(card)) {
      tag = TagType.mifare2K;
    }
    onProgress?.call(0);
    await prepare(TagFrequency.hf, tag);
    await communicator.setMf1AntiCollision(antiCollision());

    final blockCount = mfClassicGetBlockCount(
      chameleonTagTypeGetMfClassicType(tag),
    );
    var chunk = <int>[];
    var lastSend = 0;
    for (var block = 0; block < blockCount; block++) {
      if ((card.data.length > block && card.data[block].isEmpty) ||
          chunk.length >= 128) {
        if (chunk.isNotEmpty) {
          await communicator.setMf1BlockData(
            lastSend,
            Uint8List.fromList(chunk),
          );
          chunk = [];
          lastSend = block;
        }
      }
      if (card.data.length > block && card.data[block].length == 16) {
        chunk.addAll(card.data[block]);
      }
      onProgress?.call(block / blockCount);
      await asyncSleep(1);
    }
    if (chunk.isNotEmpty) {
      await communicator.setMf1BlockData(lastSend, Uint8List.fromList(chunk));
    }
    await finish(TagFrequency.hf);
    return true;
  }

  if (card.tag == TagType.hf14a4) {
    await prepare(TagFrequency.hf, card.tag);
    await writeHf14a4SlotIdentity(communicator, card);
    await finish(TagFrequency.hf);
    return true;
  }

  if (isMifareUltralight(card.tag)) {
    onProgress?.call(0);
    await prepare(TagFrequency.hf, card.tag);
    await communicator.setMf1AntiCollision(antiCollision());
    final pages = mfUltralightGetPagesCount(card.tag);
    for (var page = 0; page < pages && card.data.length > page; page++) {
      await communicator.mf0EmulatorWritePages(page, card.data[page]);
      onProgress?.call(page / pages);
      await asyncSleep(1);
    }
    final extra = card.extraData;
    if (extra.ultralightVersion.isNotEmpty) {
      await communicator.mf0EmulatorSetVersionData(extra.ultralightVersion);
    }
    if (extra.ultralightSignature.isNotEmpty) {
      await communicator.mf0EmulatorSetSignatureData(extra.ultralightSignature);
    }
    for (var i = 0; i < extra.ultralightCounters.length; i++) {
      await communicator.mf0EmulatorSetCounterData(
        i,
        extra.ultralightCounters[i],
        true,
      );
    }
    if (mfUltralightHasCounters(card.tag)) {
      await communicator.mf0ResetAuthCount();
    }
    await finish(TagFrequency.hf);
    return true;
  }

  if (isEM410X(card.tag)) {
    final type = card.tag == TagType.em410XElectra
        ? TagType.em410XElectra
        : TagType.em410X;
    await prepare(TagFrequency.lf, type);
    await communicator.setEM410XEmulatorID(hexToBytes(card.uid));
    await finish(TagFrequency.lf);
    return true;
  }

  final setter = lfSetters[card.tag];
  if (setter != null) {
    await prepare(TagFrequency.lf, card.tag);
    await setter();
    await finish(TagFrequency.lf);
    return true;
  }

  return false;
}
