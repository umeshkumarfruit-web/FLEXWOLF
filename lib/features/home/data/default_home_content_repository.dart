// ignore_for_file: prefer_initializing_formals

import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';

class DefaultHomeContentRepository implements HomeContentRepository {
  const DefaultHomeContentRepository({
    required RemoteHomeContentDataSource remoteDataSource,
    required CachedHomeContentDataSource cachedDataSource,
    required Clock clock,
    AppLogger? logger,
  }) : _remoteDataSource = remoteDataSource,
       _cachedDataSource = cachedDataSource,
       _clock = clock,
       _logger = logger;

  final RemoteHomeContentDataSource _remoteDataSource;
  final CachedHomeContentDataSource _cachedDataSource;
  final Clock _clock;
  final AppLogger? _logger;

  @override
  Future<HomeContentResult> fetchHomeContent() async {
    try {
      final remoteJson = await _remoteDataSource.fetchHomeConfig();
      final parsed = HomeConfigParser.parse(remoteJson);
      final config = parsed.config;
      if (parsed.unknownSections.isNotEmpty) {
        _logger?.warning(
          'Skipped ${parsed.unknownSections.length} unknown Home section type(s).',
        );
      }
      final remoteSections = remoteJson['sections'];
      final hasRejectedSections =
          remoteSections is List &&
          remoteSections.isNotEmpty &&
          config != null &&
          config.sections.isEmpty &&
          parsed.diagnostics.isNotEmpty;
      if (config != null && !hasRejectedSections) {
        final cacheReadyConfig = config.withCacheMetadata(
          config.cache.refreshed(_clock.nowUtc()),
        );
        await _cachedDataSource.writeLastKnownGoodConfig(cacheReadyConfig);
        return HomeContentResult(
          config: cacheReadyConfig,
          source: HomeContentSource.remote,
          diagnostics: parsed.diagnostics,
        );
      }
      _logger?.warning('Rejected malformed Home remote configuration.');
      return await _cachedFallback(
        warning: 'Home content is using cached content because the latest configuration was invalid.',
        diagnostics: parsed.diagnostics,
      );
    } catch (error) {
      _logger?.warning('Home remote configuration fetch failed.', error: error);
      return await _cachedFallback(
        warning: 'Home content is using cached content because the latest configuration could not be loaded.',
        diagnostics: <String>['Remote Home content fetch failed.'],
      );
    }
  }

  Future<HomeContentResult> _cachedFallback({
    required String warning,
    required List<String> diagnostics,
  }) async {
    try {
      final cached = await _cachedDataSource.readLastKnownGoodConfig();
      if (cached != null) {
        return HomeContentResult(
          config: cached.config,
          source: HomeContentSource.cache,
          warning: warning,
          diagnostics: diagnostics,
        );
      }
    } catch (error) {
      _logger?.warning(
        'Home cached configuration could not be read.',
        error: error,
      );
    }
    return HomeContentResult(
      config: null,
      source: HomeContentSource.unavailable,
      warning: 'Home content is unavailable. Please retry.',
      diagnostics: diagnostics,
    );
  }
}
