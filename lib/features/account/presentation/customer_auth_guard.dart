import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Requires a valid FLEXWOLF customer session before a shopping action.
Future<CustomerSession?> requireCustomerSession(
  BuildContext context,
  WidgetRef ref, {
  String message = 'Create an account or sign in to shop with FLEXWOLF.',
}) async {
  var session = await ref.read(customerSessionProvider.future);
  if (session != null && !session.isExpired) return session;

  if (!context.mounted) return null;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  await context.push<void>(AppRoutes.account);
  ref.invalidate(customerSessionProvider);
  session = await ref.read(customerSessionProvider.future);

  if (session == null && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Sign in is required before you can continue shopping.',
          ),
        ),
      );
  }
  return session;
}
