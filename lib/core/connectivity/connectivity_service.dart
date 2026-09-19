enum ConnectivityQuality { unknown, offline, weak, online }

class ConnectivitySnapshot {
  const ConnectivitySnapshot({
    required this.quality,
    this.isRetryRecommended = false,
  });

  final ConnectivityQuality quality;
  final bool isRetryRecommended;
}

abstract interface class ConnectivityService {
  Stream<ConnectivitySnapshot> watch();

  Future<ConnectivitySnapshot> current();
}

class UnknownConnectivityService implements ConnectivityService {
  const UnknownConnectivityService();

  static const snapshot = ConnectivitySnapshot(
    quality: ConnectivityQuality.unknown,
  );

  @override
  Future<ConnectivitySnapshot> current() async => snapshot;

  @override
  Stream<ConnectivitySnapshot> watch() =>
      Stream<ConnectivitySnapshot>.value(snapshot);
}
