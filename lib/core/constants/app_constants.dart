/// Application-wide constants and configuration.
class AppConstants {
  AppConstants._();

  static const String appName = 'PharmaCare';
  static const String appTagline = 'Pharmacy Management System';

  /// Currency used throughout the app. Tanzanian Shilling by default to match
  /// the supported mobile-money providers (M-Pesa, Tigo Pesa, Airtel Money).
  static const String currencySymbol = 'TSh';
  static const String currencyLocale = 'en_US';

  /// Notify the pharmacist this many days before a medicine expires.
  static const int expiryWarningDays = 5;

  /// Default reorder threshold used when registering a medicine without one.
  static const int defaultReorderLevel = 10;

  /// Medicine categories offered in the registration form.
  static const List<String> medicineCategories = <String>[
    'Analgesic',
    'Antibiotic',
    'Antacid',
    'Antifungal',
    'Antihistamine',
    'Antimalarial',
    'Antiseptic',
    'Cardiovascular',
    'Dermatological',
    'Supplement',
    'Syrup',
    'Vaccine',
    'Vitamin',
    'Other',
  ];

  /// Shared-preferences keys.
  static const String prefThemeMode = 'pref_theme_mode';
  static const String prefSessionUserId = 'pref_session_user_id';
}

/// User roles for role-based access control.
enum UserRole { admin, pharmacist }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Administrator',
        UserRole.pharmacist => 'Pharmacist',
      };

  String get storageValue => name;

  static UserRole fromStorage(String value) =>
      UserRole.values.firstWhere((r) => r.name == value,
          orElse: () => UserRole.pharmacist);
}

/// Supported payment methods.
enum PaymentMethod { cash, card, mobileMoney, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Credit/Debit Card',
        PaymentMethod.mobileMoney => 'Mobile Money',
        PaymentMethod.bankTransfer => 'Bank Transfer',
      };

  String get storageValue => name;

  static PaymentMethod fromStorage(String value) =>
      PaymentMethod.values.firstWhere((m) => m.name == value,
          orElse: () => PaymentMethod.cash);
}
