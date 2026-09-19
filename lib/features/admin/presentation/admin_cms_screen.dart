import 'dart:convert';

import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_models.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminCmsScreen extends ConsumerStatefulWidget {
  const AdminCmsScreen({super.key});

  @override
  ConsumerState<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends ConsumerState<AdminCmsScreen> {
  var _trackedView = false;

  @override
  Widget build(BuildContext context) {
    _trackViewed();
    final draft = ref.watch(adminHomeContentDraftProvider);
    return Semantics(
      label: 'CMS and Home content management',
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminHomeContentDraftProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Content',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                AppButton.secondary(
                  label: 'Add Banner',
                  icon: Icons.add_photo_alternate_outlined,
                  semanticLabel: 'Add banner content',
                  onPressed: _addBanner,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Home content uses the existing dynamic Home contract. Shopify collections are referenced, not duplicated.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            draft.when(
              loading: () => const _CmsSkeleton(),
              error: (error, stackTrace) => AppErrorState(
                error: error is AppException
                    ? error
                    : mapUnknownException(error),
                onRetry: () => ref.invalidate(adminHomeContentDraftProvider),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return const AppEmptyState(
                    title: 'No content items',
                    message: 'Add a banner to begin managing Home content.',
                    icon: Icons.article_outlined,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ContentTypeSummary(items: data.items),
                    const SizedBox(height: AppSpacing.lg),
                    for (final item in data.items) ...[
                      _ContentItemTile(
                        item: item,
                        onEdit: () => _editItem(item),
                        onDelete: () => _deleteItem(item),
                        onToggle: (enabled) => _toggleItem(item, enabled),
                        onMoveUp: item.displayOrder <= 1
                            ? null
                            : () => _reorderItem(item, item.displayOrder - 1),
                        onMoveDown: () =>
                            _reorderItem(item, item.displayOrder + 1),
                        onPreview: () => _previewItem(item),
                        onPublish: () => _publishItem(item),
                        onUnpublish: () => _unpublishItem(item),
                        onSchedule: () => _scheduleItem(item),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppButton.secondary(
                      label: 'Preview Home Config',
                      icon: Icons.visibility_outlined,
                      semanticLabel: 'Preview generated Home configuration',
                      onPressed: _previewConfig,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _trackViewed() {
    if (_trackedView) return;
    _trackedView = true;
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: AppAnalyticsEvents.cmsViewed));
  }

  Future<void> _addBanner() async {
    final next = AdminHomeContentItem(
      id: 'banner-${DateTime.now().millisecondsSinceEpoch}',
      type: HomeSectionType.mainHeroBanner,
      title: 'New Banner',
      status: AdminContentStatus.draft,
      enabled: false,
      displayOrder: 99,
      media: const AdminMediaAsset(
        url: 'https://cdn.flexwolf.co/placeholders/banner.jpg',
        kind: AdminMediaKind.image,
        altText: 'New banner placeholder',
      ),
    );
    await _run(
      () => ref.read(adminHomeContentRepositoryProvider).addBanner(next),
    );
    _track(AppAnalyticsEvents.bannerUpdated);
  }

  Future<void> _editItem(AdminHomeContentItem item) async {
    final edited = await showModalBottomSheet<AdminHomeContentItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ContentEditor(item: item),
    );
    if (edited == null) return;
    await _run(
      () => ref.read(adminHomeContentRepositoryProvider).updateItem(edited),
    );
    _track(AppAnalyticsEvents.bannerUpdated);
  }

  Future<void> _deleteItem(AdminHomeContentItem item) async {
    await _run(
      () => ref.read(adminHomeContentRepositoryProvider).deleteItem(item.id),
    );
    _track(AppAnalyticsEvents.bannerUpdated);
  }

  Future<void> _toggleItem(AdminHomeContentItem item, bool enabled) async {
    await _run(
      () => ref
          .read(adminHomeContentRepositoryProvider)
          .toggleItem(item.id, enabled: enabled),
    );
    _track(AppAnalyticsEvents.bannerUpdated);
  }

  Future<void> _reorderItem(AdminHomeContentItem item, int order) async {
    await _run(
      () => ref
          .read(adminHomeContentRepositoryProvider)
          .reorderItem(item.id, order),
    );
    _track(AppAnalyticsEvents.bannerUpdated);
  }

  Future<void> _publishItem(AdminHomeContentItem item) async {
    await _run(
      () => ref.read(adminHomeContentRepositoryProvider).publish(item.id),
    );
    _track(AppAnalyticsEvents.contentPublished);
  }

  Future<void> _unpublishItem(AdminHomeContentItem item) async {
    await _run(
      () => ref.read(adminHomeContentRepositoryProvider).unpublish(item.id),
    );
    _track(AppAnalyticsEvents.contentPublished);
  }

  Future<void> _scheduleItem(AdminHomeContentItem item) async {
    final startsAt = DateTime.now().toUtc().add(const Duration(days: 1));
    await _run(
      () => ref
          .read(adminHomeContentRepositoryProvider)
          .schedule(item.id, startsAt: startsAt),
    );
    _track(AppAnalyticsEvents.contentPublished);
  }

  Future<void> _previewConfig() async {
    final json = await ref
        .read(adminHomeContentRepositoryProvider)
        .previewConfig();
    if (!mounted) return;
    _showPreview('Home Config Preview', jsonEncode(json));
  }

  void _previewItem(AdminHomeContentItem item) {
    _showPreview(
      item.title,
      const JsonEncoder.withIndent('  ').convert(item.toHomeSection().toJson()),
    );
  }

  Future<void> _run(Future<Object?> Function() action) async {
    try {
      await action();
      ref.invalidate(adminHomeContentDraftProvider);
    } catch (error) {
      if (!mounted) return;
      final appError = error is AppException
          ? error
          : mapUnknownException(error);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(appError.message)));
    }
  }

  void _showPreview(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(child: SelectableText(body)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _track(String name) {
    ref.read(analyticsGatewayProvider).track(AnalyticsEvent(name: name));
  }
}

class _ContentTypeSummary extends StatelessWidget {
  const _ContentTypeSummary({required this.items});

  final List<AdminHomeContentItem> items;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      'Hero Banner',
      'Featured Collections',
      'Promotional Cards',
      'Announcement Bar',
      'Featured Products',
      'New Arrivals',
      'Best Sellers',
      'Sale Section',
      'Video Banner',
      'Footer Content',
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final label in labels)
          Chip(
            avatar: const Icon(
              Icons.check_circle_outline,
              size: AppIconSizes.sm,
            ),
            label: Text(label),
          ),
      ],
    );
  }
}

class _ContentItemTile extends StatelessWidget {
  const _ContentItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onPreview,
    required this.onPublish,
    required this.onUnpublish,
    required this.onSchedule,
  });

  final AdminHomeContentItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onPreview;
  final VoidCallback onPublish;
  final VoidCallback onUnpublish;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.title}, ${_statusLabel(item.status)}',
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Switch(value: item.enabled, onChanged: onToggle),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${HomeSectionRegistry.definitionForType(item.type).remoteValue} / ${_statusLabel(item.status)} / Order ${item.displayOrder}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              if (item.media != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.media!.kind == AdminMediaKind.videoPlaceholder
                      ? 'Video placeholder prepared'
                      : 'Media: ${item.media!.url}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (item.collectionReferences.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Collections: ${item.collectionReferences.map((ref) => ref.handle ?? ref.id).join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  IconButton(
                    tooltip: 'Preview content item',
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined),
                  ),
                  IconButton(
                    tooltip: 'Edit content item',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Move content up',
                    onPressed: onMoveUp,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Move content down',
                    onPressed: onMoveDown,
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  IconButton(
                    tooltip: 'Schedule content',
                    onPressed: onSchedule,
                    icon: const Icon(Icons.schedule),
                  ),
                  IconButton(
                    tooltip: 'Publish content',
                    onPressed: onPublish,
                    icon: const Icon(Icons.publish_outlined),
                  ),
                  IconButton(
                    tooltip: 'Unpublish content',
                    onPressed: onUnpublish,
                    icon: const Icon(Icons.unpublished_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete content item',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentEditor extends StatefulWidget {
  const _ContentEditor({required this.item});

  final AdminHomeContentItem item;

  @override
  State<_ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<_ContentEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _body;
  late final TextEditingController _cta;
  late final TextEditingController _mediaUrl;
  late final TextEditingController _altText;
  late final TextEditingController _collectionHandles;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.item.title);
    _subtitle = TextEditingController(text: widget.item.subtitle ?? '');
    _body = TextEditingController(text: widget.item.body ?? '');
    _cta = TextEditingController(text: widget.item.ctaText ?? '');
    _mediaUrl = TextEditingController(text: widget.item.media?.url ?? '');
    _altText = TextEditingController(text: widget.item.media?.altText ?? '');
    _collectionHandles = TextEditingController(
      text: widget.item.collectionReferences
          .map((reference) => reference.handle ?? reference.id ?? '')
          .where((value) => value.isNotEmpty)
          .join(', '),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _body.dispose();
    _cta.dispose();
    _mediaUrl.dispose();
    _altText.dispose();
    _collectionHandles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                'Edit Content',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _subtitle,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),
              TextFormField(
                controller: _body,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Body'),
              ),
              TextFormField(
                controller: _cta,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'CTA text'),
              ),
              TextFormField(
                controller: _mediaUrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Media URL or video placeholder',
                ),
              ),
              TextFormField(
                controller: _altText,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Media alt text'),
              ),
              TextFormField(
                controller: _collectionHandles,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Collection handles',
                  helperText: 'Comma-separated Shopify handles only',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: 'Save Content',
                icon: Icons.save_outlined,
                semanticLabel: 'Save Home content item',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mediaUrl = _mediaUrl.text.trim();
    Navigator.of(context).pop(
      widget.item.copyWith(
        title: _title.text.trim(),
        subtitle: _optional(_subtitle.text),
        body: _optional(_body.text),
        ctaText: _optional(_cta.text),
        media: mediaUrl.isEmpty
            ? null
            : AdminMediaAsset(
                url: mediaUrl,
                kind: mediaUrl.startsWith('video-placeholder://')
                    ? AdminMediaKind.videoPlaceholder
                    : AdminMediaKind.image,
                altText: _optional(_altText.text),
              ),
        collectionReferences: _collectionHandles.text
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .map((handle) => ShopifyCollectionReference(handle: handle))
            .toList(growable: false),
      ),
    );
  }
}

class _CmsSkeleton extends StatelessWidget {
  const _CmsSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AppSkeletonLoader(height: 96),
      SizedBox(height: AppSpacing.md),
      AppSkeletonLoader(height: 96),
      SizedBox(height: AppSpacing.md),
      AppSkeletonLoader(height: 96),
    ],
  );
}

String _statusLabel(AdminContentStatus status) => switch (status) {
  AdminContentStatus.draft => 'Draft',
  AdminContentStatus.scheduled => 'Scheduled',
  AdminContentStatus.published => 'Published',
  AdminContentStatus.unpublished => 'Unpublished',
};

String? _optional(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
