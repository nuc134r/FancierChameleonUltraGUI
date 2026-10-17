# Redesign plan (fork)

Working list for the phone-first redesign. `[x]` done, `[—]` decided against (reason given). Based on the UX audit:
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
- [—] Slot page: emulation options inline — kept in upstream's Edit dialog. It also holds nonce
      collection / Mfkey32 and NTAG password detection; splitting the options across two places
      would bring back the "two ways in" problem, and the fork does not reimplement key-recovery tooling.
- [x] Card page: Load to slot button
- [x] Device settings as a grouped page (Firmware, Buttons, Display, Bluetooth, Power, Danger zone)

## 3. Scan tab
- [x] HF | LF switch with one Scan button; Keep scanning as a toggle
- [x] Result card: type headline, mono UID/SAK/ATQA/ATS with copy, PRNG/backdoor chips; card type override in ⋮
- [x] MIFARE Classic / Ultralight steps: upstream's own panels shown under the result (kept as-is;
      the fork does not reimplement key recovery)
- [x] Save to library sheet (name prefilled, folder, colour) for UID-only and LF saves

## 4. Library follow-ups
- [x] Dictionary page (view + edit merged; search, line numbers, merge into…)
- [x] Card form page replacing the Create / Edit card dialogs
- [x] NDEF tab on the Card page
- [x] Long-press multi-select for cards (move, delete)

## 5. Tools, Settings, Debug
- [x] Tools tab as a plain list (frequency tags, device-required hint); Gen4 WIP hidden;
      dictionary download moved to Library › Keys
- [—] Tools as real pages — kept as upstream's dialogs opened almost full screen. Their content is
      private to each upstream file, so converting them means forking ~3,000 lines of sniffing code.
- [x] Settings as a grouped list (Appearance, Connection, Library, Backup, About, Developer); About page
- [—] Debug tools page — kept as upstream's page (reached via Settings › Developer). It is a
      developer page built around recovery-library tests the fork does not reimplement.
