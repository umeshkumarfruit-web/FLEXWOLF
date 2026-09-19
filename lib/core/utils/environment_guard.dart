import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/errors/app_exception.dart';

void requireProductionSideEffectsAllowed(AppConfig config) {
  if (!config.allowsProductionSideEffects) {
    throw AppException(
      kind: AppErrorKind.unexpected,
      message:
          'Production-only side effects are disabled for ${config.environment.label}.',
      code: 'environment_guard',
    );
  }
}
