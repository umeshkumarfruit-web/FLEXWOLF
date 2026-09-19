import 'package:flexwolf/features/returns/data/returns_repository_impl.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';
import 'package:flexwolf/features/returns/domain/returns_repository.dart';
import 'package:flexwolf/integrations/redo/redo_boundary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final redoReturnsGatewayProvider = Provider<RedoReturnsGateway>(
  (ref) => const ClientDependencyRedoReturnsGateway(),
);

final returnReasonsProvider = Provider<List<ReturnReason>>(
  (ref) => const <ReturnReason>[
    ReturnReason(id: 'wrong_size', label: 'Wrong Size'),
    ReturnReason(id: 'wrong_product', label: 'Wrong Product'),
    ReturnReason(id: 'damaged_item', label: 'Damaged Item'),
    ReturnReason(id: 'defective_product', label: 'Defective Product'),
    ReturnReason(id: 'quality_issue', label: 'Quality Issue'),
    ReturnReason(id: 'other', label: 'Other'),
  ],
);

final returnsRepositoryProvider = Provider<ReturnsRepository>(
  (ref) => DefaultReturnsRepository(
    redo: ref.watch(redoReturnsGatewayProvider),
    configuredReasons: ref.watch(returnReasonsProvider),
  ),
);
