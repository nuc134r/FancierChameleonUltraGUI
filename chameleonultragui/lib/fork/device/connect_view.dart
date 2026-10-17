import 'dart:async';

import 'package:chameleonultragui/bridge/chameleon.dart';
import 'package:chameleonultragui/connector/serial_abstract.dart';
import 'package:chameleonultragui/connector/serial_android.dart';
import 'package:chameleonultragui/fork/shell.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/menu/dialogs/manual_connect.dart';
import 'package:chameleonultragui/helpers/flash.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Device tab while no Chameleon is connected: found devices as rows, a clear empty state while
// searching, and the BLE "connecting" state inline. Scan / auto-connect behaviour follows
// upstream's ConnectPage (lib/gui/page/connect.dart).
class DeviceOfflineView extends StatefulWidget {
  const DeviceOfflineView({super.key});

  static const autoScanInterval = Duration(seconds: 3);

  @override
  State<DeviceOfflineView> createState() => _DeviceOfflineViewState();
}

class _DeviceOfflineViewState extends State<DeviceOfflineView> {
  List<Chameleon> devices = [];
  Timer? scanTimer;
  Object? error;
  bool initialScanCompleted = false;
  bool scanInProgress = false;
  dynamic connectingPort;
  bool showedPermissionsSnackbar = false;
  dynamic lastAutoConnectAttemptPort;

  ChameleonGUIState get appState => context.read<ChameleonGUIState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => scanNow());
  }

  @override
  void dispose() {
    scanTimer?.cancel();
    super.dispose();
  }

  bool shouldScan() =>
      mounted &&
      connectingPort == null &&
      !appState.connector!.connected &&
      !appState.connector!.pendingConnection;

  void scheduleNextScan() {
    scanTimer?.cancel();
    if (!shouldScan() ||
        !appState.sharedPreferencesProvider.getAutoScanEnabled()) {
      return;
    }
    scanTimer = Timer(DeviceOfflineView.autoScanInterval, scanNow);
  }

  void showPermissionsWarningIfNeeded(List<Chameleon> found) {
    final connector = appState.connector;
    if (connector is! AndroidSerial ||
        found.isNotEmpty ||
        connector.hasAllPermissions) {
      showedPermissionsSnackbar = false;
      return;
    }
    if (showedPermissionsSnackbar) return;
    showedPermissionsSnackbar = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.android_ble_permissions_missing,
          ),
        ),
      );
    });
  }

  Future<void> scanNow() async {
    if (scanInProgress || !shouldScan()) return;
    final state = appState;
    scanTimer?.cancel();
    setState(() {
      scanInProgress = true;
      error = null;
    });

    try {
      final seen = <String>{};
      final found = (await state.connector!.availableChameleons(false))
          .where((d) => seen.add('${d.port}|${d.type.name}|${d.dfu}'))
          .toList();
      if (!mounted) return;

      state.syncAutoReconnectSuppression(found.map((d) => d.port));
      final firstConnectable = found.where((d) => !d.dfu).firstOrNull?.port;
      if (firstConnectable != lastAutoConnectAttemptPort) {
        lastAutoConnectAttemptPort = null;
      }
      setState(() {
        devices = found;
        initialScanCompleted = true;
      });
      showPermissionsWarningIfNeeded(found);
      await maybeAutoConnect(found);
    } catch (e) {
      await state.connector!.performDisconnect();
      if (!mounted) return;
      setState(() {
        error = e;
        initialScanCompleted = true;
      });
    } finally {
      if (mounted) {
        setState(() => scanInProgress = false);
        scheduleNextScan();
      }
    }
  }

  Future<void> maybeAutoConnect(List<Chameleon> found) async {
    if (!shouldScan() ||
        !appState.sharedPreferencesProvider.getAutoConnectFirstFoundDevice()) {
      return;
    }
    final device = found
        .where((d) => !d.dfu && !appState.isAutoReconnectSuppressed(d.port))
        .firstOrNull;
    if (device == null) {
      lastAutoConnectAttemptPort = null;
      return;
    }
    if (lastAutoConnectAttemptPort == device.port) return;
    lastAutoConnectAttemptPort = device.port;
    await connect(device, fromAutoConnect: true);
  }

  Future<void> connect(Chameleon device, {bool fromAutoConnect = false}) async {
    if (connectingPort != null) return;
    if (device.dfu) {
      if (!fromAutoConnect) showDfuDialog(device);
      return;
    }
    final state = appState;
    scanTimer?.cancel();
    setState(() => connectingPort = device.port);

    try {
      if (device.type == ConnectionType.ble) {
        state.connector!.pendingConnection = true;
        state.changesMade();
      }
      final connected = await state.connector!.connectSpecificDevice(
        device.port,
      );
      state.connector!.pendingConnection = false;
      if (connected) {
        state.clearAutoReconnectSuppression(device.port);
        state.communicator = ChameleonCommunicator(
          state.log!,
          port: state.connector,
        );
      }
      state.changesMade();
    } catch (e) {
      state.connector!.pendingConnection = false;
      state.changesMade();
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => connectingPort = null);
      if (!state.connector!.connected) scheduleNextScan();
    }
  }

  void showDfuDialog(Chameleon device) {
    final state = appState;
    final localizations = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.chameleon_is_dfu),
        content: Text(localizations.firmware_is_corrupted),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    localizations.downloading_fw(
                      chameleonDeviceName(device.device),
                    ),
                  ),
                ),
              );
              await flashFirmware(
                state,
                scaffoldMessenger: messenger,
                device: device.device,
                enterDFU: false,
              );
              state.changesMade();
              if (mounted) scanNow();
            },
            child: Text(localizations.flash),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChameleonGUIState>();
    final strings = ForkStrings.of(context);
    final localizations = AppLocalizations.of(context)!;
    final manual = state.connector!.isManualConnectionSupported();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.device),
        actions: [
          IconButton(
            tooltip: strings.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: state.connector!.pendingConnection ? null : scanNow,
          ),
          if (manual)
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.cable),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ManualConnect(),
                  ),
                  child: Text(strings.connectByPort),
                ),
              ],
              builder: (context, controller, _) => IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          const SettingsButton(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: scanInProgress || state.connector!.pendingConnection
              ? const LinearProgressIndicator(minHeight: 2)
              : const SizedBox(height: 2),
        ),
      ),
      body: _body(context, state, strings, localizations),
    );
  }

  Widget _body(
    BuildContext context,
    ChameleonGUIState state,
    ForkStrings strings,
    AppLocalizations localizations,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (state.connector!.pendingConnection) {
      return EmptyState(
        icon: Icons.bluetooth_searching,
        title: localizations.connecting_to_ble,
        hint: [
          localizations.default_ble_password,
          localizations.connection_might_take_some_time,
          localizations.ble_need_to_remove_pair,
        ].join('\n\n'),
      );
    }

    if (error != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: strings.connectionFailed,
        hint: error.toString(),
        action: FilledButton.icon(
          onPressed: scanNow,
          icon: const Icon(Icons.refresh),
          label: Text(strings.retry),
        ),
      );
    }

    if (!initialScanCompleted) {
      return const SizedBox.shrink();
    }

    if (devices.isEmpty) {
      return EmptyState(
        icon: Icons.usb_off,
        title: strings.noDeviceFound,
        hint: strings.searchingHint,
      );
    }

    return ListView(
      children: [
        SectionLabel(strings.foundDevices),
        for (final device in devices)
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                device.type == ConnectionType.ble ? Icons.bluetooth : Icons.usb,
                color: scheme.primary,
              ),
            ),
            title: Text('Chameleon ${chameleonDeviceName(device.device)}'),
            subtitle: Text(
              [
                '${device.port ?? ''}',
                device.type == ConnectionType.ble ? 'BLE' : 'USB',
                if (device.dfu) 'DFU',
              ].where((s) => s.isNotEmpty).join(' · '),
              style: monoStyle(
                context,
                size: 12,
                color: device.dfu ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
            onTap: () => connect(device),
            trailing: connectingPort == device.port
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : device.dfu
                ? OutlinedButton(
                    onPressed: () => connect(device),
                    child: Text(localizations.flash),
                  )
                : FilledButton(
                    onPressed: connectingPort == null
                        ? () => connect(device)
                        : null,
                    child: Text(localizations.connect),
                  ),
          ),
      ],
    );
  }
}
