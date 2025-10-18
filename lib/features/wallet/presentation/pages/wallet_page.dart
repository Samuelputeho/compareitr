import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/features/order/presentation/bloc/order_bloc.dart';
import 'package:compareitr/features/order/presentation/pages/order_details_page.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _orderStatuses = ['All', 'Pending', 'Processing', 'Delivered', 'Cancelled'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _orderStatuses.length, vsync: this);
    _loadUserOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserOrders() {
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is AppUserLoggedIn) {
      final userId = appUserState.user.id;
      if (userId.isNotEmpty) {
        context.read<OrderBloc>().add(GetUserOrdersEvent(userId));
      }
    }
  }

  List<OrderEntity> _filterOrders(List<OrderEntity> orders, String status) {
    if (status == 'All') return orders;
    
    // Map "Processing" tab to "out_for_delivery" database status
    if (status == 'Processing') {
      return orders.where((order) => 
        order.orderStatus.toLowerCase() == 'out_for_delivery'
      ).toList();
    }
    
    return orders.where((order) => 
      order.orderStatus.toLowerCase() == status.toLowerCase()
    ).toList();
  }
  
  // Convert database status to user-friendly display status
  String _getDisplayStatus(String dbStatus) {
    if (dbStatus.toLowerCase() == 'out_for_delivery') {
      return 'Processing';
    }
    return dbStatus;
  }
  
  // Get order number for display (uses orderNumber field, or falls back to orderId)
  String _getOrderNumber(OrderEntity order) {
    // Use orderNumber if available, otherwise use orderId (for old orders)
    return order.orderNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _orderStatuses.map((status) => Tab(text: status)).toList(),
          onTap: (index) {
            setState(() {}); // Trigger rebuild when tab changes
          },
        ),
      ),
      body: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          if (state is OrderInitial) {
            // Show loading while we fetch orders for the first time
            return Center(child: CircularProgressIndicator(color: Colors.green));
          } else if (state is OrderLoading) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          } else if (state is OrderFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is UserOrdersLoaded) {
            final orders = _filterOrders(
              state.orders,
              _orderStatuses[_tabController.index],
            );
            
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No ${_orderStatuses[_tabController.index].toLowerCase()} orders',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                _loadUserOrders();
              },
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final formattedDate = DateFormat('MMM dd, yyyy').format(order.orderDate);
                  
                  // DEBUG: Print order details
                  print('========== ORDER LIST DEBUG ==========');
                  print('Order ${index + 1}/${orders.length}');
                  print('Order ID: ${order.orderId}');
                  print('Status: ${order.orderStatus}');
                  print('Driver ID: ${order.driverId}');
                  print('Driver Name: ${order.driverName}');
                  print('Driver Phone: ${order.driverPhone}');
                  print('Driver Profile Pic: ${order.driverProfilePic}');
                  print('=====================================');
                  
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsPage(order: order),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          'Order #${_getOrderNumber(order)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.orderStatus).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getDisplayStatus(order.orderStatus).toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(order.orderStatus),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (order.items.isNotEmpty) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Items:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (order.items.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              order.items.first.imageUrl,
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image_not_supported),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  order.items.first.itemName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  order.items.first.shopName,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${order.items.first.measure.isNotEmpty ? order.items.first.measure : "Unit"} × ${order.items.first.quantity} - N\$${order.items.first.price.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (order.items.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Text(
                                          '+ ${order.items.length - 1} more items',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 8),
                                Text(formattedDate),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.shopping_bag_outlined, size: 16),
                                const SizedBox(width: 8),
                                Text('${order.items.length} items'),
                                const Spacer(),
                                Text(
                                  'N\$${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    order.deliveryAddress,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Fee:',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'N\$${order.deliveryFee.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            // Driver assigned indicator
                            if (order.orderStatus == 'out_for_delivery' && order.driverName != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.delivery_dining, color: Colors.green.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Driver: ${order.driverName}',
                                            style: TextStyle(
                                              color: Colors.green.shade900,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            'Tap to view details & contact',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, color: Colors.green.shade700, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          
          return const Center(
            child: Text(
              'No orders found',
              style: TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
      case 'out_for_delivery':  // Map out_for_delivery to blue (Processing color)
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'cancel':  // Handle both "cancel" and "cancelled"
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
