import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/layout/responsive_page_padding.dart';
import 'package:flexwolf/core/widgets/app_badge.dart';
import 'package:flexwolf/core/widgets/app_section_heading.dart';
import 'package:flexwolf/features/account/presentation/account_auth_screen.dart';
import 'package:flexwolf/features/home/app_section.dart';
import 'package:flexwolf/features/home/presentation/dynamic_home_screen.dart';
import 'package:flexwolf/features/shop/presentation/shop_screen.dart';
import 'package:flexwolf/features/support/presentation/support_screen.dart';
import 'package:flexwolf/features/wishlist/presentation/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDestinationShell extends ConsumerWidget {
  const AppDestinationShell({required this.section, super.key});

  final AppSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section == AppSection.home) {
      return const DynamicHomeScreen();
    }
    if (section == AppSection.search) {
      return const ResponsivePagePadding(child: ShopScreen(searchMode: true));
    }
    if (section == AppSection.shop) {
      return const ResponsivePagePadding(child: ShopScreen());
    }
    if (section == AppSection.wishlist) {
      return const ResponsivePagePadding(child: WishlistScreen());
    }
    if (section == AppSection.support) {
      return const ResponsivePagePadding(child: SupportScreen());
    }
    if (section == AppSection.account) {
      return const ResponsivePagePadding(child: AccountAuthScreen());
    }

    final config = ref.watch(appConfigProvider);

    return Semantics(
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: section.label,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBadge(label: section.label.toUpperCase()),
            const SizedBox(height: AppSpacing.md),
            AppSectionHeading(title: section.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'FLEXWOLF app shell is running in ${config.environment.label}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              section.description,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
