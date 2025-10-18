import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/domain/entities/order_item_entity.dart';

class OrderModel extends OrderEntity {
  OrderModel({
    required super.orderId,
    required super.orderNumber,
    required super.userId,
    required super.items,
    required super.subtotal,
    required super.deliveryFee,
    required super.totalAmount,
    required super.orderDate,
    required super.deliveryAddress,
    required super.orderStatus,
    required super.paymentMethod,
    super.driverId,
    super.driverName,
    super.driverPhone,
    super.driverProfilePic,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] ?? '',
      orderNumber: json['order_number'] ?? json['order_id'] ?? '',  // Fallback to order_id for old orders
      userId: json['user_id'] ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItemEntity(
                    productId: item['product_id'] ?? '',
                    itemName: item['item_name'] ?? '',
                    shopName: item['shop_name'] ?? '',
                    imageUrl: item['image_url'] ?? '',
                    price: (item['price'] as num?)?.toDouble() ?? 0.0,
                    quantity: item['quantity'] ?? 0,
                    measure: item['measure'] ?? '',
                  ))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      orderDate: DateTime.tryParse(json['order_date'] ?? '') ?? DateTime.now(),
      deliveryAddress: json['delivery_address'] ?? '',
      orderStatus: json['order_status'] ?? '',
      paymentMethod: json['payment_method'] ?? 'cash',  // Default to cash for backward compatibility
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      driverProfilePic: json['driver_profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'order_id': orderId,  // UUID for database
      'order_number': orderNumber,  // C0001 for display
      'user_id': userId,
      'items': items
          .map((e) => {
                'product_id': e.productId,
                'item_name': e.itemName,
                'shop_name': e.shopName,
                'image_url': e.imageUrl,
                'price': e.price,
                'quantity': e.quantity,
                'measure': e.measure,
              })
          .toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total_amount': totalAmount,
      'order_date': orderDate.toIso8601String(),
      'delivery_address': deliveryAddress,
      'order_status': orderStatus,
      'payment_method': paymentMethod,
    };
    
    // Only include driver fields if they are not null (when driver accepts order)
    if (driverId != null) json['driver_id'] = driverId!;
    if (driverName != null) json['driver_name'] = driverName!;
    if (driverPhone != null) json['driver_phone'] = driverPhone!;
    if (driverProfilePic != null) json['driver_profile_pic'] = driverProfilePic!;
    
    return json;
  }
}
