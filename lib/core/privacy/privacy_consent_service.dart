abstract interface class PrivacyConsentService {
  Future<bool> hasAnalyticsConsent();

  Future<bool> hasMarketingConsent();
}

class UnknownPrivacyConsentService implements PrivacyConsentService {
  const UnknownPrivacyConsentService();

  @override
  Future<bool> hasAnalyticsConsent() async => false;

  @override
  Future<bool> hasMarketingConsent() async => false;
}
