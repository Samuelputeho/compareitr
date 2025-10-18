import 'package:compareitr/core/common/entities/recently_viewed_entity.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/features/recently_viewed/domain/usecases/add_recent_item_usecase.dart';
import 'package:compareitr/features/recently_viewed/domain/usecases/get_recent_items_usecase.dart';
import 'package:compareitr/features/recently_viewed/domain/usecases/remove_recent_item_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'recent_event.dart';
part 'recent_state.dart';

class RecentBloc extends Bloc<RecentEvent, RecentState> {
  final AddRecentItemUsecase _addRecentItemUsecase;

  final GetRecentItemsUsecase _getRecentItemsUsecase;

  final RemoveRecentItemUsecase _removeRecentItemUsecase;

  // Cache for recent items
  List<RecentlyViewedEntity> _cachedRecentItems = [];

  RecentBloc({
    required AddRecentItemUsecase addRecentItemUsecase,
    required GetRecentItemsUsecase getRecentItemsUsecase,
    required RemoveRecentItemUsecase removeRecentItemUsecase,
  })  : _addRecentItemUsecase = addRecentItemUsecase,
        _getRecentItemsUsecase = getRecentItemsUsecase,
        _removeRecentItemUsecase = removeRecentItemUsecase,
        super(RecentInitial()) {
    on<AddRecentItem>(_onAddRecentItem);
    on<GetRecentItems>(_onGetRecentItems);
    on<CheckIfProductExists>(_onCheckIfProductExists);
    on<RemoveRecentlyItem>(_onRemoveRecentItem);
    on<RefreshRecentItems>(_onRefreshRecentItems);
    on<ClearAllRecentItems>(_onClearAllRecentItems);
  }
  
  // Maximum number of recently viewed items to keep
  static const int _maxRecentItems = 20;

  Future<void> _onAddRecentItem(
      AddRecentItem event, Emitter<RecentState> emit) async {
    emit(RecentLoading());
    
    // First, check current items
    final currentItems = await _getRecentItemsUsecase(event.recentId);
    
    await currentItems.fold(
      (failure) async {
        // If error getting items, just try to add anyway
        final result = await _addRecentItemUsecase(
          AddRecentItemParams(
            name: event.name,
            image: event.image,
            measure: event.measure,
            shopName: event.shopName,
            recentId: event.recentId,
            price: event.price,
          ),
        );
        
        result.fold(
          (failure) => emit(RecentError(message: failure.message)),
          (_) {
            _cachedRecentItems.clear();
            add(GetRecentItems(recentId: event.recentId));
          },
        );
      },
      (items) async {
        // Check if this exact product already exists
        final existingItem = items.firstWhere(
          (item) =>
              item.name == event.name &&
              item.shopName == event.shopName &&
              item.measure == event.measure,
          orElse: () => RecentlyViewedEntity(
            id: '',
            name: '',
            image: '',
            measure: '',
            shopName: '',
            price: 0.0,
            recentId: '',
          ),
        );

        if (existingItem.name.isNotEmpty) {
          // Product already exists - remove it first (to move to top)
          print('🔄 Product already exists, moving to top: ${existingItem.name}');
          await _removeRecentItemUsecase(RemoveRecentItemParams(id: existingItem.id));
        } else {
          // New product - check if we need to remove oldest to stay under limit
          if (items.length >= _maxRecentItems && items.isNotEmpty) {
            // Get the oldest item (first in list)
            final oldestItem = items.first;
            await _removeRecentItemUsecase(RemoveRecentItemParams(id: oldestItem.id));
            print('🗑️ Auto-removed oldest item to maintain limit of $_maxRecentItems');
          }
        }
        
        // Now add the item (either new or moved to top)
        final result = await _addRecentItemUsecase(
          AddRecentItemParams(
            name: event.name,
            image: event.image,
            measure: event.measure,
            shopName: event.shopName,
            recentId: event.recentId,
            price: event.price,
          ),
        );

        result.fold(
          (failure) => emit(RecentError(message: failure.message)),
          (_) {
            // Invalidate cache since we added a new item
            _cachedRecentItems.clear();
            
            // Also clear persistent cache to force refresh
            final cacheKey = 'recent_items_${event.recentId}';
            final box = Hive.box('recently_viewed');
            box.delete(cacheKey);
            
            add(GetRecentItems(recentId: event.recentId));
          },
        );
      },
    );
  }

  Future<void> _onGetRecentItems(
      GetRecentItems event, Emitter<RecentState> emit) async {
    final recentId = event.recentId;
    
    // First, check for cached recent items in Hive (like cart does)
    final box = Hive.box('recently_viewed');
    final cacheKey = 'recent_items_$recentId';
    final cachedData = box.get(cacheKey);
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 RecentBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedRecentItems = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 RecentBloc: Parsing cached recent item: ${itemData['name']}');
        return RecentlyViewedEntity(
          id: itemData['id'],
          name: itemData['name'],
          image: itemData['image'],
          measure: itemData['measure'],
          shopName: itemData['shopName'],
          recentId: itemData['recentId'],
          price: itemData['price'].toDouble(),
        );
      }).toList();
      
      if (cachedRecentItems.isNotEmpty) {
        print('✅ RecentBloc: Using cached recent items (${cachedRecentItems.length} items)');
        print('🔍 RecentBloc: First recent item: ${cachedRecentItems.first.name}');
        emit(RecentLoaded(recentItems: cachedRecentItems));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, continue to fetch fresh data below (like cart does)
      }
    }

    // If offline and no cached data, return error
    if (CacheManager.isOffline) {
      print('📱 Offline: No cached recent items found for key: $cacheKey');
      emit(RecentError(message: 'You\'re offline and no cached recent items available'));
      return;
    }
    
    emit(RecentLoading());
    final result = await _getRecentItemsUsecase(recentId);

    result.fold(
      (failure) {
        // If network error, try to use any available cached data
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedRecentItems = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return RecentlyViewedEntity(
              id: itemData['id'],
              name: itemData['name'],
              image: itemData['image'],
              measure: itemData['measure'],
              shopName: itemData['shopName'],
              recentId: itemData['recentId'],
              price: itemData['price'].toDouble(),
            );
          }).toList();
          
          if (cachedRecentItems.isNotEmpty) {
            print('✅ RecentBloc: Server error, using cached recent items (${cachedRecentItems.length} items)');
            emit(RecentLoaded(recentItems: cachedRecentItems));
            return;
          }
        }
        
        emit(RecentError(message: failure.message));
      },
      (recentItems) {
        // Cache the data
        _cachedRecentItems = recentItems;
        emit(RecentLoaded(recentItems: recentItems));
      },
    );
  }

  Future<void> _onCheckIfProductExists(
    CheckIfProductExists event, Emitter<RecentState> emit) async {
  emit(RecentLoading());

  // Get the list of recently viewed items
  final result = await _getRecentItemsUsecase(event.recentId);

  result.fold(
    (failure) => emit(RecentError(message: failure.message)),
    (recentItems) {
      // Check if the product already exists in the list
      final existingProduct = recentItems.firstWhere(
        (item) =>
            item.name == event.name &&
            item.shopName == event.shopName &&
            item.measure == event.measure,
        orElse: () => RecentlyViewedEntity( 
          id: event.recentId,// Return a default value here
          name: '', 
          image: '',
          measure: '',
          shopName: '',
          price: 0.0,
          recentId: '', // Adjust according to the default values needed
        ),
      );

      if (existingProduct.name.isEmpty) { // Check if product was found
        // If the product doesn't exist, add it to the list
        add(AddRecentItem(
          name: event.name,
          image: '', // Add the correct image URL here
          measure: event.measure,
          shopName: event.shopName,
          recentId: event.recentId,
          price: 0.0, // Add the correct price here
        ));
      } else {
        // If the product exists, just emit the existing list
        emit(RecentLoaded(recentItems: recentItems));
      }
    },
  );
}

  Future<void> _onRemoveRecentItem(
      RemoveRecentlyItem event, Emitter<RecentState> emit) async {
    emit(RecentLoading());
    final result = await _removeRecentItemUsecase(RemoveRecentItemParams(id: event.id));

    result.fold(
      (failure) => emit(RecentError(message: failure.message)),
      (_) {
        // Invalidate cache since we removed an item
        _cachedRecentItems.clear();
        add(GetRecentItems(recentId: event.recentId));
      },
    );
  }

  Future<void> _onRefreshRecentItems(
      RefreshRecentItems event, Emitter<RecentState> emit) async {
    // Force refresh by clearing cache and fetching fresh data
    _cachedRecentItems.clear();
    add(GetRecentItems(recentId: event.recentId));
  }
  
  Future<void> _onClearAllRecentItems(
      ClearAllRecentItems event, Emitter<RecentState> emit) async {
    emit(RecentLoading());
    
    // Get all items for this user
    final itemsResult = await _getRecentItemsUsecase(event.recentId);
    
    await itemsResult.fold(
      (failure) async {
        emit(RecentError(message: failure.message));
      },
      (items) async {
        // Delete all items one by one
        for (final item in items) {
          await _removeRecentItemUsecase(RemoveRecentItemParams(id: item.id));
        }
        
        print('🗑️ Cleared all ${items.length} recently viewed items');
        
        // Clear cache
        _cachedRecentItems.clear();
        
        // Emit empty state
        emit(RecentLoaded(recentItems: []));
      },
    );
  }
}