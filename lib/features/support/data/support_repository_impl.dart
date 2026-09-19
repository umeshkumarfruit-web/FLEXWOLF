import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/support/domain/support_models.dart';
import 'package:flexwolf/features/support/domain/support_repository.dart';
import 'package:flexwolf/integrations/gorgias/gorgias_boundary.dart';

class CachedSupportRepository implements SupportRepository {
  CachedSupportRepository({required this.gorgias});

  final GorgiasGateway gorgias;
  List<FaqCategory>? _categories;
  List<FaqItem>? _items;
  Future<List<FaqCategory>>? _categoryRequest;
  Future<List<FaqItem>>? _itemRequest;
  Future<SupportTicketResult>? _submitRequest;

  @override
  Future<List<FaqCategory>> fetchFaqCategories() {
    final cached = _categories;
    if (cached != null) return Future.value(cached);
    return _categoryRequest ??= Future<List<FaqCategory>>(() {
      _categories = _defaultCategories;
      _categoryRequest = null;
      return _defaultCategories;
    });
  }

  @override
  Future<List<FaqItem>> fetchFaqItems() {
    final cached = _items;
    if (cached != null) return Future.value(cached);
    return _itemRequest ??= Future<List<FaqItem>>(() {
      _items = _defaultFaqItems;
      _itemRequest = null;
      return _defaultFaqItems;
    });
  }

  @override
  Future<SupportTicketResult> submitContactRequest(SupportRequest request) {
    if (_submitRequest != null) return _submitRequest!;
    _submitRequest = _submit(request);
    return _submitRequest!;
  }

  Future<SupportTicketResult> _submit(SupportRequest request) async {
    try {
      if (!gorgias.isConfigured) {
        throw const AppException(
          kind: AppErrorKind.unavailable,
          message: 'CLIENT DEPENDENCY: Gorgias credentials and secure ticket endpoint are pending.',
          code: 'gorgias_not_configured',
          isRetryable: true,
        );
      }
      return await gorgias.createTicket(request);
    } finally {
      _submitRequest = null;
    }
  }
}

const _defaultCategories = <FaqCategory>[
  FaqCategory(id: 'orders', title: 'Orders'),
  FaqCategory(id: 'shipping', title: 'Shipping'),
  FaqCategory(id: 'returns', title: 'Returns'),
  FaqCategory(id: 'products', title: 'Products'),
  FaqCategory(id: 'account', title: 'Account'),
];

const _defaultFaqItems = <FaqItem>[
  FaqItem(
    id: 'track-order',
    categoryId: 'orders',
    question: 'How do I track my order?',
    answer: 'Open Account, then Orders, and select an order to view fulfillment and tracking details when Shopify provides them.',
  ),
  FaqItem(
    id: 'change-order',
    categoryId: 'orders',
    question: 'Can I change an order after placing it?',
    answer: 'Submit an order support request as soon as possible. Changes depend on fulfillment status and warehouse processing.',
  ),
  FaqItem(
    id: 'shipping-time',
    categoryId: 'shipping',
    question: 'When will my order ship?',
    answer: 'Shipping timing is calculated after checkout and updates in your order details once fulfillment begins.',
  ),
  FaqItem(
    id: 'returns-window',
    categoryId: 'returns',
    question: 'How do returns and exchanges work?',
    answer: 'Eligible orders show Return or Exchange actions in order details. Final policy content remains controlled by FLEXWOLF operations.',
  ),
  FaqItem(
    id: 'product-sizing',
    categoryId: 'products',
    question: 'Where can I find sizing help?',
    answer: 'Open a product page and review available size options. Product-specific size chart content is a client content dependency.',
  ),
  FaqItem(
    id: 'account-login',
    categoryId: 'account',
    question: 'Do I need an account for support?',
    answer: 'No. You can contact support as a guest, but adding an order number helps the team resolve order issues faster.',
  ),
];
