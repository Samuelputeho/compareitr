import 'package:compareitr/features/saved/domain/usecases/add_saved_item_usecase.dart';
import 'package:compareitr/features/saved/domain/usecases/get_saved_items_usecase.dart';
import 'package:compareitr/features/saved/domain/usecases/remove_saved_item_usecase.dart';
import 'package:compareitr/core/common/entities/saved_entity.dart';
import 'package:compareitr/core/common/models/saved_model.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'saved_event.dart';
part 'saved_state.dart';

class SavedBloc extends Bloc<SavedEvent, SavedState> {
  final AddSavedItemUsecase _addSavedItemUsecase;

  final GetSavedItemsUsecase _getSavedItemsUsecase;

  final RemoveSavedItemUsecase _removeSavedItemUsecase;

  // Cache for saved items
  List<SavedEntity> _cachedSavedItems = [];

  SavedBloc({
    required AddSavedItemUsecase addSavedItemUsecase,
    required GetSavedItemsUsecase getSavedItemsUsecase,
    required RemoveSavedItemUsecase removeSavedItemUsecase,
  })  : _addSavedItemUsecase = addSavedItemUsecase,
        _getSavedItemsUsecase = getSavedItemsUsecase,
        _removeSavedItemUsecase = removeSavedItemUsecase,
        super(SavedInitial()) {
    on<AddSavedItem>(_onAddSavedItem);
    on<GetSavedItems>(_onGetSavedItems);
    on<RemoveSavedItem>(_onRemoveSavedItem);
    on<RefreshSavedItems>(_onRefreshSavedItems);
  }

  Future<void> _onAddSavedItem(
      AddSavedItem event, Emitter<SavedState> emit) async {
    emit(SavedLoading());
    final result = await _addSavedItemUsecase(
      AddSavedItemParams(
        name: event.name,
        image: event.image,
        measure: event.measure,
        shopName: event.shopName,
        savedId: event.savedId,
        price: event.price,
      ),
    );

    result.fold(
      (failure) => emit(SavedError(message: failure.message)),
      (_) {
        // Invalidate cache since we added a new item
        _cachedSavedItems.clear();
        add(GetSavedItems(
            savedId: event.savedId)); // Fetch updated saved items after adding
      },
    );
  }

  Future<void> _onRemoveSavedItem(
      RemoveSavedItem event, Emitter<SavedState> emit) async {
    emit(SavedLoading());
    final result =
        await _removeSavedItemUsecase(RemoveSavedItemParams(id: event.id));

    result.fold(
      (failure) => emit(SavedError(message: failure.message)),
      (_) {
        // Invalidate cache since we removed an item
        _cachedSavedItems.clear();
        // Ensure we fetch the updated list for the correct user/group
        add(GetSavedItems(savedId: event.savedId)); // Use the correct savedId
      },
    );
  }

  Future<void> _onGetSavedItems(
GetSavedItems event, Emitter<SavedState> emit) async {
    final savedId = event.savedId;
    
    // First, check for cached saved items in Hive
    final box = Hive.box('recently_viewed');
    final cacheKey = 'saved_items_$savedId';
    final cachedData = box.get(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 SavedBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedSavedItems = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 SavedBloc: Parsing cached item: $itemData');
        return SavedModel(
          id: itemData['id'],
          name: itemData['name'],
          image: itemData['image'],
          measure: itemData['measure'],
          shopName: itemData['shopName'],
          savedId: itemData['savedId'],
          price: itemData['price'].toDouble(),
        );
      }).toList();
      
      if (cachedSavedItems.isNotEmpty) {
        print('✅ SavedBloc: Using cached saved items (${cachedSavedItems.length} items)');
        print('🔍 SavedBloc: First saved item: ${cachedSavedItems.first.name} - ${cachedSavedItems.first.price}');
        _cachedSavedItems = cachedSavedItems;
        emit(SavedLoaded(savedItems: cachedSavedItems));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, continue to fetch fresh data below
      }
    }
    

    // If offline and no cached saved items, emit error
    if (CacheManager.isOffline) {
      emit(SavedError(message: 'You\'re offline and no cached saved items available'));
      return;
    }
    
    emit(SavedLoading());
    final result = await _getSavedItemsUsecase(savedId);

    result.fold(
      (failure) {
        // If server error, try to use cached data as fallback
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedSavedItems = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return SavedModel(
              id: itemData['id'],
              name: itemData['name'],
              image: itemData['image'],
              measure: itemData['measure'],
              shopName: itemData['shopName'],
              savedId: itemData['savedId'],
              price: itemData['price'].toDouble(),
            );
          }).toList();
          
          if (cachedSavedItems.isNotEmpty) {
            print('✅ SavedBloc: Server error, using cached saved items (${cachedSavedItems.length} items)');
            _cachedSavedItems = cachedSavedItems;
            emit(SavedLoaded(savedItems: cachedSavedItems));
            return;
          }
        }
        
        emit(SavedError(message: failure.message));
      },
      (savedItems) {
        // Cache the data
        _cachedSavedItems = savedItems;
        emit(SavedLoaded(savedItems: savedItems));
      },
    );
  }

  Future<void> _onRefreshSavedItems(
      RefreshSavedItems event, Emitter<SavedState> emit) async {
    // Force refresh by clearing cache and fetching fresh data
    _cachedSavedItems.clear();
    add(GetSavedItems(savedId: event.savedId));
  }
}
