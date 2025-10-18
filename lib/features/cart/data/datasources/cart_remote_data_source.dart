import 'dart:async';
import 'package:compareitr/core/common/models/cart_model.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CartRemoteDataSource {
  Future<void> addCartItem({
    required String cartId,
    required String itemName,
    required String shopName,
    required String imageUrl,
    required double price,
    required int quantity,
    required String measure,
  });
  Future<void> removeCartItem(String productId);
  Future<List<CartModel>> getCartItems(String cartId);
  // New method to update the cart item's quantity
  Future<void> updateCartItem({
    required String cartId,
    required String id,
    required int quantity,
  });
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final SupabaseClient supabaseClient;

  CartRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> addCartItem({
    required String cartId,
    required String itemName,
    required String shopName,
    required String imageUrl,
    required double price,
    required int quantity,
    required String measure,
  }) async {
    try {
      // Create a CartModel instance from the parameters
      final cartItem = CartModel(
        cartId: cartId,
        itemName: itemName,
        shopName: shopName,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity,
        measure: measure,
      );

      // Insert item into the cart table
      print('DEBUG: Inserting cart item with data: ${cartItem.toJson()}');
      await supabaseClient.from('cart').insert(cartItem.toJson());
      print('DEBUG: Cart item inserted successfully');
    } on PostgrestException catch (e) {
      print('ERROR: PostgrestException adding cart item: ${e.message}');
      print('ERROR: Code: ${e.code}, Details: ${e.details}');
      throw ServerException('Failed to add cart item: ${e.message}');
    } catch (e) {
      print('ERROR: Unexpected error adding cart item: $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<void> removeCartItem(String id) async {
    try {
      // Delete the cart item by cartId
      await supabaseClient.from('cart').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to remove cart item: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<CartModel>> getCartItems(String cartId) async {
    try {
      print('🔍 Cart: Fetching from remote data source for cart: $cartId');
      // Fetch cart items for the specific user, ordered by ID for consistent positioning
      // This prevents items from jumping around when quantities are updated
      final List<dynamic> response = await supabaseClient
          .from('cart')
          .select()
          .eq('cartId', cartId) // Filter by user ID
          .order('id', ascending: true) // Order by ID to maintain consistent positions
          .timeout(const Duration(seconds: 10)); // Add 10 second timeout
      
      final cartItems = response.map((item) => CartModel.fromJson(item)).toList();
      print('✅ Cart: Successfully fetched ${cartItems.length} cart items from remote');
      return cartItems;
    } on PostgrestException catch (e) {
      print('❌ Cart: PostgrestException - ${e.message}');
      throw ServerException('Failed to fetch cart items: ${e.message}');
    } on TimeoutException {
      print('❌ Cart: TimeoutException - Request timed out');
      throw ServerException('Request timed out. Please check your internet connection.');
    } catch (e) {
      print('❌ Cart: Unexpected error - $e');
      throw ServerException('Unexpected error: $e');
    }
  }

  // Update cart item quantity
  @override
Future<void> updateCartItem({
  required String cartId,
  required String id,
  required int quantity,
}) async {
  try {
    print('Updating item with id: $id in cart: $cartId to quantity: $quantity');
    
    final response = await supabaseClient
        .from('cart')
        .update({'quantity': quantity}) // Update the quantity field
        .eq('id', id) // Ensure this matches the id in the cart table
        .eq('cartId', cartId); // Ensure this matches the cartId

    print('Response from update: $response');

    // Check if the response is null or empty
    
  } on PostgrestException catch (e) {
    throw ServerException('Failed to update cart item: ${e.message}');
  } catch (e) {
    throw ServerException('Unexpected error: $e');
  }
}

}
