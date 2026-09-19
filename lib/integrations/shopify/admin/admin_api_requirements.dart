class AdminApiRequirement {
  const AdminApiRequirement({
    required this.businessRequirement,
    required this.whyStorefrontOrCustomerApiCannotSatisfy,
    required this.requiredScopes,
    required this.securityPlan,
    required this.status,
  });

  final String businessRequirement;
  final String whyStorefrontOrCustomerApiCannotSatisfy;
  final List<String> requiredScopes;
  final String securityPlan;
  final AdminApiRequirementStatus status;
}

enum AdminApiRequirementStatus { notRequiredYet, proposed, approved, removed }

abstract interface class ShopifyAdminBackendGateway {
  Future<void> invokeApprovedServerSideOperation(String operationName);
}

class ShopifyAdminApiDisabled implements ShopifyAdminBackendGateway {
  const ShopifyAdminApiDisabled();

  @override
  Future<void> invokeApprovedServerSideOperation(String operationName) {
    throw UnsupportedError(
      'Shopify Admin API operations require the secure FLEXWOLF backend.',
    );
  }
}
