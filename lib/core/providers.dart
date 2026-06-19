import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/medicines/data/medicine_repository.dart';
import '../features/sales/data/sales_repository.dart';
import 'database/app_database.dart';

/// Single shared database handle.
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final medicineRepositoryProvider = Provider<MedicineRepository>(
  (ref) => MedicineRepository(ref.watch(databaseProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(databaseProvider)),
);

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(ref.watch(databaseProvider)),
);
