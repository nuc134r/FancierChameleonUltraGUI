import 'dart:convert';
import 'dart:io';

import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/component/developer_list.dart';
import 'package:chameleonultragui/gui/component/qrcode_viewer.dart';
import 'package:chameleonultragui/gui/menu/dialogs/qr/import.dart';
import 'package:chameleonultragui/gui/menu/dialogs/qr/settings.dart';
import 'package:chameleonultragui/gui/menu/pages/changelog_view.dart';
import 'package:chameleonultragui/gui/page/debug.dart';
import 'package:chameleonultragui/gui/page/settings.dart' show loadLicense;
import 'package:chameleonultragui/helpers/colors.dart' as colors;
import 'package:chameleonultragui/helpers/github.dart';
import 'package:chameleonultragui/main.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const forkRepoUrl = 'https://github.com/nuc134r/FancierChameleonUltraGUI';
const upstreamRepoUrl = 'https://github.com/GameTec-live/ChameleonUltraGUI';

// App settings as a grouped list (replaces upstream's SettingsMainPage in the fork).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final prefs = appState.sharedPreferencesProvider;
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    Widget value(String text) => Text(
      text,
      style: monoStyle(context, size: 12.5, color: scheme.onSurfaceVariant),
    );

    final themes = [
      (ThemeMode.system, localizations.system),
      (ThemeMode.light, localizations.light),
      (ThemeMode.dark, localizations.dark),
    ];
    final accents = [
      strings.pcbGold,
      localizations.purple,
      localizations.blue,
      localizations.green,
      localizations.indigo,
      localizations.lime,
      localizations.red,
      localizations.yellow,
    ];
    final accentIndex = prefs.getThemeColorIndex().clamp(0, accents.length - 1);
    final locales = AppLocalizations.supportedLocales
        .map(
          (l) => (l.toLanguageTag(), lookupAppLocalizations(l).language_name),
        )
        .toList();
    final currentLocale = prefs.getLocaleString();

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionLabel(strings.groupAppearance),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(localizations.theme),
            trailing: value(
              themes.firstWhere((t) => t.$1 == prefs.getTheme()).$2,
            ),
            onTap: () async {
              final picked = await _choose(
                context,
                localizations.theme,
                themes,
                prefs.getTheme(),
              );
              if (picked == null) return;
              prefs.setTheme(picked);
              appState.changesMade();
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(strings.accent),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: accentIndex == 0
                        ? pcbGold
                        : colors.getThemeColor(accentIndex),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                value(accents[accentIndex]),
              ],
            ),
            onTap: () async {
              final picked = await _choose(context, strings.accent, [
                for (var i = 0; i < accents.length; i++) (i, accents[i]),
              ], accentIndex);
              if (picked == null) return;
              prefs.setThemeColor(picked);
              appState.changesMade();
            },
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(localizations.language),
            trailing: value(
              locales.where((l) => l.$1 == currentLocale).firstOrNull?.$2 ??
                  currentLocale,
            ),
            onTap: () async {
              final picked = await _choose(
                context,
                localizations.language,
                locales,
                currentLocale,
              );
              if (picked == null) return;
              prefs.setLocale(Locale(picked));
              appState.changesMade();
            },
          ),
          SectionLabel(strings.groupConnection),
          SwitchListTile(
            secondary: const Icon(Icons.radar),
            title: Text(localizations.auto_scan_devices),
            subtitle: Text(strings.autoScanHint),
            value: prefs.getAutoScanEnabled(),
            onChanged: (v) {
              prefs.setAutoScanEnabled(v);
              appState.changesMade();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.link),
            title: Text(localizations.auto_connect_first_device),
            subtitle: Text(strings.autoConnectHint),
            value: prefs.getAutoConnectFirstFoundDevice(),
            onChanged: (v) {
              prefs.setAutoConnectFirstFoundDevice(v);
              appState.changesMade();
            },
          ),
          SectionLabel(strings.library),
          SwitchListTile(
            secondary: const Icon(Icons.delete_outline),
            title: Text(localizations.confirm_deletions),
            subtitle: Text(strings.confirmDeleteHint),
            value: prefs.getConfirmDelete(),
            onChanged: (v) {
              prefs.setConfirmDelete(v);
              appState.changesMade();
            },
          ),
          SectionLabel(strings.groupBackup),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(localizations.export_settings),
            subtitle: Text(strings.exportHint),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(localizations.import_settings),
            subtitle: Text(strings.importHint),
            onTap: () => _import(context),
          ),
          SectionLabel(strings.groupAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(localizations.about),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const _AboutPage())),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(localizations.changelog),
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const ChangelogView(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(localizations.licenses),
            onTap: () => _showLicenses(context),
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(localizations.help_translate),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://crowdin.com/project/chameleonultragui'),
            ),
          ),
          SectionLabel(strings.groupDeveloper),
          SwitchListTile(
            secondary: const Icon(Icons.science_outlined),
            title: Text(localizations.emulate_device),
            subtitle: Text(strings.demoHint),
            value: prefs.isEmulatedChameleon(),
            onChanged: (v) async {
              await appState.disconnect();
              prefs.setEmulatedChameleon(v);
              appState.connector = null;
              appState.changesMade();
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.bug_report_outlined),
            title: Text(localizations.debug_mode),
            subtitle: Text(strings.debugHint),
            value: prefs.isDebugMode(),
            onChanged: (v) {
              prefs.setDebugMode(v);
              appState.changesMade();
            },
          ),
          if (prefs.isDebugMode())
            ListTile(
              leading: const Icon(Icons.terminal),
              title: Text(strings.debugTools),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const DebugPage())),
            ),
        ],
      ),
    );
  }

  static Future<T?> _choose<T>(
    BuildContext context,
    String title,
    List<(T, String)> options,
    T current,
  ) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
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
            Flexible(
              child: RadioGroup<T>(
                groupValue: current,
                onChanged: (v) => Navigator.pop(context, v),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final (v, label) in options)
                      RadioListTile<T>(value: v, title: Text(label)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Future<String?> _qrOrFile(BuildContext context, String title) {
    final localizations = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
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
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: Text(localizations.qr_code),
              onTap: () => Navigator.pop(context, 'qr'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(localizations.json_file),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final appState = context.read<ChameleonGUIState>();
    final how = await _qrOrFile(context, localizations.export_settings);
    if (how == null || !context.mounted) return;
    final json = appState.sharedPreferencesProvider.dumpSettingsToJson();
    if (how == 'file') {
      await FilePicker.saveFile(
        dialogTitle: '${localizations.output_file}:',
        fileName: 'ChameleonUltraGUISettings.json',
        bytes: const Utf8Encoder().convert(json),
      );
      return;
    }
    final Map<String, int> qr =
        await showDialog(
          context: context,
          builder: (_) => const QRCodeSettings(),
        ) ??
        {};
    if (qr.isEmpty || !context.mounted) return;
    final chunks = splitStringIntoQrChunks(json, qr['splitSize']!);
    chunks.insert(
      0,
      jsonEncode({
        'Info': 'Chameleon Ultra GUI Settings',
        'chunks': chunks.length,
        'sha256': sha256.convert(const Utf8Encoder().convert(json)).toString(),
      }),
    );
    await showDialog<void>(
      context: context,
      builder: (_) => QrCodeViewer(
        qrChunks: chunks,
        errorCorrection: qr['errorCorrection']!,
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final appState = context.read<ChameleonGUIState>();
    final how = await _qrOrFile(context, localizations.import_settings);
    if (how == null || !context.mounted) return;
    String? json;
    if (how == 'file') {
      final result = await FilePicker.pickFile();
      if (result == null) return;
      json = const Utf8Decoder().convert(
        await File(result.path!).readAsBytes(),
      );
    } else {
      if (!(Platform.isAndroid || Platform.isIOS)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.qr_code_import_not_supported_description,
            ),
          ),
        );
        return;
      }
      json = await showDialog<String>(
        context: context,
        builder: (_) => const QrCodeImport(),
      );
    }
    if (json == null) return;
    appState.sharedPreferencesProvider.restoreSettingsFromJson(json);
    appState.changesMade();
  }

  Future<void> _showLicenses(BuildContext context) async {
    final bsd = await loadLicense('BSD-3-Clause');
    final gpl = await loadLicense('GPL3');
    final lgpl = await loadLicense('LGPL3');
    final mit = await loadLicense('MIT');
    for (final (packages, text) in [
      (['chinese_font_library'], bsd),
      (['FlipperNestedRecovery'], lgpl),
      (['proxmark3'], gpl),
      (['minlzma'], mit),
    ]) {
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          LicenseEntryWithLineBreaks(packages, text),
        ),
      );
    }
    if (context.mounted) showLicensePage(context: context);
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.about)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chameleon Ultra GUI',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) => Text(
                    snapshot.hasData
                        ? '${localizations.version} ${snapshot.data!.version} '
                              '(build ${snapshot.data!.buildNumber})'
                        : ' ',
                    style: monoStyle(
                      context,
                      size: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(localizations.about_text),
                const SizedBox(height: 8),
                Text(strings.forkNote, style: muted),
              ],
            ),
          ),
          SectionLabel(strings.groupAbout),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(strings.sourceCode),
            subtitle: Text(forkRepoUrl, style: monoStyle(context, size: 12)),
            onTap: () => launchUrl(Uri.parse(forkRepoUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.fork_right),
            title: Text(strings.upstreamProject),
            subtitle: Text(
              upstreamRepoUrl,
              style: monoStyle(context, size: 12),
            ),
            onTap: () => launchUrl(Uri.parse(upstreamRepoUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(localizations.license),
            subtitle: const Text('GNU General Public License v3.0'),
          ),
          SectionLabel(localizations.developed_by),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DeveloperList(avatars: developers),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in [
                  localizations.trademarks_mifare,
                  localizations.trademarks_em,
                  localizations.trademarks_hid,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      t,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
