import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/sales/domain/entity/sale_card_entity.dart';
import 'package:compareitr/features/sales/domain/usecases/get_all_sale_card_usecase.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/services/cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'salecard_event.dart';
part 'salecard_state.dart';

class SalecardBloc extends Bloc<SalecardEvent, SalecardState> {
  final GetSaleCardAllUsecase getSaleCardAllUsecase;

  SalecardBloc({required this.getSaleCardAllUsecase}) : super(SalecardInitial()) {
    on<GetAllSaleCardEvent>(_onGetAllSaleCardEvent);
  }

  Future<void> _onGetAllSaleCardEvent(
      GetAllSaleCardEvent event, Emitter<SalecardState> emit) async {
    // First, check for cached sale cards
    final box = Hive.box('recently_viewed');
    final cacheKey = 'sale_cards';
    final cachedData = box.get(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 SalecardBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedSaleCards = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 SalecardBloc: Parsing cached item: $itemData');
        return SaleCardEntity(
          storeName: itemData['storeName'],
          image: itemData['image'],
          startDate: itemData['startDate'],
          endDate: itemData['endDate'],
        );
      }).toList();
      
      if (cachedSaleCards.isNotEmpty) {
        print('✅ SalecardBloc: Using cached sale cards (${cachedSaleCards.length} items)');
        print('🔍 SalecardBloc: First sale card: ${cachedSaleCards.first.storeName}');
        emit(SalecardSuccess(saleCard: cachedSaleCards));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, the repository will handle cache expiry (1 minute)
        // Only fetch fresh data if cache is stale
      }
    }

    // If offline and no cached sale cards, emit failure
    if (CacheManager.isOffline) {
      emit(SalecardFailure(message: 'You\'re offline and no cached sale cards available'));
      return;
    }

    emit(SalecardLoading());
    final result = await getSaleCardAllUsecase(NoParams());

    result.fold(
      (failure) {
        // If server error, try to use cached data as fallback
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedSaleCards = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return SaleCardEntity(
              storeName: itemData['storeName'],
              image: itemData['image'],
              startDate: itemData['startDate'],
              endDate: itemData['endDate'],
            );
          }).toList();
          
          if (cachedSaleCards.isNotEmpty) {
            print('🔄 SalecardBloc: Server error, using cached data as fallback');
            emit(SalecardSuccess(saleCard: cachedSaleCards));
            return;
          }
        }
        emit(SalecardFailure(message: _mapFailureToMessage(failure)));
      },
      (saleCards) {
        // Debug the saleCards data
        debugPrint('SaleCards: $saleCards');
        emit(SalecardSuccess(saleCard: saleCards));
      },
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
