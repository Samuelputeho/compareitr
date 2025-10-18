import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/data/datasources/order_remote_data_source.dart';
import 'package:compareitr/features/delivery_config/presentation/bloc/delivery_config_bloc.dart';
import 'package:compareitr/features/delivery_config/presentation/bloc/delivery_config_event.dart';
import 'package:compareitr/features/delivery_config/presentation/bloc/delivery_config_state.dart';
import 'package:compareitr/init_dependencies.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderEntity order;

  const OrderDetailsPage({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrderEntity _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  // Convert database status to user-friendly display status
  String _getDisplayStatus(String dbStatus) {
    if (dbStatus.toLowerCase() == 'out_for_delivery') {
      return 'Processing';
    }
    return dbStatus;
  }
  
  // Get order number for display
  String _getOrderNumber(OrderEntity order) {
    return order.orderNumber;
  }
  
  // Format phone number to include +264 prefix
  String _formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return 'N/A';
    
    // Remove any existing +264 prefix to avoid duplication
    String cleanNumber = phoneNumber.replaceAll('+264', '');
    
    // Add +264 prefix if not already present
    if (!cleanNumber.startsWith('+264')) {
      cleanNumber = '+264$cleanNumber';
    }
    
    return cleanNumber;
  }
  
  // Launch phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        // Fallback: show error message
        print('Could not launch phone call to $phoneNumber');
      }
    } catch (e) {
      print('Error making phone call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderDataSource = serviceLocator<OrderRemoteDataSource>();
    final deliveryConfigBloc = serviceLocator<DeliveryConfigBloc>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_getOrderNumber(widget.order)}'),
      ),
      body: BlocProvider(
        create: (context) => deliveryConfigBloc..add(const LoadDeliveryConfig()),
        child: BlocBuilder<DeliveryConfigBloc, DeliveryConfigState>(
          builder: (context, configState) {
            // Get delivery time from config or use default
            final deliveryTimeMinutes = configState is DeliveryConfigLoaded 
                ? configState.config.deliveryTimeMinutes 
                : 90;
            
            return StreamBuilder<OrderEntity>(
              stream: orderDataSource.listenToOrderUpdates(widget.order.orderId),
              initialData: widget.order,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          }
          
          final currentOrder = snapshot.data!;
          final formattedDate = DateFormat('MMM dd, yyyy HH:mm').format(currentOrder.orderDate);
          
          // Update current order
          if (currentOrder != _currentOrder) {
            _currentOrder = currentOrder;
          }
          
          // DEBUG LOGS
          print('========== ORDER DEBUG INFO ==========');
          print('Order ID: ${currentOrder.orderId}');
          print('Order Status: ${currentOrder.orderStatus}');
          print('Driver ID: ${currentOrder.driverId}');
          print('Driver Name: ${currentOrder.driverName}');
          print('Driver Phone: ${currentOrder.driverPhone}');
          print('Driver Profile Pic: ${currentOrder.driverProfilePic}');
          print('Has Driver Info: ${currentOrder.driverName != null}');
          print('Should Show Driver Card: ${currentOrder.orderStatus == 'out_for_delivery' && currentOrder.driverName != null}');
          print('Delivery Time Minutes: $deliveryTimeMinutes');
          print('======================================');
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? null 
                                : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Order Number: ${_getOrderNumber(currentOrder)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Date: $formattedDate'),
                        Text('Status: ${_getDisplayStatus(currentOrder.orderStatus).toUpperCase()}'),
                        Text('Delivery Address: ${currentOrder.deliveryAddress}'),
                      ],
                    ),
                  ),
                ),
                // Driver Information Card - Shows when order is accepted
                if (currentOrder.orderStatus == 'out_for_delivery' && currentOrder.driverName != null)
                  const SizedBox(height: 16),
                if (currentOrder.orderStatus == 'out_for_delivery' && currentOrder.driverName != null)
                  Card(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.green.shade900.withOpacity(0.3)
                        : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver Information',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green.shade300
                                  : Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Driver Profile Picture
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[700]
                                    : Colors.grey[300],
                                backgroundImage: currentOrder.driverProfilePic != null && currentOrder.driverProfilePic!.isNotEmpty
                                    ? NetworkImage(currentOrder.driverProfilePic!)
                                    : null,
                                child: currentOrder.driverProfilePic == null || currentOrder.driverProfilePic!.isEmpty
                                    ? Icon(Icons.person, size: 40, color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey[400]
                                        : Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentOrder.driverName ?? 'Driver',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 16, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatPhoneNumber(currentOrder.driverPhone?.toString()),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Call Button
                              IconButton(
                                onPressed: () {
                                  final formattedPhone = _formatPhoneNumber(currentOrder.driverPhone?.toString());
                                  if (formattedPhone != 'N/A') {
                                    _makePhoneCall(formattedPhone);
                                  }
                                },
                                icon: const Icon(Icons.phone, color: Colors.green),
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.green.shade800.withOpacity(0.5)
                                      : Colors.green.shade100,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.green.shade800.withOpacity(0.3)
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_shipping, 
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.green.shade300
                                      : Colors.green.shade900,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your order is on the way!',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.green.shade300
                                          : Colors.green.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Delivery Time Countdown
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.blue.shade900.withOpacity(0.3)
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade700
                                    : Colors.blue.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.blue.shade300
                                          : Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Estimated Arrival',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Driver will arrive in $deliveryTimeMinutes minutes',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.blue.shade200
                                        : Colors.blue.shade800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? null 
                                : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...currentOrder.items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isLastItem = index == currentOrder.items.length - 1;
                          
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: HiveImageWidget(
                                        imageUrl: item.imageUrl,
                                        hiveKey: 'orderImage_${item.itemName.hashCode}',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorWidget: Container(
                                          width: 60,
                                          height: 60,
                                          color: Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.grey[700]
                                              : Colors.grey[200],
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Theme.of(context).brightness == Brightness.dark 
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.itemName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text('Shop: ${item.shopName}'),
                                          Text('${item.measure.isNotEmpty ? item.measure : "Unit"} × ${item.quantity}'),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'N\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLastItem) const Divider(),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? null 
                                : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('N\$${currentOrder.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee:'),
                            Text('N\$${currentOrder.deliveryFee.toStringAsFixed(2)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'N\$${currentOrder.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
            );
          },
        ),
      ),
    );
  }
}
