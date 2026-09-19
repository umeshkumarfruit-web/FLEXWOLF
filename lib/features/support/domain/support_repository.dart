import 'package:flexwolf/features/support/domain/support_models.dart';

abstract interface class SupportRepository {
  Future<List<FaqCategory>> fetchFaqCategories();
  Future<List<FaqItem>> fetchFaqItems();
  Future<SupportTicketResult> submitContactRequest(SupportRequest request);
}
