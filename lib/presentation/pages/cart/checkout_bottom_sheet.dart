import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:e_commerce_shopping_app/core/constants/app_constants.dart';
import 'package:e_commerce_shopping_app/core/theme/app_colors.dart';
import 'package:e_commerce_shopping_app/domain/entities/cart_order_entities.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/auth/auth_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_cubit.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/cart/cart_state.dart';
import 'package:e_commerce_shopping_app/presentation/cubits/product/product_cubit.dart';

final NumberFormat _checkoutCurrency = NumberFormat.simpleCurrency(
  name: 'USD',
  decimalDigits: 2,
);

/// Stitch Screen 5 Modal — Simulated Checkout Bottom Sheet (Shipping + COD/Card Payment).
class CheckoutBottomSheet extends StatefulWidget {
  final double grandTotal;
  final ValueChanged<OrderEntity> onOrderConfirmed;

  const CheckoutBottomSheet({
    super.key,
    required this.grandTotal,
    required this.onOrderConfirmed,
  });

  static Future<void> show(
    BuildContext context, {
    required double grandTotal,
    required ValueChanged<OrderEntity> onOrderConfirmed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CheckoutBottomSheet(
        grandTotal: grandTotal,
        onOrderConfirmed: onOrderConfirmed,
      ),
    );
  }

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();

  // Simulated Credit/Debit Card UI controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  String _selectedPaymentMethod = AppConstants.paymentCreditDebitCard;

  @override
  void initState() {
    super.initState();
    final userName = context.read<AuthCubit>().currentUser?.name ?? '';
    _fullNameController = TextEditingController(text: userName);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  bool get _isCardSelected =>
      _selectedPaymentMethod == AppConstants.paymentCreditDebitCard;

  Future<void> _submitOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final uid = context.read<AuthCubit>().currentUser?.uid;
    final address = ShippingAddressEntity(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
    );

    final order = await context.read<CartCubit>().checkoutOrder(
      shippingAddress: address,
      paymentMethod: _selectedPaymentMethod,
      uid: uid,
    );

    if (!mounted) return;
    if (order != null) {
      context.read<ProductCubit>().loadAndRefreshRecommendations(uid);
      Navigator.of(context).pop();
      widget.onOrderConfirmed(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final isSubmitting =
                  cartState is CartLoaded && cartState.isCheckingOut;

              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Modal Header
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_cart_checkout_rounded,
                              size: 20,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order & Delivery Details',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                Text(
                                  'Simulated Checkout & Cloud Order Sync',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Section 1: Shipping Address
                      Text(
                        '1. SHIPPING ADDRESS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Alex Rivera',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (val) => (val?.trim().isEmpty ?? true)
                            ? 'Full name is required.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+1 (555) 234-8901',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                        validator: (val) => (val?.trim().length ?? 0) < 6
                            ? 'Enter a valid phone number.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _streetController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Street Address',
                          hintText: '742 Evergreen Terrace',
                          prefixIcon: Icon(Icons.home_outlined, size: 20),
                        ),
                        validator: (val) => (val?.trim().isEmpty ?? true)
                            ? 'Street address is required.'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        enabled: !isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          hintText: 'Cairo / New York',
                          prefixIcon: Icon(
                            Icons.location_city_outlined,
                            size: 20,
                          ),
                        ),
                        validator: (val) => (val?.trim().isEmpty ?? true)
                            ? 'City is required.'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Payment Method Selector
                      Text(
                        '2. PAYMENT METHOD',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Option 1: Cash on Delivery
                      _PaymentOptionTile(
                        title: 'Cash on Delivery (COD)',
                        subtitle: 'Pay with cash upon doorstep delivery',
                        icon: Icons.payments_outlined,
                        isSelected:
                            _selectedPaymentMethod ==
                            AppConstants.paymentCashOnDelivery,
                        onTap: isSubmitting
                            ? null
                            : () => setState(
                                () => _selectedPaymentMethod =
                                    AppConstants.paymentCashOnDelivery,
                              ),
                      ),
                      const SizedBox(height: 10),

                      // Option 2: Simulated Credit / Debit Card
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isCardSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.4,
                                  ),
                            width: _isCardSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            _PaymentOptionTile(
                              title: 'Credit / Debit Card',
                              subtitle: 'Simulated secure card entry (no real charge)',
                              icon: Icons.credit_card_rounded,
                              badge: 'INSTANT',
                              isSelected: _isCardSelected,
                              transparentBackground: true,
                              onTap: isSubmitting
                                  ? null
                                  : () => setState(
                                      () => _selectedPaymentMethod =
                                          AppConstants.paymentCreditDebitCard,
                                    ),
                            ),
                            if (_isCardSelected)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  12,
                                ),
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _cardNumberController,
                                      keyboardType: TextInputType.number,
                                      enabled: !isSubmitting,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(16),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Card Number (Simulated)',
                                        hintText: '4242 4242 4242 4242',
                                        fillColor:
                                            colorScheme.surfaceContainerLowest,
                                        prefixIcon: const Icon(
                                          Icons.credit_card_rounded,
                                          size: 20,
                                        ),
                                      ),
                                      validator: (val) {
                                        if (!_isCardSelected) return null;
                                        if ((val?.trim().length ?? 0) < 12) {
                                          return 'Enter 12–16 card digits.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _expiryController,
                                            keyboardType:
                                                TextInputType.datetime,
                                            enabled: !isSubmitting,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                5,
                                              ),
                                            ],
                                            decoration: InputDecoration(
                                              labelText: 'Expiry (MM/YY)',
                                              hintText: '08/28',
                                              fillColor: colorScheme
                                                  .surfaceContainerLowest,
                                            ),
                                            validator: (val) {
                                              if (!_isCardSelected) return null;
                                              if ((val?.trim().length ?? 0) <
                                                  4) {
                                                return 'MM/YY';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _cvcController,
                                            obscureText: true,
                                            keyboardType: TextInputType.number,
                                            enabled: !isSubmitting,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                4,
                                              ),
                                            ],
                                            decoration: InputDecoration(
                                              labelText: 'CVC',
                                              hintText: '424',
                                              fillColor: colorScheme
                                                  .surfaceContainerLowest,
                                            ),
                                            validator: (val) {
                                              if (!_isCardSelected) return null;
                                              if ((val?.trim().length ?? 0) <
                                                  3) {
                                                return '3–4 digits';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sync Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 20,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hive local cache & Firestore cloud sync',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                  Text(
                                    'Saves securely to users/{uid}/orders & clears cart',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Place Order CTA
                      ElevatedButton(
                        onPressed: isSubmitting ? null : _submitOrder,
                        child: isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Syncing Order to Firestore...'),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 19,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Place Order (${_checkoutCurrency.format(widget.grandTotal)})',
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final bool isSelected;
  final bool transparentBackground;
  final VoidCallback? onTap;

  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
    required this.isSelected,
    this.transparentBackground = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: transparentBackground
          ? Colors.transparent
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: transparentBackground
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stitch Order Confirmation Dialog shown right after successful checkout.
class OrderConfirmationDialog extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onContinueShopping;

  const OrderConfirmationDialog({
    super.key,
    required this.order,
    required this.onContinueShopping,
  });

  static Future<void> show(
    BuildContext context, {
    required OrderEntity order,
    required VoidCallback onContinueShopping,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => OrderConfirmationDialog(
        order: order,
        onContinueShopping: () {
          Navigator.of(dialogContext).pop();
          onContinueShopping();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shortId = order.orderId.length >= 8
        ? order.orderId.substring(0, 8).toUpperCase()
        : order.orderId.toUpperCase();

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Order Confirmed!',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your order of ${_checkoutCurrency.format(order.totalAmount)} has been saved to Hive & Cloud Firestore.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _ConfirmMetaRow(label: 'Order ID', value: '#ORD-$shortId'),
                  const SizedBox(height: 6),
                  _ConfirmMetaRow(label: 'Payment', value: order.paymentMethod),
                  const SizedBox(height: 6),
                  _ConfirmMetaRow(
                    label: 'Status',
                    value: order.status,
                    valueColor: AppColors.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onContinueShopping,
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmMetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ConfirmMetaRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: valueColor ?? theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
