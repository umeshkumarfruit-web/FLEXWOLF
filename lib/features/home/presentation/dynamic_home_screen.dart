import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_network_status_banner.dart';
import 'package:flexwolf/features/home/data/home_content_providers.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/features/home/presentation/home_action_dispatcher.dart';
import 'package:flexwolf/features/home/presentation/renderers/home_section_renderer_registry.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DynamicHomeScreen extends ConsumerStatefulWidget {
  const DynamicHomeScreen({super.key});

  @override
  ConsumerState<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends ConsumerState<DynamicHomeScreen> {
  static const _actionDispatcher = HomeActionDispatcher();
  final Set<String> _trackedSectionImpressions = <String>{};
  var _trackedHomeView = false;

  @override
  Widget build(BuildContext context) {
    final asyncResult = ref.watch(homeContentResultProvider);
    return asyncResult.when(
      loading: () => const HomeLoadingView(),
      error: (error, stackTrace) => HomeUnavailableView(onRetry: _refresh),
      data: (result) {
        _trackHome(result);
        final nowUtc = ref.watch(homeClockProvider).nowUtc();
        final sections = result.config?.activeSections(nowUtc) ?? const [];
        if (result.config == null) {
          return HomeUnavailableView(onRetry: _refresh);
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (result.source == HomeContentSource.cache)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppNetworkStatusBanner(
                      message: 'Showing saved Home content.',
                      status: AppNetworkStatus.stale,
                      actionLabel: 'Retry',
                      onAction: _refresh,
                    ),
                  ),
                ),
              if (sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppRetryState(
                    title: 'Home content is not available yet',
                    message: 'Pull to refresh or try again.',
                    onRetry: _refresh,
                    icon: Icons.storefront_outlined,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    _trackSectionImpression(section.id, section.analyticsName);
                    return HomeSectionRendererRegistry.render(
                      HomeSectionRenderContext(
                        section: section,
                        actionDispatcher: _actionDispatcher,
                        nowUtc: nowUtc,
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(homeContentResultProvider);
    await ref.read(homeContentResultProvider.future);
  }

  void _trackHome(HomeContentResult result) {
    if (_trackedHomeView) {
      return;
    }
    _trackedHomeView = true;
    final analytics = ref.read(analyticsGatewayProvider);
    analytics.track(
      AnalyticsEvent(
        name: AppAnalyticsEvents.homeView,
        parameters: <String, Object?>{
          'source': result.source.name,
          'schemaVersion': result.config?.schemaVersion,
          'sectionCount': result.config?.sections.length ?? 0,
        },
      ),
    );
  }

  void _trackSectionImpression(String sectionId, String analyticsName) {
    if (!_trackedSectionImpressions.add(sectionId)) {
      return;
    }
    ref
        .read(analyticsGatewayProvider)
        .track(
          AnalyticsEvent(
            name: AppAnalyticsEvents.homeSectionImpression,
            parameters: <String, Object?>{
              'sectionId': sectionId,
              'sectionType': analyticsName,
            },
          ),
        );
  }
}

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AppSkeletonLoader(height: 420),
              SizedBox(height: AppSpacing.xl),
              HomeRailSkeleton(title: 'Loading products'),
              HomeRailSkeleton(title: 'Loading collections'),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeUnavailableView extends StatelessWidget {
  const HomeUnavailableView({required this.onRetry, super.key});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorState(
            error: const AppException(
              kind: AppErrorKind.network,
              message: 'Home content could not be loaded.',
              code: 'home_content_unavailable',
              isRetryable: true,
            ),
            onRetry: () => onRetry(),
          ),
        ),
      ],
    );
  }
}
