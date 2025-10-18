import 'package:bloc/bloc.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/domain/usecases/cancel_oder.dart';
import 'package:compareitr/features/order/domain/usecases/create_order.dart';
import 'package:compareitr/features/order/domain/usecases/get_user_order.dart';
import 'package:compareitr/features/order/domain/usecases/get_order_by_id.dart';
import 'package:compareitr/features/order/domain/usecases/update_order_status.dart';
import 'package:compareitr/features/order/data/models/order_model.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrder createOrder;
  final GetUserOrders getUserOrders;
  final GetOrderById getOrderById;
  final CancelOrder cancelOrder;
  final UpdateOrderStatus updateOrderStatus;

  OrderBloc({
    required this.createOrder,
    required this.getUserOrders,
    required this.getOrderById,
    required this.cancelOrder,
    required this.updateOrderStatus,
  }) : super(OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<GetUserOrdersEvent>(_onGetUserOrders);
    on<GetOrderByIdEvent>(_onGetOrderById);
    on<CancelOrderEvent>(_onCancelOrder);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
  }

  void _onCreateOrder(CreateOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final res = await createOrder(CreateOrderParams(order: event.order));

    res.fold(
      (failure) => emit(OrderFailure(failure.message)),
      (_) => emit(const OrderSuccess()),
    );
  }

  void _onGetUserOrders(GetUserOrdersEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    
    // First, check for cached orders in Hive
    final box = Hive.box('recently_viewed');
    final cacheKey = 'orders_${event.userId}';
    final cachedData = box.get(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 OrderBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedOrders = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 OrderBloc: Parsing cached order: ${itemData['order_id']}');
        return OrderModel.fromJson(itemData);
      }).toList();
      
      if (cachedOrders.isNotEmpty) {
        print('✅ OrderBloc: Using cached orders (${cachedOrders.length} orders)');
        print('🔍 OrderBloc: First order: ${cachedOrders.first.orderId} - ${cachedOrders.first.orderStatus}');
        emit(UserOrdersLoaded(cachedOrders));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, continue to fetch fresh data below
      }
    }
    
    final res = await getUserOrders(GetUserOrdersParams(userId: event.userId));

    res.fold(
      (failure) {
        // If server error, try to use cached data as fallback
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedOrders = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return OrderModel.fromJson(itemData);
          }).toList();
          
          if (cachedOrders.isNotEmpty) {
            print('✅ OrderBloc: Server error, using cached orders (${cachedOrders.length} orders)');
            emit(UserOrdersLoaded(cachedOrders));
            return;
          }
        }
        
        emit(OrderFailure(failure.message));
      },
      (orders) => emit(UserOrdersLoaded(orders)),
    );
  }

  void _onGetOrderById(GetOrderByIdEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final res = await getOrderById(GetOrderByIdParams(orderId: event.orderId));

    res.fold(
      (failure) => emit(OrderFailure(failure.message)),
      (order) => emit(OrderDetailsLoaded(order)),
    );
  }

  void _onCancelOrder(CancelOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final res = await cancelOrder(CancelOrderParams(orderId: event.orderId));

    res.fold(
      (failure) => emit(OrderFailure(failure.message)),
      (_) => emit(const OrderSuccess()),
    );
  }

  void _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    final res = await updateOrderStatus(UpdateOrderStatusParams(
      orderId: event.orderId,
      status: event.status,
    ));

    res.fold(
      (failure) => emit(OrderFailure(failure.message)),
      (_) => emit(const OrderSuccess()),
    );
  }
}
