import 'package:flexwolf/features/admin/domain/admin_operations_models.dart';

abstract interface class AdminOperationsRepository {
  Future<AdminOperationsSnapshot> fetchSnapshot();

  Future<List<AdminContentApprovalItem>> fetchContentApprovals();

  Future<List<AdminSupportQueueSummary>> fetchSupportQueues();

  Future<List<AdminReturnQueueSummary>> fetchReturnQueues();

  Future<List<AdminReviewModerationSummary>> fetchReviewModeration();

  Future<void> updateReturnStatus(String returnId, AdminReturnBucket status);

  Future<void> moderateReview(String reviewId, AdminReviewBucket status);
}
