import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// Live, admin-claim protected operations. Shopify credentials stay in
/// Firebase Functions; the app only sends validated action input.
class AdminStoreOperationsScreen extends StatefulWidget {
  const AdminStoreOperationsScreen({super.key});

  @override
  State<AdminStoreOperationsScreen> createState() =>
      _AdminStoreOperationsScreenState();
}

class _AdminStoreOperationsScreenState
    extends State<AdminStoreOperationsScreen> {
  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(
    app: Firebase.app('flexwolfAdmin'),
    region: 'us-central1',
  );
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _pushTitle = TextEditingController();
  final _pushBody = TextEditingController();
  Future<List<Map<String, dynamic>>>? _products;
  Future<List<Map<String, dynamic>>>? _orders;
  Future<List<Map<String, dynamic>>>? _users;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _pushTitle.dispose();
    _pushBody.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, Object?> data = const {},
  ]) async {
    final result = await _functions.httpsCallable('adminOperations').call(
      <String, Object?>{'action': action, ...data},
    );
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<List<Map<String, dynamic>>> _list(String action) async {
    final result = await _call(action);
    return (result['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  void _refresh() {
    if (Firebase.apps.isEmpty) return;
    setState(() {
      _products = _list('products');
      _orders = _list('orders');
      _users = _list('users');
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved successfully')));
        _refresh();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Action failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Column(
      children: [
        const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Products'),
            Tab(text: 'Orders'),
            Tab(text: 'Firebase users'),
            Tab(text: 'Push'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [_productsTab(), _ordersTab(), _usersTab(), _pushTab()],
          ),
        ),
      ],
    ),
  );

  Widget _items(
    Future<List<Map<String, dynamic>>>? future,
    Widget Function(Map<String, dynamic>) builder,
  ) {
    if (future == null) return const Center(child: CircularProgressIndicator());
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No records found'));
        }
        return ListView(children: snapshot.data!.map(builder).toList());
      },
    );
  }

  Widget _productsTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'New product title'),
            ),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await _call('createProduct', {
                        'title': _title.text.trim(),
                        'price': _price.text.trim(),
                      });
                      _title.clear();
                      _price.clear();
                    }),
              child: const Text('Create draft product'),
            ),
            const Text(
              'Review and publish the draft in Shopify after adding images and inventory.',
            ),
          ],
        ),
      ),
      Expanded(
        child: _items(_products, (product) {
          final variants =
              (product['variants'] as Map?)?['nodes'] as List? ?? [];
          return ExpansionTile(
            title: Text('${product['title']}'),
            subtitle: Text('${product['status']}'),
            children: variants.map((raw) {
              final variant = Map<String, dynamic>.from(raw as Map);
              return ListTile(
                title: Text('${variant['title']}'),
                subtitle: Text('Price: ${variant['price']}'),
                trailing: IconButton(
                  tooltip: 'Update price',
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPrice(product, variant),
                ),
              );
            }).toList(),
          );
        }),
      ),
    ],
  );

  Future<void> _editPrice(
    Map<String, dynamic> product,
    Map<String, dynamic> variant,
  ) async {
    final controller = TextEditingController(text: '${variant['price']}');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price: ${product['title']}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'New price'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    await _run(
      () async => _call('updatePrice', {
        'productId': product['id'] as String,
        'variantId': variant['id'] as String,
        'price': value,
      }),
    );
  }

  Widget _ordersTab() => RefreshIndicator(
    onRefresh: () async => _refresh(),
    child: _items(_orders, (order) {
      final money = (order['totalPriceSet'] as Map?)?['shopMoney'] as Map?;
      return ListTile(
        title: Text(
          '${order['name']}  ?  ${money?['amount'] ?? ''} ${money?['currencyCode'] ?? ''}',
        ),
        subtitle: Text(
          'Payment: ${order['displayFinancialStatus']}  ?  Fulfillment: ${order['displayFulfillmentStatus']}',
        ),
      );
    }),
  );

  Widget _usersTab() => _items(
    _users,
    (user) => ListTile(
      title: Text('${user['email']}'),
      subtitle: Text('Firebase UID: ${user['uid']}'),
      trailing: user['disabled'] == true ? const Text('Disabled') : null,
    ),
  );

  Widget _pushTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Send a notification to signed-in customers who enabled push.',
      ),
      TextField(
        controller: _pushTitle,
        maxLength: 100,
        decoration: const InputDecoration(labelText: 'Notification title'),
      ),
      TextField(
        controller: _pushBody,
        maxLength: 500,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Message'),
      ),
      FilledButton(
        onPressed: _busy
            ? null
            : () => _run(() async {
                await _call('sendPush', {
                  'title': _pushTitle.text.trim(),
                  'body': _pushBody.text.trim(),
                });
                _pushTitle.clear();
                _pushBody.clear();
              }),
        child: const Text('Send push notification'),
      ),
    ],
  );
}
