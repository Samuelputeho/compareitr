import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/common/entities/shop_entity.dart';
import '../../../../../core/common/cache/cache.dart';
import '../../../../../core/usecase/usecase.dart';
import '../../../domain/usecase/get_all_shops.dart';

part 'all_shops_event.dart';
part 'all_shops_state.dart';

class AllShopsBloc extends Bloc<AllShopsEvent, AllShopsState> {
  final GetAllShopsUsecase _getAllShopsUsecase;

  static List<ShopEntity> allStores = [];
  String? _currentFilter;

  AllShopsBloc({required GetAllShopsUsecase getAllShopsUsecase})
      : _getAllShopsUsecase = getAllShopsUsecase,
        super(AllShopsInitial()) {
    on<AllShopsEvent>((event, emit) {});
    on<GetAllShopsEvent>(_onGetAllShops);
    on<FilterShopsByTypeEvent>(_onFilterShopsByType);
    on<ClearShopFilterEvent>(_onClearShopFilter);
  }

  void _onGetAllShops(
    GetAllShopsEvent event,
    Emitter<AllShopsState> emit,
  ) async {
    // Let the repository handle caching logic (it already has offline-first caching)
    final res = await _getAllShopsUsecase(NoParams());

    res.fold(
      (l) {
        // If offline and no cached data, show offline message
        if (CacheManager.isOffline && l.message.contains('offline')) {
          emit(AllShopsFailure(message: 'You\'re offline. No cached shops available.'));
        } else {
          emit(AllShopsFailure(message: l.message));
        }
      },
      (r) {
        allStores = r;
        print("Number of shops fetched: ${r.length}");
        _applyCurrentFilter(emit);
      },
    );
  }

  void _onFilterShopsByType(
    FilterShopsByTypeEvent event,
    Emitter<AllShopsState> emit,
  ) {
    _currentFilter = event.shopType;
    _applyCurrentFilter(emit);
  }

  void _onClearShopFilter(
    ClearShopFilterEvent event,
    Emitter<AllShopsState> emit,
  ) {
    _currentFilter = null;
    _applyCurrentFilter(emit);
  }

  void _applyCurrentFilter(Emitter<AllShopsState> emit) {
    if (allStores.isEmpty) {
      emit(AllShopsInitial());
      return;
    }

    List<ShopEntity> filteredShops = allStores;
    
    if (_currentFilter != null && _currentFilter!.isNotEmpty) {
      filteredShops = allStores
          .where((shop) => shop.shopType.toLowerCase() == _currentFilter!.toLowerCase())
          .toList();
    }

    emit(AllShopsSuccess(shops: filteredShops, currentFilter: _currentFilter));
  }

  // Helper method to get all unique shop types
  static List<String> getAllShopTypes() {
    if (allStores.isEmpty) {
      return [];
    }
    return allStores
        .map((shop) => shop.shopType)
        .where((type) => type.isNotEmpty) // Filter out empty shop types
        .toSet()
        .toList()
      ..sort();
  }
}