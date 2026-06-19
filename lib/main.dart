import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/theme/theme_provider.dart';
import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm up the database (creates schema + seed data on first launch).
  await AppDatabase.instance.database;

  // Persisted preferences (theme, session).
  final prefs = await SharedPreferences.getInstance();

  // Initialise local notifications (no-op on unsupported platforms).
  await NotificationService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PharmaCareApp(),
    ),
  );
}
