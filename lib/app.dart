import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/medicines/presentation/medicine_providers.dart';
import 'features/notifications/notification_service.dart';

class PharmaCareApp extends ConsumerWidget {
  const PharmaCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const _AuthGate(),
    );
  }
}

/// Routes between the login screen and the main shell based on auth state, and
/// kicks off an inventory scan for notifications once signed in.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    // When the user becomes authenticated, scan inventory for alerts.
    ref.listen(authControllerProvider, (prev, next) {
      if (next.isAuthenticated && (prev?.isAuthenticated != true)) {
        _scanForAlerts();
      }
    });

    if (auth.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.isAuthenticated ? const AppShell() : const LoginScreen();
  }

  Future<void> _scanForAlerts() async {
    // Ensure the inventory is loaded, then notify.
    final medicines = await ref.read(medicinesProvider.future);
    await NotificationService.instance.scanInventory(medicines);
  }
}
