abstract interface class CmsContentGateway {
  Future<Map<String, Object?>> fetchAppContent();
}

abstract interface class RemoteFeatureConfigGateway {
  Future<Map<String, Object?>> fetchFeatureConfig();
}
