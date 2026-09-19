import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/core/monitoring/app_monitoring.dart';
import 'package:flexwolf/core/network/api_client.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final crashReportingGatewayProvider = Provider<FirebaseCrashReportingGateway>((
  ref,
) {
  return const FirebaseCrashReportingNotConfigured();
});

final monitoringGatewayProvider = Provider<MonitoringGateway>((ref) {
  return MonitoringGateway(
    analytics: ref.watch(analyticsGatewayProvider),
    crashReporting: ref.watch(crashReportingGatewayProvider),
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return MonitoredApiClient(
    delegate: NoopApiClient(ref.watch(appConfigProvider)),
    monitoring: ref.watch(monitoringGatewayProvider),
  );
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return InMemorySecureStorage();
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return InMemoryLocalStorage();
});

final analyticsGatewayProvider = Provider<AnalyticsGateway>((ref) {
  return const NoopAnalyticsGateway();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return const UnknownConnectivityService();
});

final loggerProvider = appLoggerProvider;
