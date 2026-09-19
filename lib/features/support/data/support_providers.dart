import 'package:flexwolf/features/support/data/support_repository_impl.dart';
import 'package:flexwolf/features/support/domain/support_models.dart';
import 'package:flexwolf/features/support/domain/support_repository.dart';
import 'package:flexwolf/integrations/gorgias/gorgias_boundary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gorgiasGatewayProvider = Provider<GorgiasGateway>(
  (ref) => const ClientDependencyGorgiasGateway(),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => CachedSupportRepository(gorgias: ref.watch(gorgiasGatewayProvider)),
);

final faqCategoriesProvider = FutureProvider<List<FaqCategory>>(
  (ref) => ref.watch(supportRepositoryProvider).fetchFaqCategories(),
);

final faqItemsProvider = FutureProvider<List<FaqItem>>(
  (ref) => ref.watch(supportRepositoryProvider).fetchFaqItems(),
);
