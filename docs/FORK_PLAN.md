# Redesign plan (fork)

Working list for the phone-first redesign. Based on the UX audit:
https://claude.ai/artifact/B3GwzD9b8QZXHQ1zKDYvH4 — tick items as they land on `better-ui`.

## 1. Foundations — released in 2.0.0
- [x] Release workflow: signed APKs on GitHub releases (`fork-release.yml`)
- [x] Android app id `io.nuc134r.chameleon`
- [x] Bottom bar shell: Device, Scan, Library, Tools; rail on wide screens; Settings gear
- [x] Dark theme by default, PCB gold accent, mono for data
- [x] Library: Cards | Keys tabs, search, HF/LF filter, breadcrumbs, ⋮ menus, Undo on delete
- [x] Card page: Info | Data | Keys tabs, Write to tag
- [x] Scan tab: "No device" empty state

## 2. Device tab
- [x] Offline state: "No device" empty state with found devices as rows (model, USB/BLE, port, DFU),
      Connect per row, live scanning indicator, Refresh, manual port connect in ⋮, demo-mode hint
- [x] BLE "connecting" state inline (no separate page)
- [x] Connected header: model, connection, battery, firmware version, Emulate | Read switch,
      ⋮ with Disconnect, Device settings, Check for firmware update
- [x] Slots as a list of 8 rows (HF/LF card names, active slot highlighted); tap opens Slot page,
      ⋮ / long-press sets it active
- [x] Slot page: HF and LF sections (enable switch, card summary, Load from library, Edit, Clear),
      View data, Save to library
- [ ] Slot page: emulation options inline (today they are in upstream's Edit dialog, with Mfkey32)
- [x] Card page: Load to slot button
- [x] Device settings as a grouped page (Firmware, Buttons, Display, Bluetooth, Power, Danger zone)

## 3. Scan tab
- [ ] HF | LF switch with one Scan button; Continuous as a toggle
- [ ] Result card: type headline, mono UID/SAK/ATQA/ATS with copy, PRNG/backdoor chips
- [ ] MIFARE Classic steps: Keys → Recover → Dump, one bottom primary button per state
- [ ] Save to library sheet (name prefilled, folder, colour)

## 4. Library follow-ups
- [x] Dictionary page (view + edit merged; search, line numbers, merge into…)
- [ ] Card form page replacing the Create / Edit card dialogs
- [x] NDEF tab on the Card page
- [x] Long-press multi-select for cards (move, delete)

## 5. Tools, Settings, Debug
- [x] Tools tab as a plain list (frequency tags, device-required hint); Gen4 WIP hidden;
      dictionary download moved to Library › Keys
- [ ] Tools as real pages (today upstream's tool dialogs open almost full screen)
- [x] Settings as a grouped list (Appearance, Connection, Library, Backup, About, Developer); About page
- [ ] Debug tools page grouped, short warning banner
