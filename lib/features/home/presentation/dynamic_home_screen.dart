import 'package:flexwolf/features/home/presentation/flexwolf_storefront_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DynamicHomeScreen extends ConsumerStatefulWidget {
  const DynamicHomeScreen({super.key});
  @override
  ConsumerState<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends ConsumerState<DynamicHomeScreen> {
  @override
  Widget build(BuildContext context) => const FlexwolfStorefrontHome();
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
