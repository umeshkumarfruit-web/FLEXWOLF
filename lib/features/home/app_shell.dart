import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/widgets/app_icon_action_button.dart';
import 'package:flexwolf/core/widgets/app_scaffold.dart';
import 'package:flexwolf/core/widgets/flexwolf_logo.dart';
import 'package:flexwolf/app/theme/theme_mode_controller.dart';
import 'package:flexwolf/features/home/app_main_navigation_bar.dart';
import 'package:flexwolf/features/home/app_section.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;

    return PopScope(
      canPop: currentIndex == AppSection.home.index,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != AppSection.home.index) {
          navigationShell.goBranch(AppSection.home.index);
        }
      },
      child: AppScaffold(
        drawer: _StorefrontDrawer(
          currentIndex: currentIndex,
          onDestinationSelected: _goToBranch,
        ),
        actions: [
          AppIconActionButton(
            icon: Icons.search,
            semanticLabel: 'Search FLEXWOLF',
            isSelected: currentIndex == AppSection.search.index,
            onPressed: () => _goToBranch(AppSection.search.index),
          ),
          AppIconActionButton(
            icon: currentIndex == AppSection.wishlist.index
                ? Icons.favorite
                : Icons.favorite_border,
            semanticLabel: 'Wishlist FLEXWOLF',
            isSelected: currentIndex == AppSection.wishlist.index,
            onPressed: () => _goToBranch(AppSection.wishlist.index),
          ),
          AnimatedBuilder(
            animation: ref.watch(cartControllerProvider),
            builder: (context, _) {
              final count = ref.read(cartControllerProvider).itemCount;
              return Semantics(
                label: 'Cart, $count items',
                button: true,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Cart',
                      onPressed: () => context.push('/cart'),
                      icon: const Icon(Icons.shopping_bag_outlined),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 3,
                        top: 3,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: const BoxDecoration(
                            color: AppColors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
        body: Column(
          children: [
            const _StorefrontAnnouncementBar(),
            Expanded(child: navigationShell),
          ],
        ),
        bottomNavigationBar: AppMainNavigationBar(
          currentIndex: currentIndex,
          onDestinationSelected: _goToBranch,
        ),
      ),
    );
  }

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _StorefrontAnnouncementBar extends StatelessWidget {
  const _StorefrontAnnouncementBar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'FLEXWOLF store announcement. Easy 60 day returns and free shipping on orders over 75 dollars.',
      child: Container(
        width: double.infinity,
        color: AppColors.black,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          'EASY 60-DAY RETURNS   •   FREE SHIPPING ON ORDERS OVER \$75',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class _StorefrontDrawer extends ConsumerWidget {
  const _StorefrontDrawer({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _sections = <AppSection>[
    AppSection.home,
    AppSection.shop,
    AppSection.search,
    AppSection.wishlist,
    AppSection.support,
    AppSection.account,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeController = ref.watch(appThemeModeControllerProvider);

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.88,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 28),
              child: FlexwolfLogo(),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  for (final section in _sections)
                    ListTile(
                      minTileHeight: 54,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      leading: Icon(
                        section.index == currentIndex
                            ? section.selectedIcon
                            : section.icon,
                        size: 22,
                      ),
                      title: Text(
                        section.label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      trailing: const Icon(Icons.arrow_forward, size: 18),
                      selected: section.index == currentIndex,
                      onTap: () {
                        Navigator.of(context).pop();
                        onDestinationSelected(section.index);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeController,
              builder: (context, mode, _) {
                final isDark =
                    mode == ThemeMode.dark ||
                    (mode == ThemeMode.system &&
                        MediaQuery.platformBrightnessOf(context) ==
                            Brightness.dark);

                return ListTile(
                  minTileHeight: 58,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  leading: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 22,
                  ),
                  title: Text(
                    isDark ? 'LIGHT MODE' : 'DARK MODE',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (useDarkMode) {
                      themeModeController.value = useDarkMode
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                  ),
                  onTap: () {
                    themeModeController.value = isDark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                  },
                );
              },
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'TRUST LIKE A WOLF.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
