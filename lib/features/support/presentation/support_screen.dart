import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/features/support/data/support_providers.dart';
import 'package:flexwolf/features/support/domain/support_models.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({this.reference, super.key});

  final SupportReference? reference;

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _search = TextEditingController();
  var _selectedCategory = 'all';
  var _trackedOpen = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _trackOpened();
    final categories = ref.watch(faqCategoriesProvider);
    final items = ref.watch(faqItemsProvider);
    return Semantics(
      label: 'Customer support',
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          Text('Support', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Find help, review FAQs, or send a support request.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SupportActions(reference: widget.reference),
          const SizedBox(height: AppSpacing.lg),
          Text('FAQ', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Search FAQ',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          categories.when(
            loading: () => const _SupportSkeleton(),
            error: (error, stack) => AppErrorState(
              error: _map(error),
              onRetry: () => ref.invalidate(faqCategoriesProvider),
            ),
            data: (categoryData) => _CategoryFilter(
              categories: categoryData,
              selected: _selectedCategory,
              onSelected: (value) => setState(() => _selectedCategory = value),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          items.when(
            loading: () => const _SupportSkeleton(),
            error: (error, stack) => AppErrorState(
              error: _map(error),
              onRetry: () => ref.invalidate(faqItemsProvider),
            ),
            data: _buildFaqItems,
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItems(List<FaqItem> items) {
    final query = _search.text.trim().toLowerCase();
    final filtered = items
        .where((item) {
          final matchesCategory =
              _selectedCategory == 'all' ||
              item.categoryId == _selectedCategory;
          final matchesQuery =
              query.isEmpty ||
              item.question.toLowerCase().contains(query) ||
              item.answer.toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
    if (filtered.isEmpty) {
      return const AppEmptyState(
        title: 'No FAQ results',
        message: 'Try a different search or category.',
        icon: Icons.search_off,
      );
    }
    return Column(
      children: [
        for (final item in filtered)
          Semantics(
            button: true,
            label: 'FAQ ${item.question}',
            child: ExpansionTile(
              title: Text(item.question),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item.answer),
                  ),
                ),
              ],
              onExpansionChanged: (expanded) {
                if (expanded) {
                  ref
                      .read(analyticsGatewayProvider)
                      .track(
                        AnalyticsEvent(
                          name: AppAnalyticsEvents.faqViewed,
                          parameters: {'faqId': item.id},
                        ),
                      );
                }
              },
            ),
          ),
      ],
    );
  }

  void _trackOpened() {
    if (_trackedOpen) return;
    _trackedOpen = true;
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: AppAnalyticsEvents.supportOpened));
  }
}

class _SupportActions extends StatelessWidget {
  const _SupportActions({this.reference});

  final SupportReference? reference;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton.secondary(
          label: 'Help Center',
          icon: Icons.help_outline,
          semanticLabel: 'Open help center topics',
          onPressed: () => _showInfo(
            context,
            'Help Center',
            'Help Center content is ready for CMS or Gorgias Help Center feeds when client access is provided.',
          ),
        ),
        AppButton.secondary(
          label: 'Order Support',
          icon: Icons.receipt_long_outlined,
          semanticLabel: 'Contact support about an order',
          onPressed: () => _openContact(
            context,
            reference ??
                const SupportReference(orderNumber: 'Add order number below'),
          ),
        ),
        AppButton.secondary(
          label: 'Product Support',
          icon: Icons.inventory_2_outlined,
          semanticLabel: 'Contact support about a product',
          onPressed: () => _openContact(context, reference),
        ),
        AppButton.primary(
          label: 'Contact Support',
          icon: Icons.support_agent,
          semanticLabel: 'Open contact support form',
          onPressed: () => _openContact(context, reference),
        ),
      ],
    );
  }

  void _openContact(BuildContext context, SupportReference? reference) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactSupportSheet(reference: reference),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<FaqCategory> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, 'all', 'All'),
          for (final category in categories)
            _chip(context, category.id, category.title),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String id, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: selected == id,
        label: 'FAQ category $label',
        child: ChoiceChip(
          label: Text(label),
          selected: selected == id,
          onSelected: (_) => onSelected(id),
        ),
      ),
    );
  }
}

class _ContactSupportSheet extends ConsumerStatefulWidget {
  const _ContactSupportSheet({this.reference});

  final SupportReference? reference;

  @override
  ConsumerState<_ContactSupportSheet> createState() =>
      _ContactSupportSheetState();
}

class _ContactSupportSheetState extends ConsumerState<_ContactSupportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  late final TextEditingController _order;
  late final TextEditingController _product;
  bool _submitting = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _order = TextEditingController(
      text: widget.reference?.orderNumber == 'Add order number below'
          ? ''
          : widget.reference?.orderNumber ?? '',
    );
    _product = TextEditingController(
      text: widget.reference?.productTitle ?? widget.reference?.productId ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    _order.dispose();
    _product.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Semantics(
          label: 'Contact support form',
          explicitChildNodes: true,
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  'Contact Support',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_error != null) ...[
                  AppErrorState(error: _error!, onRetry: _submit),
                  const SizedBox(height: AppSpacing.sm),
                ],
                TextFormField(
                  controller: _name,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _email,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    if (normalized.isEmpty || !normalized.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _subject,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _message,
                  minLines: 4,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (value) {
                    final normalized = value?.trim() ?? '';
                    if (normalized.length < 10) {
                      return 'Enter at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _order,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Order Number (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _product,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Product (optional)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton.primary(
                  label: _submitting ? 'Submitting' : 'Submit',
                  icon: Icons.send,
                  semanticLabel: 'Submit contact support request',
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(supportRepositoryProvider)
          .submitContactRequest(
            SupportRequest(
              name: _name.text.trim(),
              email: _email.text.trim(),
              subject: _subject.text.trim(),
              message: _message.text.trim(),
              orderNumber: _optional(_order.text),
              productId: widget.reference?.productId,
              productTitle: _optional(_product.text),
            ),
          );
      await ref
          .read(analyticsGatewayProvider)
          .track(
            AnalyticsEvent(
              name: AppAnalyticsEvents.contactSubmitted,
              parameters: {
                'clientDependency': result.clientDependency,
                'ticketId': result.id,
              },
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        // ignore: deprecated_member_use
        SemanticsService.announce(
          'Support request submitted',
          TextDirection.ltr,
        );
      }
    } catch (error) {
      _error = _map(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SupportSkeleton extends StatelessWidget {
  const _SupportSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonLoader(height: 48),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonLoader(height: 72),
      ],
    );
  }
}

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) return 'Required';
  return null;
}

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

AppException _map(Object error) =>
    error is AppException ? error : mapUnknownException(error);
