import 'package:chameleonultragui/fork/device/connect_view.dart';
import 'package:chameleonultragui/fork/device/device_view.dart';
import 'package:chameleonultragui/fork/library/library_page.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/gui/page/debug.dart';
import 'package:chameleonultragui/gui/page/flashing.dart';
import 'package:chameleonultragui/fork/scan/scan_page.dart';
import 'package:chameleonultragui/fork/settings/settings_page.dart';
import 'package:chameleonultragui/fork/tools/tools_page.dart';
import 'package:chameleonultragui/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Root navigator of the app, so the shell can drop device-only routes when the Chameleon
// disconnects.
final forkNavigatorKey = GlobalKey<NavigatorState>();

// Routes named with this prefix need a connected device and are closed on disconnect.
const deviceRoutePrefix = 'device:';

Future<T?> pushDeviceRoute<T>(BuildContext context, String name, Widget page) {
  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      settings: RouteSettings(name: '$deviceRoutePrefix$name'),
      builder: (_) => page,
    ),
  );
}

enum _Tab { device, scan, library, tools }

// Phone: bottom navigation bar. Wide screens (>= 840 dp): the same four items as a rail.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  _Tab tab = _Tab.device;
  bool wasConnected = false;

  void _onConnectionChange(bool connected) {
    if (wasConnected && !connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        forkNavigatorKey.currentState?.popUntil(
          (route) =>
              !(route.settings.name?.startsWith(deviceRoutePrefix) ?? false),
        );
      });
    }
    wasConnected = connected;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final connector = appState.connector!;
    final strings = ForkStrings.of(context);
    _onConnectionChange(connector.connected);

    if (connector.connected && connector.isDFU) {
      return const Scaffold(
        body: SafeArea(child: FlashingPage()),
        bottomNavigationBar: BottomProgressBar(),
      );
    }

    final destinations = [
      (_Tab.device, Icons.memory_outlined, Icons.memory, strings.device),
      (_Tab.scan, Icons.sensors_outlined, Icons.sensors, strings.scan),
      (
        _Tab.library,
        Icons.collections_bookmark_outlined,
        Icons.collections_bookmark,
        strings.library,
      ),
      (_Tab.tools, Icons.handyman_outlined, Icons.handyman, strings.tools),
    ];

    final body = KeyedSubtree(
      key: ValueKey(tab),
      child: _buildTab(context, appState, strings),
    );
    final wide = MediaQuery.sizeOf(context).width >= 840;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                labelType: NavigationRailLabelType.all,
                selectedIndex: tab.index,
                onDestinationSelected: (i) =>
                    setState(() => tab = _Tab.values[i]),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.$2),
                      selectedIcon: Icon(d.$3),
                      label: Text(d.$4),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) => setState(() => tab = _Tab.values[i]),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.$2),
              selectedIcon: Icon(d.$3),
              label: d.$4,
            ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    ChameleonGUIState appState,
    ForkStrings strings,
  ) {
    final connector = appState.connector!;
    switch (tab) {
      case _Tab.device:
        if (!connector.connected) {
          return const DeviceOfflineView();
        }
        return const DeviceView();
      case _Tab.scan:
        if (!connector.connected) {
          return Scaffold(
            appBar: AppBar(
              title: Text(strings.scan),
              actions: const [SettingsButton()],
            ),
            body: EmptyState(
              icon: Icons.sensors_off_outlined,
              title: strings.noDevice,
              hint: strings.noDeviceScan,
              action: FilledButton.icon(
                onPressed: () => setState(() => tab = _Tab.device),
                icon: const Icon(Icons.usb),
                label: Text(strings.goToDevice),
              ),
            ),
          );
        }
        return const ScanPage();
      case _Tab.library:
        return const LibraryPage();
      case _Tab.tools:
        return const ToolsPage();
    }
  }
}

// Gear in the top bar: Settings, plus Debug tools when debug mode is on.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final strings = ForkStrings.of(context);

    void openSettings() =>
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SettingsPage()));

    if (!appState.devMode) {
      return IconButton(
        tooltip: strings.settings,
        icon: const Icon(Icons.settings_outlined),
        onPressed: openSettings,
      );
    }
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.settings_outlined),
          onPressed: openSettings,
          child: Text(strings.settings),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.bug_report_outlined),
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const DebugPage())),
          child: Text(strings.debugTools),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: strings.settings,
        icon: const Icon(Icons.settings_outlined),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
