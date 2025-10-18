import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/shops/domain/usecase/get_all_products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../core/common/entities/product_entity.dart';
import '../../../../../core/common/models/product_model.dart';
import '../../../../../core/common/cache/cache.dart';

part 'all_products_event.dart';
part 'all_products_state.dart';

class AllProductsBloc extends Bloc<AllProductsEvent, AllProductsState> {
  final GetAllProductsUseCase _getAllProductsUseCase;
  static List<ProductEntity> allProducts = [];
  static List<ProductEntity> productsByCategory = [];
  static List<ProductEntity> productsBySubCategory = [];
  static List<String> subCategories = [];

  AllProductsBloc({required GetAllProductsUseCase getAllProductsUseCase})
      : _getAllProductsUseCase = getAllProductsUseCase,
        super(AllProductsInitial()) {
    print(
        "AllProductsBloc created with GetAllProductsUseCase: $getAllProductsUseCase");
    on<AllProductsEvent>((event, emit) {});
    on<GetAllProductsEvent>(_onGetAllProducts);
    on<GetProductsByCategoryEvent>(_onGetProductsByCategory);
    on<GetProductsBySubCategoryEvent>(_onGetProductsBySubCategory);
    on<SearchProductsEvent>(_onSearchProducts);
  }

  Future<void> _onGetAllProducts(
      GetAllProductsEvent event, Emitter<AllProductsState> emit) async {
    // First, check for cached products
    final box = Hive.box('shops');
    final cachedData = box.get('products');
    
    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      print('🔍 AllProductsBloc: Found cached data with ${cachedItems.length} items');
      
      final cachedProducts = cachedItems.map((item) {
        final itemData = Map<String, dynamic>.from(item as Map);
        print('🔍 AllProductsBloc: Parsing cached item: $itemData');
        return ProductModel.fromJson(itemData);
      }).toList();
      
      if (cachedProducts.isNotEmpty) {
        print('✅ AllProductsBloc: Using cached products (${cachedProducts.length} products)');
        print('🔍 AllProductsBloc: First product: ${cachedProducts.first.name} - ${cachedProducts.first.price}');
        allProducts = cachedProducts;
        emit(GetAllProductsSuccess(products: cachedProducts));
        
        // If offline, return cached data immediately
        if (CacheManager.isOffline) {
          return;
        }
        // If online, continue to fetch fresh data below
      }
    }

    // If offline and no cached products, emit failure
    if (CacheManager.isOffline) {
      emit(GetAllProductsFailure(message: 'You\'re offline and no cached products available'));
      return;
    }

    // Fetch fresh data from remote
    final result = await _getAllProductsUseCase.call(NoParams());
    result.fold(
      (l) {
        // If server error, try to use cached data as fallback
        final box = Hive.box('shops');
        final cachedData = box.get('products');
        
        if (cachedData != null) {
          final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
          final cachedProducts = cachedItems.map((item) {
            final itemData = Map<String, dynamic>.from(item as Map);
            return ProductModel.fromJson(itemData);
          }).toList();
          
          if (cachedProducts.isNotEmpty) {
            print('✅ AllProductsBloc: Server error, using cached products (${cachedProducts.length} products)');
            allProducts = cachedProducts;
            emit(GetAllProductsSuccess(products: cachedProducts));
            return;
          }
        }
        
        emit(GetAllProductsFailure(message: l.message));
      },
      (r) {
        allProducts = r;
        emit(GetAllProductsSuccess(products: r));
      },
    );
  }

  Future<void> _onGetProductsByCategory(
      GetProductsByCategoryEvent event, Emitter<AllProductsState> emit) async {
    print("Getting products for category: ${event.category} in shop: ${event.shopName}");
    
    // If allProducts is empty, try to load from cache first
    if (allProducts.isEmpty) {
      print("All products is empty, checking cache first");
      final box = Hive.box('shops');
      final cachedData = box.get('products');
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final cachedProducts = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return ProductModel.fromJson(itemData);
        }).toList();
        
        if (cachedProducts.isNotEmpty) {
          print("✅ Loaded ${cachedProducts.length} products from cache");
          allProducts = cachedProducts;
        }
      }
      
      // If still empty and online, fetch from remote
      if (allProducts.isEmpty && !CacheManager.isOffline) {
        print("Products still empty, fetching from remote");
        emit(GetProductsByCategoryLoading());
        final result = await _getAllProductsUseCase.call(NoParams());
        result.fold(
          (l) {
            // If server error and we have cached data, use it
            if (cachedData != null) {
              final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
              final cachedProducts = cachedItems.map((item) {
                final itemData = Map<String, dynamic>.from(item as Map);
                return ProductModel.fromJson(itemData);
              }).toList();
              
              if (cachedProducts.isNotEmpty) {
                print("✅ Server error, using cached products (${cachedProducts.length} products)");
                allProducts = cachedProducts;
              }
            }
          },
          (r) {
            allProducts = r;
            print("Fetched ${r.length} total products from remote");
          },
        );
      } else if (allProducts.isEmpty && CacheManager.isOffline) {
        print("❌ Offline and no cached products available");
        emit(GetProductsByCategoryFailure(message: 'You\'re offline and no cached products available'));
        return;
      }
    }

    print("Total products available: ${allProducts.length}");
    print("Available shop names in products: ${allProducts.map((p) => p.shopName).toSet().toList()}");
    print("Available categories in products: ${allProducts.map((p) => p.category).toSet().toList()}");
    
    productsByCategory = allProducts
        .where((product) =>
            product.shopName == event.shopName &&
            product.category == event.category)
        .toList();

    print("Products found for category '${event.category}' in shop '${event.shopName}': ${productsByCategory.length}");
    for (var product in productsByCategory) {
      print("Product: ${product.name} (Shop: ${product.shopName}, Category: ${product.category})");
    }

    subCategories = productsByCategory
        .map((product) => product.subCategory)
        .toSet()
        .toList();

    // same success state
    emit(GetProductsByCategorySuccess(
      products: productsByCategory,
      subCategories: subCategories,
    ));
  }

  Future<void> _onGetProductsBySubCategory(GetProductsBySubCategoryEvent event,
      Emitter<AllProductsState> emit) async {
    productsBySubCategory = allProducts
        .where((product) =>
            product.shopName == event.shopName &&
            product.category == event.category &&
            product.subCategory == event.subCategory)
        .toList();
    // same success state
    emit(
      GetProductsBySubCategorySuccess(products: productsBySubCategory),
    );
  }

  // Update the Bloc with a handler for the SearchProductsEvent
  void _onSearchProducts(
      SearchProductsEvent event, Emitter<AllProductsState> emit) {
    final query = event.query.toLowerCase();

    final searchResults = allProducts
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();

    emit(GetAllProductsSuccess(products: searchResults));
  }
}
