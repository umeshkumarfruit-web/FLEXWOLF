// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/integrations/cms/cms_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';

class LocalCachedHomeContentDataSource implements CachedHomeContentDataSource {
  const LocalCachedHomeContentDataSource({
    required LocalStorage storage,
    this.cacheKey = _defaultCacheKey,
  }) : _storage = storage;

  static const _defaultCacheKey = 'home.last_known_good_config.v1';

  final LocalStorage _storage;
  final String cacheKey;

  @override
  Future<CachedHomeConfig?> readLastKnownGoodConfig() async {
    final raw = await _storage.readString(cacheKey);
    if (raw == null) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    final parsed = HomeConfigParser.parse(decoded);
    final config = parsed.config;
    final cachedAt = config?.cache.cachedAt;
    final expectedVersion = config == null
        ? null
        : 'schema-${config.schemaVersion}';
    if (!parsed.isValid ||
        config == null ||
        cachedAt == null ||
        config.cache.version != expectedVersion) {
      return null;
    }
    return CachedHomeConfig(config: config, cachedAt: cachedAt);
  }

  @override
  Future<void> writeLastKnownGoodConfig(HomeConfig config) async {
    await _storage.writeString(cacheKey, jsonEncode(config.toJson()));
  }
}

class FirebaseRemoteConfigHomeContentDataSource
    implements RemoteHomeContentDataSource {
  const FirebaseRemoteConfigHomeContentDataSource(this._remoteConfigGateway);

  final FirebaseRemoteConfigGateway _remoteConfigGateway;

  @override
  Future<Map<String, Object?>> fetchHomeConfig() {
    return _remoteConfigGateway.fetchSafeDefaults();
  }
}

class CmsHomeContentDataSource implements RemoteHomeContentDataSource {
  const CmsHomeContentDataSource(this._cmsGateway);

  final CmsContentGateway _cmsGateway;

  @override
  Future<Map<String, Object?>> fetchHomeConfig() {
    return _cmsGateway.fetchAppContent();
  }
}
