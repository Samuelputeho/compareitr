import 'dart:async';
import 'package:compareitr/core/common/models/branch_model.dart';
import 'package:compareitr/core/common/models/category_model.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/common/models/product_model.dart';
import '../../../../core/common/models/shop_model.dart';
import '../../../../core/constants/app_const.dart';

abstract interface class ShopsRemoteDataSource {
  Future<List<ShopModel>> getAllShops();
  Future<List<CategoryModel>> getAllCategories();
  Future<List<ProductModel>> getAllProducts();
  Future<List<BranchModel>> getBranchesByShopId(String shopId);
}

class ShopsRemoteDataSourceImpl implements ShopsRemoteDataSource {
  final SupabaseClient client;

  ShopsRemoteDataSourceImpl(this.client);

  @override
  Future<List<ShopModel>> getAllShops() async {
    try {
      final response = await client.from(AppConstants.shopCollection).select('*');
      return response.map((json) => ShopModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      print("🔍 Categories: Fetching from remote data source...");
      final response = await client
          .from(AppConstants.categoryCollection)
          .select('''
            *,
            ${AppConstants.shopCollection}!inner (
              shopName
            )
          ''')
          .timeout(const Duration(seconds: 10)); // Add 10 second timeout

      return response.map((json) {
        final shopName = json[AppConstants.shopCollection]['shopName'];

        final modifiedJson = {
          ...json,
          'shopName': shopName,
        };
        modifiedJson.remove(AppConstants.shopCollection);

        return CategoryModel.fromJson(modifiedJson);
      }).toList();
    } on PostgrestException catch (e) {
      print("❌ Categories: PostgrestException - ${e.message}");
      throw ServerException(e.message);
    } on TimeoutException {
      print("❌ Categories: TimeoutException - Request timed out");
      throw ServerException('Request timed out. Please check your internet connection.');
    } catch (e) {
      print("❌ Categories: Unexpected error - $e");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      print("🔍 Products: Fetching from remote data source...");
      final response = await client
          .from(AppConstants.productCollection)
          .select('''
            *,
            ${AppConstants.shopCollection}!inner (
              shopName
            ),
            ${AppConstants.categoryCollection}!inner (
              category_name
            )
          ''')
          .order('created_at')
          .timeout(const Duration(seconds: 10)); // Add 10 second timeout

      return response.map((json) {
        final modifiedJson = {
          ...json,
          'shopName': json[AppConstants.shopCollection]['shopName'],
          'category': json[AppConstants.categoryCollection]['category_name'],
        };
        modifiedJson.remove(AppConstants.shopCollection);
        modifiedJson.remove(AppConstants.categoryCollection);

        return ProductModel.fromJson(modifiedJson);
      }).toList();
    } on PostgrestException catch (e) {
      print("❌ Products: PostgrestException - ${e.message}");
      throw ServerException(e.message);
    } on TimeoutException {
      print("❌ Products: TimeoutException - Request timed out");
      throw ServerException('Request timed out. Please check your internet connection.');
    } catch (e) {
      print("❌ Products: Unexpected error - $e");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<BranchModel>> getBranchesByShopId(String shopId) async {
    try {
      print('Fetching branches for shopId: $shopId');
      final response = await client
          .from('branches')
          .select('*')
          .eq('shop_id', shopId)  // Changed from 'shopId' to 'shop_id'
          .order('branch_name');  // Changed from 'branchName' to 'branch_name'

      print('Branches response: $response');
      return response.map((json) => BranchModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      print('PostgrestException: ${e.message}');
      throw ServerException(e.message);
    } catch (e) {
      print('General Exception: $e');
      throw ServerException(e.toString());
    }
  }
}
