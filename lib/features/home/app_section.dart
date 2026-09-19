import 'package:flexwolf/app/router/route_names.dart';
import 'package:flutter/material.dart';

@immutable
class AppSectionConfig {
  const AppSectionConfig({
    required this.route,
    required this.routeName,
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String routeName;
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
}

enum AppSection {
  home(
    AppSectionConfig(
      route: AppRoutes.home,
      routeName: AppRouteNames.home,
      label: 'Home',
      title: 'Home foundation',
      description:
          'Native app shell placeholder. Dynamic home sections are deferred.',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
  ),
  shop(
    AppSectionConfig(
      route: AppRoutes.shop,
      routeName: AppRouteNames.shop,
      label: 'Shop',
      title: 'Shop foundation',
      description: 'Top-level shop shell only. Collections and product browsing are deferred.',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
  ),
  search(
    AppSectionConfig(
      route: AppRoutes.search,
      routeName: AppRouteNames.search,
      label: 'Search',
      title: 'Search foundation',
      description: 'Search route placeholder. Production search is deferred.',
      icon: Icons.search,
      selectedIcon: Icons.search,
    ),
  ),
  wishlist(
    AppSectionConfig(
      route: AppRoutes.wishlist,
      routeName: AppRouteNames.wishlist,
      label: 'Wishlist',
      title: 'Wishlist foundation',
      description:
          'Wishlist route placeholder. Persistence and sync are deferred.',
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
    ),
  ),
  support(
    AppSectionConfig(
      route: AppRoutes.support,
      routeName: AppRouteNames.support,
      label: 'Support',
      title: 'Support',
      description: 'Customer support, FAQ, order support, and product support.',
      icon: Icons.support_agent_outlined,
      selectedIcon: Icons.support_agent,
    ),
  ),
  account(
    AppSectionConfig(
      route: AppRoutes.account,
      routeName: AppRouteNames.account,
      label: 'Account',
      title: 'Account foundation',
      description:
          'Account route placeholder. Customer Account API flows are deferred.',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  );

  const AppSection(this.config);

  final AppSectionConfig config;

  String get path => config.route;
  String get routeName => config.routeName;
  String get label => config.label;
  String get title => config.title;
  String get description => config.description;
  IconData get icon => config.icon;
  IconData get selectedIcon => config.selectedIcon;
}
