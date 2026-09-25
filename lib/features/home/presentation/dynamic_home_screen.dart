import 'package:flexwolf/features/home/presentation/flexwolf_storefront_home.dart';
import 'package:flexwolf/features/home/data/home_content_providers.dart';
import 'package:flexwolf/features/home/presentation/home_action_dispatcher.dart';
import 'package:flexwolf/features/home/presentation/renderers/home_section_renderer_registry.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DynamicHomeScreen extends ConsumerStatefulWidget {
  const DynamicHomeScreen({super.key});
  @override
  ConsumerState<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends ConsumerState<DynamicHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final content = ref.watch(homeContentResultProvider);
    return content.when(
      loading: () => Firebase.apps.isNotEmpty
          ? const FlexwolfStorefrontHome()
          : const Center(child: Text('Loading products')),
      error: (_, _) => Firebase.apps.isNotEmpty
          ? const FlexwolfStorefrontHome()
          : const SizedBox.shrink(),
      data: (result) {
        final sections = result.config?.activeSections(DateTime.now().toUtc());
        if (sections == null || sections.isEmpty) {
          return const FlexwolfStorefrontHome();
        }
        return CustomScrollView(
          slivers: [
            if (result.isStale)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Showing saved Home content.'),
                ),
              ),
            for (final section in sections)
              SliverToBoxAdapter(
                child: HomeSectionRendererRegistry.render(
                  HomeSectionRenderContext(
                    section: section,
                    actionDispatcher: const HomeActionDispatcher(),
                    nowUtc: DateTime.now().toUtc(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});
  @override
  Widget build(BuildContext context) => const FlexwolfStorefrontHome();
}

class HomeUnavailableView extends StatelessWidget {
  const HomeUnavailableView({required this.onRetry, super.key});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => const FlexwolfStorefrontHome();
}
