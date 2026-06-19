import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/medicines/data/medicine_repository.dart';
import '../features/sales/data/sales_repository.dart';
import 'api/api_client.dart';
import 'constants/app_constants.dart';

/// Single shared HTTP client pointed at the PHP/MySQL backend.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(baseUrl: AppConstants.apiBaseUrl),
);

final medicineRepositoryProvider = Provider<MedicineRepository>(
  (ref) => MedicineRepository(ref.watch(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => SalesRepository(ref.watch(apiClientProvider)),
);
