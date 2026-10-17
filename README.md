# Fancier Chameleon Ultra GUI

A phone-first redesign of [Chameleon Ultra GUI](https://github.com/GameTec-live/ChameleonUltraGUI):
the same app for the Chameleon Ultra / Lite, with a calmer, simpler interface. Dark by default,
PCB gold accent, monospace only where the data is.

<p>
  <img src="docs/fork-screenshots/01-device.webp" width="200" alt="Device tab with status header and the 8 slots">
  <img src="docs/fork-screenshots/06-library.webp" width="200" alt="Library with folders and cards">
  <img src="docs/fork-screenshots/08-card-data.webp" width="200" alt="Card page, Data tab with the hex dump">
  <img src="docs/fork-screenshots/05-scan-result.webp" width="200" alt="Scan tab with a read result">
</p>

## Download

Signed Android APKs are on the **[Releases](https://github.com/nuc134r/FancierChameleonUltraGUI/releases/latest)** page.
Take `chameleon-<version>-arm64-v8a.apk` for most phones, or the universal `chameleon-<version>.apk`.
The app installs next to the original one (`io.nuc134r.chameleon`).

## What's different

Four tabs at the bottom instead of a side rail, pages instead of stacked dialogs, one ⋮ menu instead
of rows of icons.

### Device

Status at a glance, an Emulate | Read switch and all 8 slots in one list. Tap a slot to load a card
from the library, edit it, view its data or switch a side off. Device settings are a normal grouped
page.

<p>
  <img src="docs/fork-screenshots/01-device.webp" width="200" alt="Device tab">
  <img src="docs/fork-screenshots/02-slot.webp" width="200" alt="Slot page with HF and LF sides">
  <img src="docs/fork-screenshots/03-device-settings.webp" width="200" alt="Device settings page">
</p>

### Library

Cards and key dictionaries in two tabs, one full-height list each, with search, an HF/LF filter,
folders and long-press multi-select. A card opens on its own page: identifiers, the dump (hex or
ASCII), the keys of every sector and NDEF records, with **Load to slot** and **Write to tag** at the
bottom.

<p>
  <img src="docs/fork-screenshots/06-library.webp" width="200" alt="Library, Cards tab">
  <img src="docs/fork-screenshots/07-card-info.webp" width="200" alt="Card page, Info tab">
  <img src="docs/fork-screenshots/09-card-keys.webp" width="200" alt="Card page, Keys tab">
  <img src="docs/fork-screenshots/10-card-ndef.webp" width="200" alt="Card page, NDEF tab">
</p>

<p>
  <img src="docs/fork-screenshots/11-keys.webp" width="200" alt="Library, Keys tab">
  <img src="docs/fork-screenshots/12-dictionary.webp" width="200" alt="Dictionary page with numbered keys">
</p>

### Scan

Pick HF or LF, press Scan. The result shows the card type and identifiers you can tap to copy, and
saves to the library in one step.

<p>
  <img src="docs/fork-screenshots/04-scan-idle.webp" width="200" alt="Scan tab waiting for a card">
  <img src="docs/fork-screenshots/05-scan-result.webp" width="200" alt="Scan result">
</p>

### Tools and Settings

<p>
  <img src="docs/fork-screenshots/13-tools.webp" width="200" alt="Tools list">
  <img src="docs/fork-screenshots/14-settings.webp" width="200" alt="Settings page">
</p>

### Empty screens

No blank pages: every empty state says what to do next.

<p>
  <img src="docs/fork-screenshots/20-empty-device.webp" width="200" alt="No Chameleon found">
  <img src="docs/fork-screenshots/21-empty-scan.webp" width="200" alt="Scan without a device">
  <img src="docs/fork-screenshots/22-empty-library.webp" width="200" alt="No cards yet">
  <img src="docs/fork-screenshots/23-empty-keys.webp" width="200" alt="No dictionaries yet">
</p>

## About this fork

Built on top of the original app, which keeps doing the heavy lifting: device protocol, card
reading, key recovery, sniffing and firmware updates. This fork only changes the interface and
follows upstream closely. Screenshots use the built-in demo device, so names and values are fake.

Bugs in the redesigned screens belong here; everything else is best reported
[upstream](https://github.com/GameTec-live/ChameleonUltraGUI/issues).

For installation on other platforms, the full feature list, documentation and credits, see the
**[original README](https://github.com/GameTec-live/ChameleonUltraGUI#readme)**.
