import 'package:chameleonultragui/connector/serial_abstract.dart';
import 'package:chameleonultragui/fork/device/slot_page.dart';
import 'package:chameleonultragui/fork/shell.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/menu/dialogs/chameleon_settings.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/flash.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/github.dart';
import 'package:chameleonultragui/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SlotInfo {
  TagType hf;
  TagType lf;
  String hfName;
  String lfName;
  bool hfEnabled;
  bool lfEnabled;

  SlotInfo(
    this.hf,
    this.lf,
    this.hfName,
    this.lfName,
    this.hfEnabled,
    this.lfEnabled,
  );

  bool get used => hf != TagType.unknown || lf != TagType.unknown;
}

class _DeviceStatus {
  final BatteryCharge? battery;
  final FirmwareVersion firmware;
  final String commit;
  final bool capabilitiesOk;
  final bool readerMode;
  final int activeSlot;
  final List<SlotInfo> slots;

  _DeviceStatus(
    this.battery,
    this.firmware,
    this.commit,
    this.capabilitiesOk,
    this.readerMode,
    this.activeSlot,
    this.slots,
  );
}

// Device tab while connected: status header, Emulate | Read switch and the 8 slots.
class DeviceView extends StatefulWidget {
  const DeviceView({super.key});

  @override
  State<DeviceView> createState() => _DeviceViewState();
}

class _DeviceViewState extends State<DeviceView> {
  late Future<_DeviceStatus> status = _load();

  Future<_DeviceStatus> _load() async {
    final appState = context.read<ChameleonGUIState>();
    final c = appState.communicator!;

    BatteryCharge? battery;
    try {
      battery = await c.getBatteryCharge();
    } catch (_) {}
    final firmware = await c.getFirmwareVersion();
    var commit = '';
    try {
      commit = await c.getGitCommitHash();
    } catch (_) {}

    var capabilitiesOk = true;
    try {
      final caps = await c.getDeviceCapabilities();
      final needed = appState.connector!.device == ChameleonDevice.lite
          ? ChameleonCommand.setIdteckEmulatorID.value
          : ChameleonCommand.mf0UlcAuth.value;
      capabilitiesOk = caps.contains(needed);
    } catch (_) {
      capabilitiesOk = false;
    }

    final readerMode = await c.isReaderDeviceMode();
    var active = 0;
    try {
      active = await c.getActiveSlot();
    } catch (_) {}

    final types = await c.getSlotTagTypes();
    final enabled = await c.getEnabledSlots();
    final names = await c.getSlotTagNames();
    final slots = [
      for (var i = 0; i < 8; i++)
        SlotInfo(
          types[i].hf,
          types[i].lf,
          names[i].hf.trim(),
          names[i].lf.trim(),
          enabled[i].hf,
          enabled[i].lf,
        ),
    ];
    return _DeviceStatus(
      battery,
      firmware,
      commit,
      capabilitiesOk,
      readerMode,
      active,
      slots,
    );
  }

  void reload() => setState(() => status = _load());

  Future<void> _setReaderMode(bool reader) async {
    await context.read<ChameleonGUIState>().communicator!.setReaderDeviceMode(
      reader,
    );
    reload();
  }

  Future<void> _setActive(int slot) async {
    await context.read<ChameleonGUIState>().communicator!.activateSlot(slot);
    reload();
  }

  Future<void> _checkForUpdate(String currentCommit) async {
    final appState = context.read<ChameleonGUIState>();
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final model = chameleonDeviceName(appState.connector!.device);
    try {
      final latest = await latestAvailableCommit(appState.connector!.device);
      var current = currentCommit;
      try {
        current = await resolveCommit(currentCommit);
      } catch (_) {}
      if (latest.isEmpty) return;
      if (current.isNotEmpty && latest.startsWith(current)) {
        messenger.showSnackBar(
          SnackBar(content: Text(localizations.up_to_date(model))),
        );
        return;
      }
      await _flashLatest();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${localizations.update_error}: $e')),
      );
    }
  }

  Future<void> _flashLatest() async {
    final appState = context.read<ChameleonGUIState>();
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          localizations.downloading_fw(
            chameleonDeviceName(appState.connector!.device),
          ),
        ),
      ),
    );
    try {
      await flashFirmware(appState, scaffoldMessenger: messenger);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${localizations.update_error}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;

    return FutureBuilder<_DeviceStatus>(
      future: status,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.device),
            actions: [
              MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.tune),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const ChameleonSettings(),
                    ),
                    child: Text(localizations.device_settings),
                  ),
                  if (appState.connector!.portName != 'Demo')
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.system_update),
                      onPressed: data == null
                          ? null
                          : () => _checkForUpdate(data.commit),
                      child: Text(localizations.check_updates),
                    ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.link_off),
                    onPressed: () => appState.disconnect(manual: true),
                    child: Text(strings.disconnect),
                  ),
                ],
                builder: (context, controller, _) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                ),
              ),
              const SettingsButton(),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox(height: 2),
            ),
          ),
          body: snapshot.hasError
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: strings.connectionFailed,
                  hint: snapshot.error.toString(),
                  action: FilledButton.icon(
                    onPressed: reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.retry),
                  ),
                )
              : data == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: () async {
                    reload();
                    await status;
                  },
                  child: _content(context, appState, data),
                ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    ChameleonGUIState appState,
    _DeviceStatus data,
  ) {
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final connector = appState.connector!;
    final demo = connector.portName == 'Demo';
    final used = data.slots.where((s) => s.used).length;
    final ble = connector.connectionType == ConnectionType.ble;

    final details = [
      connector.portName,
      ble ? 'BLE' : 'USB',
      if (data.battery != null) '${data.battery!.percent}%',
      'fw ${numToVerCode(data.firmware.version)}'
          '${data.commit.isEmpty ? '' : ' (${data.commit})'}',
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  ble ? Icons.bluetooth : Icons.usb,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chameleon ${chameleonDeviceName(connector.device)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: monoStyle(
                        context,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (demo)
          _Banner(icon: Icons.science_outlined, text: strings.demoDevice)
        else if (data.firmware.legacyProtocol || !data.capabilitiesOk)
          _Banner(
            icon: Icons.system_update,
            text: data.firmware.legacyProtocol
                ? strings.outdatedProtocol
                : localizations.please_update_firmware,
            action: TextButton(
              onPressed: _flashLatest,
              child: Text(localizations.update),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
            ),
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.contactless_outlined),
                label: Text(strings.modeEmulate),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.barcode_reader),
                label: Text(strings.modeRead),
              ),
            ],
            selected: {data.readerMode},
            onSelectionChanged: (value) => _setReaderMode(value.first),
          ),
        ),
        SectionLabel(strings.slotsUsed(used)),
        for (var i = 0; i < 8; i++)
          _SlotRow(
            index: i,
            slot: data.slots[i],
            active: i == data.activeSlot,
            onOpen: () async {
              await pushDeviceRoute(context, 'slot', SlotPage(slot: i));
              if (mounted) reload();
            },
            onSetActive: () => _setActive(i),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Banner({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final int index;
  final SlotInfo slot;
  final bool active;
  final VoidCallback onOpen;
  final VoidCallback onSetActive;

  const _SlotRow({
    required this.index,
    required this.slot,
    required this.active,
    required this.onOpen,
    required this.onSetActive,
  });

  @override
  Widget build(BuildContext context) {
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    String side(TagType type, String name, bool enabled) {
      if (type == TagType.unknown) return strings.slotEmpty;
      final label = name.isEmpty ? localizations.no_name : name;
      final off = enabled ? '' : ' · ${strings.slotDisabled}';
      return '$label · ${chameleonTagToString(type, localizations)}$off';
    }

    Widget line(String freq, TagType type, String name, bool enabled) {
      final empty = type == TagType.unknown;
      return Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              freq,
              style: monoStyle(
                context,
                size: 10.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              side(type, name, enabled),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: empty || !enabled
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onOpen,
      onLongPress: active ? null : onSetActive,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 3,
              color: active ? scheme.primary : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? scheme.primary
                    : slot.used
                    ? scheme.surfaceContainerHigh
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active ? scheme.primary : scheme.outlineVariant,
                ),
              ),
              child: Text(
                '${index + 1}',
                style: monoStyle(
                  context,
                  size: 15,
                  color: active ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  line('HF', slot.hf, slot.hfName, slot.hfEnabled),
                  const SizedBox(height: 2),
                  line('LF', slot.lf, slot.lfName, slot.lfEnabled),
                ],
              ),
            ),
            if (active)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  strings.active.toUpperCase(),
                  style: monoStyle(
                    context,
                    size: 10.5,
                    color: scheme.primary,
                  ).copyWith(letterSpacing: 1),
                ),
              ),
            MenuAnchor(
              menuChildren: [
                if (!active)
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.radio_button_checked),
                    onPressed: onSetActive,
                    child: Text(strings.setActive),
                  ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.chevron_right),
                  onPressed: onOpen,
                  child: Text(strings.editSlot),
                ),
              ],
              builder: (context, controller, _) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
