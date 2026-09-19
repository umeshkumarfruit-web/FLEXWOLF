import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/support/domain/support_models.dart';

abstract interface class GorgiasGateway {
  bool get isConfigured;
  Future<SupportTicketResult> createTicket(SupportRequest request);
}

class ClientDependencyGorgiasGateway implements GorgiasGateway {
  const ClientDependencyGorgiasGateway();

  @override
  bool get isConfigured => false;

  @override
  Future<SupportTicketResult> createTicket(SupportRequest request) async {
    throw const AppException(
      kind: AppErrorKind.unavailable,
      message: 'CLIENT DEPENDENCY: Gorgias credentials and server-side ticket endpoint are not configured.',
      code: 'gorgias_not_configured',
      isRetryable: true,
    );
  }
}
