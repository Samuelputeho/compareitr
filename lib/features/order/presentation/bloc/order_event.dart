part of 'order_bloc.dart';

@immutable
sealed class OrderEvent {}

final class CreateOrderEvent extends OrderEvent {
  final OrderEntity order;

  CreateOrderEvent(this.order);
}

final class GetUserOrdersEvent extends OrderEvent {
  final String userId;

  GetUserOrdersEvent(this.userId);
}

final class GetOrderByIdEvent extends OrderEvent {
  final String orderId;

  GetOrderByIdEvent(this.orderId);
}

final class CancelOrderEvent extends OrderEvent {
  final String orderId;

  CancelOrderEvent(this.orderId);
}

final class UpdateOrderStatusEvent extends OrderEvent {
  final String orderId;
  final String status;

  UpdateOrderStatusEvent({
    required this.orderId,
    required this.status,
  });
}
