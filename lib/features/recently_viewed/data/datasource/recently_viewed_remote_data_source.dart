import 'dart:async';
import 'package:compareitr/core/common/models/recently_viewed_model.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class RecentlyViewedRemoteDataSource {
  Future<void> addRecentItem({
    required String name,
    required String image,
    required String measure,
    required String shopName,
    required String recentId,
    required double price,
  });

  Future<void> removeRecentlyItem(String id);

  Future<List<RecentlyViewedModel>> getRecentItems(String recentId);
}

class RecentlyViewedRemoteDataSourceImpl
    implements RecentlyViewedRemoteDataSource {
  final SupabaseClient supabaseClient;

  RecentlyViewedRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> addRecentItem({
    required String name,
    required String image,
    required String measure,
    required String shopName,
    required String recentId,
    required double price,
  }) async {
    try {
      final recentItem = RecentlyViewedModel(
          name: name,
          image: image,
          measure: measure,
          shopName: shopName,
          recentId: recentId,
          price: price);

      await supabaseClient.from('recent').insert(recentItem.toJson());
    } on PostgrestException catch (e) {
      throw ServerException('Failed to add recent item: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<void> removeRecentlyItem(String id) async {
    try {
      // Delete the recent item by id
      await supabaseClient.from('recent').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServerException('Failed to remove recent item: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<RecentlyViewedModel>> getRecentItems(String recentId) async {
    try {
      print('🔍 Recently viewed: Fetching items from remote data source for user: $recentId');
      // Fetch all recent items, ordered by creation time (oldest first)
      // This ensures the auto-limit feature deletes the truly oldest item
      final List<dynamic> response = await supabaseClient
          .from('recent')
          .select()
          .eq('recentId', recentId)
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 10));  // Add 10 second timeout
      
      print('✅ Recently viewed: Successfully fetched ${response.length} items from remote');
      return response
          .map((item) => RecentlyViewedModel.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      print('❌ Recently viewed: PostgrestException - ${e.message}');
      throw ServerException('Failed to fetch recent items: ${e.message}');
    } on TimeoutException {
      print('❌ Recently viewed: TimeoutException - Request timed out');
      throw ServerException('Request timed out. Please check your internet connection.');
    } catch (e) {
      print('❌ Recently viewed: Unexpected error - $e');
      throw ServerException('Unexpected error: $e');
    }
  }
}
