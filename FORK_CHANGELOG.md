# Changelog (fork)

Release notes for this fork's GitHub releases. Each `## <version>` section becomes the notes of
the release tagged `v<version>` (see docs/FORK_RELEASING.md). Upstream's history is in its own releases.

## 2.3.3

- Scan tab: the HF | LF switch and the Scan / Keep scanning buttons sit at the bottom, above the
  tab bar, within thumb reach. Results scroll above them.
- Slot page: the on/off switch shows only for a side with a card (or an empty side that is still on,
  with a hint to turn it off), plus a note on what it does: an off side keeps its card without
  emulating it, and the buttons skip a slot with both sides off.
- Device tab: a slot with both sides off is marked OFF.

## 2.3.2

- Device tab: the Emulate | Read switch is now a small mode icon in the header. Tapping it opens a
  sheet that explains both modes and switches between them.
- "No Chameleon found" no longer offers demo mode (it stays in Settings › Developer).

## 2.3.1

- Library card list shows only the card type under the name (no UID). Search still finds cards
  by UID.
- Card page › Data: the HEX / ASCII switch stays visible while scrolling the dump.

## 2.3.0

- Scan tab rebuilt: HF | LF switch, Scan and Keep scanning buttons, a clear "hold a card" and
  "no card found" state, and the result with type, PRNG / backdoor / EV1 chips and copyable
  UID, SAK, ATQA and ATS. Card type override is in ⋮. MIFARE Classic and Ultralight keep their
  existing key / dump panels under the result.
- Save to library sheet with a prefilled name, folder and colour.
- Card form page replaces the Create card and Edit card dialogs.

## 2.2.0

- Dictionary page: numbered, searchable key list (tap a key to copy it), editor that reports
  skipped lines, merge other dictionaries in, rename, move, export, delete.
- Card page: NDEF tab when the card holds an NDEF message; edit it from there.
- Library: long-press cards to select several, then move or delete them together.
- Settings rebuilt as a grouped list (Appearance, Connection, Library, Backup, About, Developer)
  with an About page. The old sidebar setting is gone.
- Tools tab: plain list with frequency tags; tools open almost full screen; the unfinished
  Gen4 tool is hidden; dictionary download lives in Library › Keys.

## 2.1.0

- Device tab without a Chameleon: explains how to connect, lists found devices with a Connect
  button, offers demo mode; Bluetooth connecting shows inline.
- Connected Device tab: status header (model, connection, battery, firmware), Emulate | Read switch,
  firmware update banner, and the 8 slots as a list with the active one highlighted.
- Slot page: HF and LF sides with on/off switch, Load from library, Edit, View data, Clear and
  Save to library.
- Card page: Load to slot.
- Device settings as a full page grouped into Firmware, Buttons, LEDs, Bluetooth, Power and
  Danger zone.

## 2.0.0

- Android app id is now `io.nuc134r.chameleon`, so the fork installs next to the upstream app.
- Signed APKs are published to GitHub releases.
- New navigation: bottom bar with Device, Scan, Library and Tools; Settings moved behind the gear.
- Library replaces Saved Cards: Cards and Keys tabs, search, HF/LF filter, folder breadcrumbs,
  one ⋮ menu per row, Undo after deleting.
- Card page replaces the card dialog: Info, Data (hex/ASCII dump) and Keys tabs; Write to tag button.
- Dark theme by default with a PCB gold accent.
