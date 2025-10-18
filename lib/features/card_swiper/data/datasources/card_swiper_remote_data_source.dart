import 'dart:async';
import 'package:compareitr/core/common/models/card_swiper_pictures_model.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_const.dart';

abstract interface class CardSwiperRemoteDataSource {
  Future<List<CardSwiperPicturesModel>> getAllPictures();
}

class CardSwiperRemoteDataSourceImpl implements CardSwiperRemoteDataSource {
  final SupabaseClient client;

  CardSwiperRemoteDataSourceImpl(this.client);

  @override
  Future<List<CardSwiperPicturesModel>> getAllPictures() async {
    try {
      print('🔍 Card swiper: Fetching images from remote data source...');
      final response = await client
          .from(AppConstants.cardSwiperCollection)
          .select()
          .timeout(const Duration(seconds: 10)); // Add 10 second timeout

      // Check if the response is empty or has an error
      if (response.isEmpty) {
        return []; // Return an empty list if no data is found
      }

      print('✅ Card swiper: Successfully fetched ${response.length} images from remote');
      return response
          .map((json) => CardSwiperPicturesModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      print('❌ Card swiper: PostgrestException - ${e.message}');
      throw ServerException(e.message);
    } on TimeoutException {
      print('❌ Card swiper: TimeoutException - Request timed out');
      throw ServerException('Request timed out. Please check your internet connection.');
    } catch (e) {
      print('❌ Card swiper: Unexpected error - $e');
      throw ServerException(e.toString());
    }
  }
}
