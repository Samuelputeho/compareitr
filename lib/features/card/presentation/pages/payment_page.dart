import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:compareitr/core/common/entities/cart_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:compareitr/features/order/presentation/bloc/order_bloc.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/domain/entities/order_item_entity.dart';
import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/services/order_number_service.dart';
import 'package:compareitr/init_dependencies.dart';
import 'package:uuid/uuid.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final List<CartEntity> cartItems;
  final LatLng deliveryLocation;
  final String streetName;
  final String locationName;
  final String houseNumber;
  final double deliveryFee;

  const PaymentPage({
    Key? key,
    required this.totalAmount,
    required this.cartItems,
    required this.deliveryLocation,
    required this.streetName,
    required this.locationName,
    required this.houseNumber,
    required this.deliveryFee,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  void _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a payment method"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Handle different payment methods
    if (_selectedPaymentMethod == 'speedpoint') {
      // Show info message for Speedpoint Terminal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("💳 Speedpoint Terminal: Pay with card at delivery"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
      // Continue with order processing for Speedpoint
    }

    setState(() {
      _isProcessing = true;
    });

    // Get the current user
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is AppUserLoggedIn) {
      final userId = appUserState.user.id;

      // Generate UUID for database primary key
      final orderId = const Uuid().v4();
      
      // Generate custom order number for customer display (C0001, C0002, etc.)
      final orderNumberService = serviceLocator<OrderNumberService>();
      final orderNumber = await orderNumberService.generateOrderNumber();

      // Create order items from cart items
      final orderItems = widget.cartItems
          .map((item) => OrderItemEntity(
                productId: item.id,
                itemName: item.itemName,
                shopName: item.shopName,
                imageUrl: item.imageUrl,
                price: item.price,
                quantity: item.quantity,
                measure: item.measure,
              ))
          .toList();

      // Format the delivery address
      final formattedAddress =
          '${widget.houseNumber} ${widget.streetName}, ${widget.locationName}';

      // Create the order
      final order = OrderEntity(
        orderId: orderId,  // UUID for database
        orderNumber: orderNumber,  // C0001 for customer display
        userId: userId,
        items: orderItems,
        subtotal: widget.totalAmount,
        deliveryFee: widget.deliveryFee,
        totalAmount: widget.totalAmount + widget.deliveryFee,
        orderDate: DateTime.now(),
        deliveryAddress: formattedAddress,
        orderStatus: 'Pending',
        paymentMethod: _selectedPaymentMethod!,  // Pass selected payment method
      );

      // Dispatch create order event
      context.read<OrderBloc>().add(CreateOrderEvent(order));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalWithDelivery = widget.totalAmount + widget.deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Method"),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.grey[200],
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("🎉 Order placed successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isProcessing = false;
            });
          }
        },
        child: Column(
          children: [
            // Order Summary Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Subtotal', widget.totalAmount, isDarkMode),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                      'Delivery Fee', widget.deliveryFee, isDarkMode),
                  const Divider(height: 20),
                  _buildSummaryRow('Total', totalWithDelivery, isDarkMode,
                      isBold: true),
                ],
              ),
            ),

            // Payment Methods Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cash on Delivery - Active
                    _buildPaymentOption(
                      icon: Icons.payments,
                      title: 'Cash on Delivery',
                      description: 'Pay with cash when your order arrives',
                      value: 'cash',
                      isEnabled: true,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 12),

                    // Speedpoint Terminal - Active
                    _buildPaymentOption(
                      icon: Icons.point_of_sale,
                      title: 'Speedpoint Terminal',
                      description: 'Pay with card at our Speedpoint machine',
                      value: 'speedpoint',
                      isEnabled: true,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 12),

                    // Card Payment - Coming Soon
                    _buildPaymentOption(
                      icon: Icons.credit_card,
                      title: 'Card Payment',
                      description: 'Pay with Visa, Mastercard, or Debit card',
                      value: 'card',
                      isEnabled: false,
                      isDarkMode: isDarkMode,
                      comingSoon: true,
                    ),

                    const SizedBox(height: 12),

                    // Apple Pay - Coming Soon
                    _buildPaymentOption(
                      icon: Icons.apple,
                      title: 'Apple Pay',
                      description: 'Fast and secure payment with Apple Pay',
                      value: 'apple',
                      isEnabled: false,
                      isDarkMode: isDarkMode,
                      comingSoon: true,
                    ),

                    const SizedBox(height: 12),

                    // Google Pay - Coming Soon
                    _buildPaymentOption(
                      icon: Icons.account_balance_wallet,
                      title: 'Google Pay',
                      description: 'Quick checkout with Google Pay',
                      value: 'google',
                      isEnabled: false,
                      isDarkMode: isDarkMode,
                      comingSoon: true,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Confirm Order Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.green,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Confirm Order • N\$${totalWithDelivery.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isDarkMode,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        Text(
          'N\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String description,
    required String value,
    required bool isEnabled,
    required bool isDarkMode,
    bool comingSoon = false,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              setState(() {
                _selectedPaymentMethod = value;
              });
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("This payment method is coming soon! 🚀"),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled
              ? (isSelected
                  ? (isDarkMode
                      ? Colors.green.withOpacity(0.2)
                      : Colors.green.withOpacity(0.1))
                  : (isDarkMode ? Colors.grey[850] : Colors.grey[100]))
              : (isDarkMode
                  ? Colors.grey[850]?.withOpacity(0.5)
                  : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.green
                : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEnabled
                    ? (isSelected
                        ? Colors.green
                        : (isDarkMode ? Colors.grey[700] : Colors.grey[300]))
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),

            const SizedBox(width: 16),

            // Title and Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.grey,
                        ),
                      ),
                      if (comingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'COMING SOON',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled
                          ? (isDarkMode ? Colors.grey[400] : Colors.grey[600])
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Radio/Check indicator
            if (isEnabled)
              Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: isSelected ? Colors.green : Colors.grey,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
