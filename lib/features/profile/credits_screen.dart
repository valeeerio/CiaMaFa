import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/theme.dart';
import '../../shared/screen_header.dart';

part 'credits_screen.g.dart';

/// "1.0.0 (1)": versione e build dell'app.
@riverpod
Future<String> appVersion(Ref ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

/// Crediti: attribuzioni obbligatorie della mappa e della ricerca, licenze
/// open source e versione.
class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final version = ref.watch(appVersionProvider).value;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            ScreenHeader(
              title: 'Crediti',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            const SizedBox(height: 24),
            Text('Mappa', style: text.titleSmall),
            const SizedBox(height: 4),
            Text(
              '© OpenStreetMap contributors · © CARTO',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Ricerca luoghi', style: text.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Photon by Komoot · dati © OpenStreetMap contributors',
              style: text.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextButton(
              key: const ValueKey('open-licenses'),
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'CiaMaFa',
                applicationVersion: version,
              ),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                foregroundColor: AppColors.nightBlue,
              ),
              child: const Text('Licenze open source'),
            ),
            if (version != null) ...[
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'CiaMaFa $version',
                  key: const ValueKey('app-version'),
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
