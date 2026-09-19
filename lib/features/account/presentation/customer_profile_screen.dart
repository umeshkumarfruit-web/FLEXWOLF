import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_network_status_banner.dart';
import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/account/presentation/order_history_screen.dart';
import 'package:flexwolf/features/notifications/presentation/notification_settings_tile.dart';
import 'package:flexwolf/features/returns/data/returns_providers.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';
import 'package:flexwolf/features/support/presentation/support_screen.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({
    required this.session,
    required this.onLogout,
    super.key,
  });

  final CustomerSession session;
  final Future<void> Function() onLogout;

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _loadingProfile = false;
  bool _offline = false;
  CustomerProfile? _profile;
  List<CustomerAddress> _addresses = const <CustomerAddress>[];
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _load(trackView: true);
  }

  Future<void> _load({bool trackView = false}) async {
    if (_loadingProfile) return;
    _loadingProfile = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final connectivity = await ref
          .read(connectivityServiceProvider)
          .current();
      _offline = connectivity.quality == ConnectivityQuality.offline;
      if (_offline) {
        throw const AppException(
          kind: AppErrorKind.network,
          message: 'You are offline. Profile data cannot refresh right now.',
          code: 'customer_profile_offline',
          isRetryable: true,
        );
      }
      final repository = ref.read(customerAccountRepositoryProvider);
      _profile = await repository.fetchProfile();
      _addresses = await repository.fetchAddresses();
      if (trackView) _track(AppAnalyticsEvents.profileViewed);
    } catch (error) {
      _error = error is AppException ? error : mapUnknownException(error);
    } finally {
      _loadingProfile = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile(CustomerProfileInput input) async {
    await _runSave(() async {
      _profile = await ref
          .read(customerAccountRepositoryProvider)
          .updateProfile(input);
    });
  }

  Future<void> _addAddress(CustomerAddressInput input) async {
    await _runSave(() async {
      await ref.read(customerAccountRepositoryProvider).addAddress(input);
      _track(AppAnalyticsEvents.addressAdded);
      await _load();
    });
  }

  Future<void> _updateAddress(String id, CustomerAddressInput input) async {
    await _runSave(() async {
      await ref
          .read(customerAccountRepositoryProvider)
          .updateAddress(id, input);
      _track(AppAnalyticsEvents.addressUpdated);
      await _load();
    });
  }

  Future<void> _deleteAddress(String id) async {
    await _runSave(() async {
      await ref.read(customerAccountRepositoryProvider).deleteAddress(id);
      _track(AppAnalyticsEvents.addressDeleted);
      await _load();
    });
  }

  Future<void> _setDefaultShipping(String id) async {
    await _runSave(
      () => ref
          .read(customerAccountRepositoryProvider)
          .setDefaultShippingAddress(id),
    );
  }

  Future<void> _setDefaultBilling(String id) async {
    await _runSave(
      () => ref
          .read(customerAccountRepositoryProvider)
          .setDefaultBillingAddress(id),
    );
  }

  Future<void> _runSave(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      _error = error is AppException ? error : mapUnknownException(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _track(String name) {
    ref.read(analyticsGatewayProvider).track(AnalyticsEvent(name: name));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Semantics(
          label: 'Loading customer profile',
          liveRegion: true,
          child: AppSkeletonLoader(width: 240, height: 180),
        ),
      );
    }

    return Semantics(
      label: 'Customer profile and addresses',
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Account',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                ),
                IconButton(
                  tooltip: 'Refresh profile',
                  onPressed: _saving ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_offline) ...[
              AppNetworkStatusBanner(
                message: 'You are offline. Profile changes are unavailable.',
                status: AppNetworkStatus.offline,
                actionLabel: 'Retry',
                onAction: _load,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _offline
                    ? AppOfflineState(onRetry: _load)
                    : AppErrorState(error: _error!, onRetry: _load),
              ),
            if (_profile == null)
              const AppEmptyState(
                title: 'Profile unavailable',
                message:
                    'We could not load your details. Pull down to try again.',
                icon: Icons.manage_accounts_outlined,
              )
            else ...[
              _ProfileSummary(
                profile: _profile!,
                onEdit: () => _showProfileEditor(_profile!),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _AddressSection(
              addresses: _addresses,
              defaultAddress: _profile?.defaultAddress,
              defaultBillingAddress:
                  _profile?.defaultBillingAddress ?? _profile?.defaultAddress,
              saving: _saving,
              onAdd: _showAddressCreator,
              onEdit: _showAddressEditor,
              onDelete: _deleteAddress,
              onDefaultShipping: _setDefaultShipping,
              onDefaultBilling: _setDefaultBilling,
            ),
            const SizedBox(height: AppSpacing.lg),
            _AccountExperienceActions(
              onOrders: _scrollToOrders,
              onReturns: _showReturns,
              onReviews: _showReviewsDependency,
              onHelpCenter: _showHelpCenter,
              onSupport: _openSupport,
            ),
            const SizedBox(height: AppSpacing.lg),
            const OrderHistoryScreen(embedded: true),
            const SizedBox(height: AppSpacing.lg),
            _AccountSettings(
              session: widget.session,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToOrders() {
    _track(AppAnalyticsEvents.ordersViewed);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: OrderHistoryScreen(embedded: true),
        ),
      ),
    );
  }

  void _showReturns() {
    _track(AppAnalyticsEvents.returnOpened);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ReturnsStatusSheet(),
    );
  }

  void _showReviewsDependency() {
    _track(AppAnalyticsEvents.reviewOpened);
    _showInfo(
      'My Reviews',
      'CLIENT DEPENDENCY: Customer review history requires the review provider account endpoint or a secure backend proxy.',
    );
  }

  void _showHelpCenter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SupportScreen(),
    );
  }

  void _openSupport() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SupportScreen(),
    );
  }

  void _showInfo(String title, String message) {
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

  void _showProfileEditor(CustomerProfile profile) {
    final firstName = TextEditingController(text: profile.firstName ?? '');
    final lastName = TextEditingController(text: profile.lastName ?? '');
    final phone = TextEditingController(text: profile.phone ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProfileEditor(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        onSave: (input) async {
          Navigator.of(context).pop();
          await _saveProfile(input);
        },
      ),
    );
  }

  void _showAddressCreator() => _showAddressEditor(null);

  void _showAddressEditor(CustomerAddress? address) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddressEditor(
        address: address,
        onSave: (input) async {
          Navigator.of(context).pop();
          if (address == null) {
            await _addAddress(input);
          } else {
            await _updateAddress(address.id, input);
          }
        },
      ),
    );
  }
}

class _AccountExperienceActions extends StatelessWidget {
  const _AccountExperienceActions({
    required this.onOrders,
    required this.onReturns,
    required this.onReviews,
    required this.onHelpCenter,
    required this.onSupport,
  });

  final VoidCallback onOrders;
  final VoidCallback onReturns;
  final VoidCallback onReviews;
  final VoidCallback onHelpCenter;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _SectionTitle(title: 'Account Help'),
      AppButton.secondary(
        label: 'My Orders',
        icon: Icons.receipt_long_outlined,
        semanticLabel: 'View my orders',
        onPressed: onOrders,
      ),
      AppButton.secondary(
        label: 'My Returns',
        icon: Icons.assignment_return_outlined,
        semanticLabel: 'View my returns and exchanges',
        onPressed: onReturns,
      ),
      AppButton.secondary(
        label: 'My Reviews',
        icon: Icons.rate_review_outlined,
        semanticLabel: 'View my reviews',
        onPressed: onReviews,
      ),
      AppButton.secondary(
        label: 'Help Center',
        icon: Icons.help_outline,
        semanticLabel: 'Open help center',
        onPressed: onHelpCenter,
      ),
      AppButton.primary(
        label: 'Contact Support',
        icon: Icons.support_agent,
        semanticLabel: 'Contact customer support',
        onPressed: onSupport,
      ),
    ],
  );
}

class _ReturnsStatusSheet extends ConsumerWidget {
  const _ReturnsStatusSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_returnsHistoryProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Semantics(
          label: 'My returns status',
          explicitChildNodes: true,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('My Returns', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              history.when(
                loading: () => const AppSkeletonLoader(height: 120),
                error: (error, stackTrace) => AppErrorState(
                  error: error is AppException
                      ? error
                      : mapUnknownException(error),
                  onRetry: () => ref.invalidate(_returnsHistoryProvider),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return const AppEmptyState(
                      title: 'No returns yet',
                      message: 'Return and exchange requests will appear here after submission.',
                      icon: Icons.assignment_return_outlined,
                    );
                  }
                  return Column(
                    children: [
                      for (final record in records)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            record.flowType == ReturnFlowType.exchange
                                ? Icons.swap_horiz
                                : Icons.assignment_return_outlined,
                          ),
                          title: Text(record.lineItemTitle),
                          subtitle: Text(
                            '${record.reasonLabel} / ${record.status.name}',
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _returnsHistoryProvider =
    FutureProvider.autoDispose<List<ReturnExchangeRecord>>(
      (ref) => ref.watch(returnsRepositoryProvider).fetchHistory(),
    );

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile, required this.onEdit});
  final CustomerProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name =
        profile.displayName ??
        '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: name.isEmpty ? 'Customer' : name,
          actionLabel: 'Edit',
          onAction: onEdit,
        ),
        _InfoRow(label: 'Email', value: profile.email ?? 'Not available'),
        _InfoRow(label: 'Phone', value: profile.phone ?? 'Not available'),
        _InfoRow(label: 'Account status', value: profile.accountStatus.name),
        _InfoRow(
          label: 'Default shipping',
          value: _addressLine(profile.defaultAddress),
        ),
        _InfoRow(
          label: 'Default billing',
          value: _addressLine(
            profile.defaultBillingAddress ?? profile.defaultAddress,
          ),
        ),
      ],
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.addresses,
    required this.defaultAddress,
    required this.defaultBillingAddress,
    required this.saving,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onDefaultShipping,
    required this.onDefaultBilling,
  });
  final List<CustomerAddress> addresses;
  final CustomerAddress? defaultAddress;
  final CustomerAddress? defaultBillingAddress;
  final bool saving;
  final VoidCallback onAdd;
  final ValueChanged<CustomerAddress?> onEdit;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onDefaultShipping;
  final ValueChanged<String> onDefaultBilling;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Addresses',
          actionLabel: 'Add',
          onAction: saving ? null : onAdd,
        ),
        if (addresses.isEmpty)
          const AppEmptyState(
            title: 'No saved addresses',
            message: 'Add a shipping address when Customer Account writes are enabled.',
            icon: Icons.location_off_outlined,
          )
        else
          for (final address in addresses)
            ListTile(
              minVerticalPadding: AppSpacing.sm,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: Text(_addressLine(address)),
              subtitle: Text(
                _addressFlags(address, defaultAddress, defaultBillingAddress),
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Address actions',
                onSelected: (value) {
                  if (value == 'edit') onEdit(address);
                  if (value == 'delete') onDelete(address.id);
                  if (value == 'shipping') onDefaultShipping(address.id);
                  if (value == 'billing') onDefaultBilling(address.id);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'shipping',
                    child: Text('Set default shipping'),
                  ),
                  PopupMenuItem(
                    value: 'billing',
                    child: Text('Set default billing'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
      ],
    );
  }
}

class _AccountSettings extends StatelessWidget {
  const _AccountSettings({required this.session, required this.onLogout});
  final CustomerSession session;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: 'Settings'),
        const NotificationSettingsTile(),
        _InfoRow(
          label: 'Session expires',
          value: session.expiresAt.toLocal().toString(),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.verified_user_outlined),
          title: Text('Secure email sign-in'),
          subtitle: Text(
            'Use a one-time code sent to your email. No password needed.',
          ),
        ),
        AppButton.text(
          label: 'Privacy',
          icon: Icons.privacy_tip_outlined,
          onPressed: () {},
        ),
        AppButton.text(
          label: 'Terms',
          icon: Icons.description_outlined,
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton.secondary(
          label: 'Logout',
          icon: Icons.logout,
          semanticLabel: 'Logout of customer account',
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _ProfileEditor extends StatelessWidget {
  const _ProfileEditor({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.onSave,
  });
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController phone;
  final ValueChanged<CustomerProfileInput> onSave;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
            TextFormField(
              controller: firstName,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: _required,
            ),
            TextFormField(
              controller: lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: _required,
            ),
            TextFormField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Save changes',
              icon: Icons.save_outlined,
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                onSave(
                  CustomerProfileInput(
                    firstName: firstName.text,
                    lastName: lastName.text,
                    phone: phone.text.trim().isEmpty ? null : phone.text,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressEditor extends StatelessWidget {
  _AddressEditor({required this.address, required this.onSave});
  final CustomerAddress? address;
  final ValueChanged<CustomerAddressInput> onSave;
  final _formKey = GlobalKey<FormState>();

  late final firstName = TextEditingController(text: address?.firstName ?? '');
  late final lastName = TextEditingController(text: address?.lastName ?? '');
  late final address1 = TextEditingController(text: address?.address1 ?? '');
  late final address2 = TextEditingController(text: address?.address2 ?? '');
  late final city = TextEditingController(text: address?.city ?? '');
  late final province = TextEditingController(text: address?.province ?? '');
  late final country = TextEditingController(text: address?.country ?? '');
  late final zip = TextEditingController(text: address?.zip ?? '');
  late final phone = TextEditingController(text: address?.phone ?? '');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                address == null ? 'Add address' : 'Edit address',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextFormField(
                controller: firstName,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: _required,
              ),
              TextFormField(
                controller: lastName,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: _required,
              ),
              TextFormField(
                controller: address1,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: _required,
              ),
              TextFormField(
                controller: address2,
                decoration: const InputDecoration(
                  labelText: 'Apartment, suite, etc.',
                ),
              ),
              TextFormField(
                controller: city,
                decoration: const InputDecoration(labelText: 'City'),
                validator: _required,
              ),
              TextFormField(
                controller: province,
                decoration: const InputDecoration(
                  labelText: 'State or province',
                ),
              ),
              TextFormField(
                controller: country,
                decoration: const InputDecoration(labelText: 'Country'),
                validator: _required,
              ),
              TextFormField(
                controller: zip,
                decoration: const InputDecoration(
                  labelText: 'ZIP or postal code',
                ),
                validator: _required,
              ),
              TextFormField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                label: 'Save address',
                icon: Icons.save_outlined,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    onSave(
      CustomerAddressInput(
        firstName: firstName.text,
        lastName: lastName.text,
        address1: address1.text,
        address2: _optional(address2.text),
        city: city.text,
        province: _optional(province.text),
        country: country.text,
        zip: zip.text,
        phone: _optional(phone.text),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
      if (actionLabel != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Semantics(
      label: '$label: $value',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    ),
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;
String? _optional(String value) => value.trim().isEmpty ? null : value.trim();
String _addressLine(CustomerAddress? address) {
  if (address == null) return 'Not available';
  return [
    address.address1,
    address.address2,
    address.city,
    address.province,
    address.country,
    address.zip,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
}

String _addressFlags(
  CustomerAddress address,
  CustomerAddress? shipping,
  CustomerAddress? billing,
) {
  final flags = <String>[];
  if (address.isDefaultShipping || address.id == shipping?.id) {
    flags.add('Default shipping');
  }
  if (address.isDefaultBilling || address.id == billing?.id) {
    flags.add('Default billing');
  }
  return flags.isEmpty ? 'Saved address' : flags.join(' / ');
}
