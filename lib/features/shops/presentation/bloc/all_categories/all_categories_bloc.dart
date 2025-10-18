import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../core/common/entities/category_entity.dart';
import '../../../../../core/common/models/category_model.dart';
import '../../../../../core/common/cache/cache.dart';
import '../../../../../core/usecase/usecase.dart';
import '../../../domain/usecase/get_categories.dart';

part 'all_categories_event.dart';
part 'all_categories_state.dart';

class AllCategoriesBloc extends Bloc<AllCategoriesEvent, AllCategoriesState> {
  final GetCategoriesUsecase _getCategoriesUsecase;

  static List<CategoryEntity> allCategories = [];
  static List<CategoryEntity> categoriesByShopName = [];

  AllCategoriesBloc({required GetCategoriesUsecase getCategoriesUsecase})
      : _getCategoriesUsecase = getCategoriesUsecase,
        super(AllCategoriesInitial()) {
    on<AllCategoriesEvent>((event, emit) {});
    on<GetAllCategoriesEvent>(_onGetAllCategories);
    on<GetCategoriesByShopNameEvent>(_onGetCategoriesByShopName);
  }

  void _onGetAllCategories(
    GetAllCategoriesEvent event,
    Emitter<AllCategoriesState> emit,
  ) async {
    emit(AllCategoriesLoading());
    
    // First, check for cached categories
    final box = Hive.box('shops');
    final cachedData = box.get('categories');
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 AllCategoriesBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedCategories = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 AllCategoriesBloc: Parsing cached item: $itemData');
        return CategoryModel.fromJson(itemData);
      }).toList();
      
      if (cachedCategories.isNotEmpty) {
        print('✅ AllCategoriesBloc: Using cached categories (${cachedCategories.length} categories)');
        print('🔍 AllCategoriesBloc: First category: ${cachedCategories.first.categoryName} - ${cachedCategories.first.categoryUrl}');
        allCategories = cachedCategories;
        emit(AllCategoriesSuccess(categories: cachedCategories));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, continue to fetch fresh data below
      }
    }

    // If offline and no cached categories, emit failure
    if (CacheManager.isOffline) {
      emit(AllCategoriesFailure(message: 'You\'re offline and no cached categories available'));
      return;
    }

    // Fetch fresh data from remote
    final res = await _getCategoriesUsecase(NoParams());
    res.fold(
      (l) {
        // If server error, try to use cached data as fallback
        final box = Hive.box('shops');
        final cachedData = box.get('categories');
        
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedCategories = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return CategoryModel.fromJson(itemData);
          }).toList();
          
          if (cachedCategories.isNotEmpty) {
            print('✅ AllCategoriesBloc: Server error, using cached categories (${cachedCategories.length} categories)');
            allCategories = cachedCategories;
            emit(AllCategoriesSuccess(categories: cachedCategories));
            return;
          }
        }
        
        emit(AllCategoriesFailure(message: l.message));
      },
      (r) {
        allCategories = r;
        emit(AllCategoriesSuccess(categories: r));
      },
    );
  }

  void _onGetCategoriesByShopName(
    GetCategoriesByShopNameEvent event,
    Emitter<AllCategoriesState> emit,
  ) async {
    print("Getting categories for shop: ${event.shopName}");
    emit(AllCategoriesLoading());
    
    // If allCategories is empty, try to load from cache first
    if (allCategories.isEmpty) {
      print("All categories is empty, checking cache first");
      final box = Hive.box('shops');
      final cachedData = box.get('categories');
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final cachedCategories = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return CategoryModel.fromJson(itemData);
        }).toList();
        
        if (cachedCategories.isNotEmpty) {
          print("✅ Loaded ${cachedCategories.length} categories from cache");
          allCategories = cachedCategories;
        }
      }
      
      // If still empty and online, fetch from remote
      if (allCategories.isEmpty && !CacheManager.isOffline) {
        print("Categories still empty, fetching from remote");
        final res = await _getCategoriesUsecase(NoParams());
        res.fold(
          (l) {
            // If server error and we have cached data, use it
            if (cachedData != null) {
              final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
              final cachedCategories = cachedItems.map((item) {
                final itemData = Map<String, dynamic>.from(item as Map);
                return CategoryModel.fromJson(itemData);
              }).toList();
              
              if (cachedCategories.isNotEmpty) {
                print("✅ Server error, using cached categories (${cachedCategories.length} categories)");
                allCategories = cachedCategories;
              }
            }
          },
          (r) {
            allCategories = r;
            print("Fetched ${r.length} total categories from remote");
          },
        );
      } else if (allCategories.isEmpty && CacheManager.isOffline) {
        print("❌ Offline and no cached categories available");
        emit(AllCategoriesFailure(message: 'You\'re offline and no cached categories available'));
        return;
      }
    }

    print("Total categories available: ${allCategories.length}");
    print("Available shop names in categories: ${allCategories.map((c) => c.shopName).toSet().toList()}");
    
    // Filter categories by shop name
    categoriesByShopName = allCategories
        .where((category) => category.shopName == event.shopName)
        .toList();

    print("Categories found for shop '${event.shopName}': ${categoriesByShopName.length}");
    for (var category in categoriesByShopName) {
      print("Category: ${category.categoryName} (Shop: ${category.shopName})");
    }

    emit(CategoriesByShopNameSuccess(categories: categoriesByShopName));
  }
}
