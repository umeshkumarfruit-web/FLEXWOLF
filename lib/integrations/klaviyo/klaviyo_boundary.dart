abstract interface class KlaviyoProfileGateway {
  Future<void> identifyProfile(String customerId);
}

abstract interface class KlaviyoEventGateway {
  Future<void> trackEvent(KlaviyoEvent event);
}

class KlaviyoEvent {
  const KlaviyoEvent({
    required this.name,
    this.properties = const <String, Object?>{},
  });

  final String name;
  final Map<String, Object?> properties;
}
