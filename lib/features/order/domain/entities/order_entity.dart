import 'order_item_entity.dart';

class OrderEntity {
  final String orderId;  // UUID - database primary key
  final String orderNumber;  // C0001 - customer-facing order number
  final String userId;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final DateTime orderDate;
  final String deliveryAddress;
  final String orderStatus;
  final String paymentMethod;  // cash, speedpoint, card, apple_pay, google_pay
  final String? driverId;
  final String? driverName;
  final int? driverPhone;
  final String? driverProfilePic;

  const OrderEntity({
    required this.orderId,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.orderDate,
    required this.deliveryAddress,
    required this.orderStatus,
    required this.paymentMethod,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverProfilePic,
  });
}
