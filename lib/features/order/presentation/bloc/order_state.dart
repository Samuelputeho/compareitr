part of 'order_bloc.dart';

@immutable
sealed class OrderState {
  const OrderState();
}

final class OrderInitial extends OrderState {}

final class OrderLoading extends OrderState {}

final class OrderFailure extends OrderState {
  final String message;

  const OrderFailure(this.message);
}

final class OrderSuccess extends OrderState {
  const OrderSuccess();
}

final class UserOrdersLoaded extends OrderState {
  final List<OrderEntity> orders;

  const UserOrdersLoaded(this.orders);
}

final class OrderDetailsLoaded extends OrderState {
  final OrderEntity order;

  const OrderDetailsLoaded(this.order);
}
