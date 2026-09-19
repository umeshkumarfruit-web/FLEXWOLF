import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeActionDispatcher {
  const HomeActionDispatcher();

  bool canDispatch(HomeDestination? destination) {
    if (destination == null || destination.type == HomeDestinationType.none) {
      return false;
    }
    final value = destination.value;
    return value != null && value.trim().isNotEmpty;
  }

  void dispatch(BuildContext context, HomeDestination? destination) {
    if (!canDispatch(destination)) {
      return;
    }
    final value = destination!.value!.trim();
    switch (destination.type) {
      case HomeDestinationType.product:
        context.goNamed(
          AppRouteNames.product,
          pathParameters: <String, String>{'handle': value},
        );
      case HomeDestinationType.collection:
        context.goNamed(
          AppRouteNames.collection,
          pathParameters: <String, String>{'handle': value},
        );
      case HomeDestinationType.internalRoute:
        if (_allowedInternalRoutes.contains(value)) {
          context.go(value);
        }
      case HomeDestinationType.search:
        context.goNamed(
          AppRouteNames.search,
          queryParameters: <String, String>{'q': value},
        );
      case HomeDestinationType.promotion:
        context.goNamed(
          AppRouteNames.promotion,
          pathParameters: <String, String>{'id': value},
        );
      case HomeDestinationType.externalUrl:
        context.go(
          AppRoutes.shop,
          extra: <String, String>{'pendingExternalUrl': value},
        );
      case HomeDestinationType.none:
        break;
    }
  }

  static const _allowedInternalRoutes = <String>{
    AppRoutes.home,
    AppRoutes.shop,
    AppRoutes.search,
    AppRoutes.wishlist,
    AppRoutes.account,
  };
}
