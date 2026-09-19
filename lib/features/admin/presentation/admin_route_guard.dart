import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminRouteGuard extends ConsumerWidget {
  const AdminRouteGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(adminSessionProvider);
    return session.when(
      loading: () => const Scaffold(
        body: Center(child: AppSkeletonLoader(width: 240, height: 160)),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: AppErrorState(
            error: mapUnknownException(error),
            onRetry: () => ref.invalidate(adminSessionProvider),
          ),
        ),
      ),
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(AppRoutes.adminLogin);
          });
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppLoadingIndicator(label: 'Opening admin login'),
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}
