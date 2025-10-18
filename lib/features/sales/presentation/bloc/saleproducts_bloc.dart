import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/sales/domain/entity/sale_products_entity.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/sales/domain/usecases/get_all_sale_products_usecase.dart';
import 'package:compareitr/core/services/cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'saleproducts_event.dart';
part 'saleproducts_state.dart';

class SaleProductBloc extends Bloc<SaleproductsEvent, SaleproductsState> {
  final GetAllSaleProductsUsecase getAllProductsUseCase;

  SaleProductBloc({required this.getAllProductsUseCase})
      : super(SaleproductsInitial()) {
    on<GetAllSaleProductsEvent>(_onGetAllSaleProductEvent);
  }

  Future<void> _onGetAllSaleProductEvent(
      SaleproductsEvent event, Emitter<SaleproductsState> emit) async {
    // First, check for cached sale products
    final box = Hive.box('recently_viewed');
    final cacheKey = 'sale_products';
    final cachedData = box.get(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 SaleProductBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedSaleProducts = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 SaleProductBloc: Parsing cached item: $itemData');
        return SaleProductsEntity(
          storeName: itemData['storeName'],
          image: itemData['image'],
          name: itemData['name'],
          description: itemData['description'],
          price: itemData['price'].toDouble(),
          oldprice: itemData['oldprice'].toDouble(),
          measure: itemData['measure'],
          save: (itemData['save'] ?? 0.0).toDouble(),
          startDate: itemData['startDate'],
          endDate: itemData['endDate'],
        );
      }).toList();
      
      if (cachedSaleProducts.isNotEmpty) {
        print('✅ SaleProductBloc: Using cached sale products (${cachedSaleProducts.length} items)');
        print('🔍 SaleProductBloc: First sale product: ${cachedSaleProducts.first.name}');
        emit(SaleproductsSuccess(saleProducts: cachedSaleProducts));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, continue to fetch fresh data below
      }
    }

    // If offline and no cached sale products, emit failure
    if (CacheManager.isOffline) {
      emit(SaleproductsFailure(message: 'You\'re offline and no cached sale products available'));
      return;
    }

    emit(SaleproductsLoading());
    final result = await getAllProductsUseCase(NoParams());

    result.fold(
      (failure) {
        // If server error, try to use cached data as fallback
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedSaleProducts = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return SaleProductsEntity(
              storeName: itemData['storeName'],
              image: itemData['image'],
              name: itemData['name'],
              description: itemData['description'],
              price: itemData['price'].toDouble(),
              oldprice: itemData['oldprice'].toDouble(),
              measure: itemData['measure'],
              save: (itemData['save'] ?? 0.0).toDouble(),
              startDate: itemData['startDate'],
              endDate: itemData['endDate'],
            );
          }).toList();
          
          if (cachedSaleProducts.isNotEmpty) {
            print('🔄 SaleProductBloc: Server error, using cached data as fallback');
            emit(SaleproductsSuccess(saleProducts: cachedSaleProducts));
            return;
          }
        }
        emit(SaleproductsFailure(message: _mapFailureToMessage(failure)));
      },
      (saleProducts) => emit(SaleproductsSuccess(saleProducts: saleProducts)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    // Map the Failure to a user-friendly error message
    if (failure is ServerFailure) {
      return 'Server error occurred. Please try again later.';
    } else if (failure is NetworkFailure) {
      return 'Please check your internet connection.';
    } else {
      return 'An unexpected error occurred.';
    }
  }
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message) : super(message);
}
