import 'package:chameleonultragui/connector/serial_abstract.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/component/long_press_threshold_input.dart';
import 'package:chameleonultragui/helpers/definitions.dart';
import 'package:chameleonultragui/helpers/flash.dart';
import 'package:chameleonultragui/helpers/general.dart';
import 'package:chameleonultragui/helpers/validators.dart';
import 'package:chameleonultragui/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Device settings as a grouped list (replaces upstream's ChameleonSettings dialog in the fork).
// Each row shows its current value; tapping opens a picker or a small input dialog.
class DeviceSettingsPage extends StatefulWidget {
  const DeviceSettingsPage({super.key});

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  late final Future<DeviceSettings> future = _load();
  DeviceSettings? settings;

  Future<DeviceSettings> _load() async {
    final c = context.read<ChameleonGUIState>().communicator!;
    final s = await c.getDeviceSettings();
    // Older firmware has no long-press threshold; leave it null so the row is hidden.
    try {
      final caps = await c.getDeviceCapabilities();
      if (caps.contains(ChameleonCommand.getLongPressThreshold.value)) {
        s.longPressThreshold = await c.getLongPressThreshold();
      }
    } catch (_) {}
    settings = s;
    return s;
  }

  ChameleonGUIState get appState => context.read<ChameleonGUIState>();

  Future<void> _apply(Future<void> Function() command) async {
    final localizations = AppLocalizations.of(context)!;
    try {
      await command();
      await appState.communicator!.saveSettings();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${localizations.error}: $e')));
      }
    }
  }

  Future<T?> _choose<T>(String title, List<(T, String)> options, T current) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            RadioGroup<T>(
              groupValue: current,
              onChanged: (value) => Navigator.pop(context, value),
              child: Column(
                children: [
                  for (final (value, label) in options)
                    RadioListTile<T>(value: value, title: Text(label)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _askText(
    String title,
    String initial, {
    required String? Function(String?) validator,
    String? suffix,
    int? maxLength,
  }) {
    final controller = TextEditingController(text: initial);
    final formKey = GlobalKey<FormState>();
    final localizations = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: maxLength,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: monoStyle(context, size: 16),
            validator: validator,
            decoration: InputDecoration(suffixText: suffix),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text(localizations.save),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations.yes),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.device_settings)),
      body: FutureBuilder<DeviceSettings>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: localizations.error,
              hint: snapshot.error.toString(),
            );
          }
          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _list(context, settings!);
        },
      ),
    );
  }

  Widget _list(BuildContext context, DeviceSettings s) {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final c = appState.communicator!;
    final model = chameleonDeviceName(appState.connector!.device);
    final demo = appState.connector!.portName == 'Demo';

    final buttonOptions = [
      (ButtonConfig.disable, localizations.disable),
      (ButtonConfig.cycleForward, localizations.forward),
      (ButtonConfig.cycleBackward, localizations.backward),
      (ButtonConfig.cloneUID, localizations.clone_uid),
      (ButtonConfig.chargeStatus, localizations.charge),
    ];
    String buttonLabel(ButtonConfig value) =>
        buttonOptions.firstWhere((o) => o.$1 == value).$2;

    final animationOptions = [
      (AnimationSetting.full, localizations.full),
      (AnimationSetting.minimal, localizations.mini),
      (AnimationSetting.none, localizations.none),
      (AnimationSetting.symmetric, localizations.symmetric),
    ];

    Widget value(String text) => Text(
      text,
      style: monoStyle(context, size: 12.5, color: scheme.onSurfaceVariant),
    );

    Widget buttonRow(
      String title,
      ButtonType button,
      bool long,
      ButtonConfig current,
      void Function(ButtonConfig) store,
    ) {
      return ListTile(
        title: Text(title),
        trailing: value(buttonLabel(current)),
        onTap: () async {
          final picked = await _choose(title, buttonOptions, current);
          if (picked == null || picked == current) return;
          await _apply(() async {
            if (long) {
              await c.setLongButtonConfig(button, picked);
            } else {
              await c.setButtonConfig(button, picked);
            }
            store(picked);
          });
        },
      );
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (!demo) ...[
          SectionLabel(strings.groupFirmware),
          ListTile(
            leading: const Icon(Icons.system_update),
            title: Text(localizations.flash_via_dfu),
            subtitle: Text(strings.flashLatestHint),
            onTap: () async {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text(localizations.downloading_fw(model))),
              );
              try {
                await flashFirmware(appState, scaffoldMessenger: messenger);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('${localizations.update_error}: $e')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: Text(localizations.flash_zip_dfu),
            subtitle: Text(strings.flashZipHint),
            onTap: () async {
              navigator.pop();
              try {
                await flashFirmwareZip(appState, scaffoldMessenger: messenger);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('${localizations.update_error}: $e')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services_outlined),
            title: Text(localizations.enter_dfu),
            subtitle: Text(strings.enterDfuHint),
            onTap: () async {
              final state = appState;
              await state.communicator!.enterDFUMode();
              await state.connector!.performDisconnect();
              state.changesMade();
            },
          ),
        ],
        SectionLabel(strings.groupButtons),
        buttonRow(
          '${localizations.button_x("A")} · ${strings.press}',
          ButtonType.a,
          false,
          s.aPress,
          (v) => s.aPress = v,
        ),
        buttonRow(
          '${localizations.button_x("B")} · ${strings.press}',
          ButtonType.b,
          false,
          s.bPress,
          (v) => s.bPress = v,
        ),
        buttonRow(
          '${localizations.button_x("A")} · ${strings.longPressSuffix}',
          ButtonType.a,
          true,
          s.aLongPress,
          (v) => s.aLongPress = v,
        ),
        buttonRow(
          '${localizations.button_x("B")} · ${strings.longPressSuffix}',
          ButtonType.b,
          true,
          s.bLongPress,
          (v) => s.bLongPress = v,
        ),
        if (s.longPressThreshold != null)
          ListTile(
            title: Text(
              localizations.long_press_threshold.replaceAll(
                RegExp(r'\s*\(.*\)?:?$'),
                '',
              ),
            ),
            trailing: value('${s.longPressThreshold} ${strings.ms}'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                content: LongPressThresholdInput(
                  initialValue: s.longPressThreshold!,
                  onSave: (threshold) async {
                    await _apply(() async {
                      await c.setLongPressThreshold(threshold);
                      s.longPressThreshold = threshold;
                    });
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
              ),
            ),
          ),
        SectionLabel(strings.groupLed),
        ListTile(
          title: Text(localizations.animations),
          trailing: value(
            animationOptions.firstWhere((o) => o.$1 == s.animation).$2,
          ),
          onTap: () async {
            final picked = await _choose(
              localizations.animations,
              animationOptions,
              s.animation,
            );
            if (picked == null || picked == s.animation) return;
            await _apply(() async {
              await c.setAnimationMode(picked);
              s.animation = picked;
            });
          },
        ),
        SectionLabel(strings.groupBluetooth),
        SwitchListTile(
          title: Text(strings.pairingRequired),
          subtitle: Text(strings.pairingHint),
          value: s.pairingEnabled,
          onChanged: (v) => _apply(() async {
            await c.setBLEPairEnabled(v);
            s.pairingEnabled = v;
          }),
        ),
        if (s.pairingEnabled) ...[
          ListTile(
            title: Text(localizations.ble_pin),
            trailing: value(s.key.isEmpty ? '—' : s.key),
            onTap: () async {
              final pin = await _askText(
                localizations.ble_pin,
                s.key,
                maxLength: 6,
                validator: (v) => validateBlePin(v, localizations),
              );
              if (pin == null) return;
              await _apply(() async {
                await c.setBLEConnectKey(pin);
                s.key = pin;
              });
            },
          ),
          ListTile(
            title: Text(localizations.clear_ble_bonds),
            onTap: () async {
              if (!await _confirm(
                localizations.clear_ble_bonds,
                localizations.clear_ble_bonds_confirmation,
              )) {
                return;
              }
              final state = appState;
              await state.communicator!.clearBLEBoundedDevices();
              if (state.connector!.connectionType == ConnectionType.ble) {
                await state.connector!.performDisconnect();
                state.changesMade();
              }
            },
          ),
        ],
        if (s.wakeTimeSeconds != null) ...[
          SectionLabel(strings.groupPower),
          ListTile(
            title: Text(localizations.wake_time),
            subtitle: Text(
              localizations.wake_time_after_button_press.replaceAll(
                RegExp(r'\s*\(.*\)?:?$'),
                '',
              ),
            ),
            trailing: value('${s.wakeTimeSeconds} ${strings.seconds}'),
            onTap: () async {
              final text = await _askText(
                localizations.wake_time,
                '${s.wakeTimeSeconds}',
                suffix: strings.seconds,
                validator: (v) =>
                    validateIntRange(v, localizations, min: 5, max: 60),
              );
              if (text == null) return;
              await _apply(() async {
                await c.setSleepTimeout(int.parse(text));
                s.wakeTimeSeconds = int.parse(text);
              });
            },
          ),
        ],
        SectionLabel(strings.dangerZone),
        ListTile(
          leading: Icon(Icons.settings_backup_restore, color: scheme.error),
          title: Text(
            localizations.reset_settings,
            style: TextStyle(color: scheme.error),
          ),
          subtitle: Text(strings.resetSettingsHint),
          onTap: () async {
            if (!await _confirm(
              localizations.reset_settings,
              strings.resetSettingsHint,
            )) {
              return;
            }
            await c.resetSettings();
            if (mounted) navigator.pop();
            _snack(localizations.reset_settings);
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
          title: Text(
            localizations.factory_reset,
            style: TextStyle(color: scheme.error),
          ),
          subtitle: Text(strings.factoryResetHint),
          onTap: () async {
            if (!await _confirm(
              localizations.factory_reset,
              localizations.factory_reset_confirmation,
            )) {
              return;
            }
            final state = appState;
            await state.communicator!.factoryReset();
            await state.connector!.performDisconnect();
            state.changesMade();
          },
        ),
      ],
    );
  }
}
