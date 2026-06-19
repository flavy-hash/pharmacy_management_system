import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../medicines/domain/medicine.dart';

/// Wraps `flutter_local_notifications` to surface expiry and low-stock alerts.
///
/// Notifications are only supported on Android & iOS; on other platforms every
/// method is a safe no-op so the app still runs for development/testing.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_supported || _initialised) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+ runtime permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialised = true;
  }

  static const _expiryChannel = AndroidNotificationDetails(
    'expiry_alerts',
    'Expiry Alerts',
    channelDescription: 'Warns when medicines are expiring or expired',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _stockChannel = AndroidNotificationDetails(
    'stock_alerts',
    'Stock Alerts',
    channelDescription: 'Warns when medicines run low',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Scans the inventory and posts summary notifications for medicines that are
  /// expired, expiring within [AppConstants.expiryWarningDays] days, or low on
  /// stock. Call this after the inventory loads (e.g. on login).
  Future<void> scanInventory(List<Medicine> medicines) async {
    if (!_supported) return;
    await init();

    final expired = medicines.where((m) => m.isExpired).toList();
    final expiringSoon = medicines.where((m) => m.isExpiringSoon).toList();
    final lowStock =
        medicines.where((m) => m.isLowStock || m.isOutOfStock).toList();

    if (expired.isNotEmpty) {
      await _show(
        id: 1001,
        title: '⚠️ ${expired.length} medicine(s) expired',
        body: expired.take(4).map((m) => m.name).join(', '),
        details: const NotificationDetails(android: _expiryChannel),
      );
    }

    if (expiringSoon.isNotEmpty) {
      await _show(
        id: 1002,
        title: '⏰ ${expiringSoon.length} medicine(s) expiring soon',
        body: expiringSoon
            .take(4)
            .map((m) => '${m.name} (${m.daysToExpiry}d)')
            .join(', '),
        details: const NotificationDetails(android: _expiryChannel),
      );
    }

    if (lowStock.isNotEmpty) {
      await _show(
        id: 1003,
        title: '📉 ${lowStock.length} item(s) low on stock',
        body: lowStock.take(4).map((m) => m.name).join(', '),
        details: const NotificationDetails(android: _stockChannel),
      );
    }
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    try {
      await _plugin.show(id, title, body, details);
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }
}
