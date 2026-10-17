import 'package:chameleonultragui/fork/shell.dart';
import 'package:chameleonultragui/fork/strings.dart';
import 'package:chameleonultragui/fork/theme.dart';
import 'package:chameleonultragui/generated/i18n/app_localizations.dart';
import 'package:chameleonultragui/gui/menu/tools/hf_sniffing.dart';
import 'package:chameleonultragui/gui/menu/tools/lf_sniffing.dart';
import 'package:chameleonultragui/gui/menu/tools/t55xx_password_cleaner.dart';
import 'package:chameleonultragui/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Tools tab: plain rows with a frequency tag. The tools themselves are upstream's dialogs,
// opened almost full screen. Dictionary download lives in Library › Keys; the unfinished
// Gen4 tool is hidden.
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ChameleonGUIState>();
    final localizations = AppLocalizations.of(context)!;
    final strings = ForkStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final connected = appState.connector?.connected ?? false;

    final tools = [
      (
        Icons.graphic_eq,
        localizations.lf_sniffing,
        localizations.lf_sniffing_description,
        'LF',
        false,
        () => const LfSniffingMenu(),
      ),
      (
        Icons.radar,
        localizations.hf_sniffing,
        localizations.hf_sniffing_description,
        'HF',
        false,
        () => const HfSniffingMenu(),
      ),
      (
        Icons.password,
        localizations.t55xx_password_cleaner,
        localizations.t55xx_password_cleaner_description,
        'LF',
        true,
        () => const T55XXPasswordCleanerMenu(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tools),
        actions: const [SettingsButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          for (final (icon, name, description, freq, needsDevice, build)
              in tools)
            ListTile(
              enabled: !needsDevice || connected,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              title: Row(
                children: [
                  Flexible(child: Text(name)),
                  const SizedBox(width: 8),
                  Text(
                    freq,
                    style: monoStyle(
                      context,
                      size: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                needsDevice && !connected
                    ? '$description\n${strings.connectFirst}'
                    : description,
              ),
              isThreeLine: needsDevice && !connected,
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => Theme(
                  data: Theme.of(dialogContext).copyWith(
                    dialogTheme: Theme.of(dialogContext).dialogTheme.copyWith(
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 16,
                      ),
                    ),
                  ),
                  child: build(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
