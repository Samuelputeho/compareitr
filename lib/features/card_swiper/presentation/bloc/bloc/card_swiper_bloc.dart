import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/core/common/entities/card_swiper_pictures_entinty.dart';
import 'package:compareitr/core/services/image_cache_service.dart';
import 'package:compareitr/features/card_swiper/domain/usecase/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../../core/usecase/usecase.dart';

part 'card_swiper_event.dart';
part 'card_swiper_state.dart';

class CardSwiperBloc extends Bloc<CardSwiperEvent, CardSwiperState> {
  final GetAllCardSwiperPicturesUseCase _getAllCardSwiperPicturesUseCase;

  // Static list for in-memory cache of the swiper pictures
  static List<CardSwiperPicturesEntinty> allPictures = [];

  // Enhanced cache for card swiper pictures
  List<CardSwiperPicturesEntinty> _cachedPictures = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 10); // Cache for 10 minutes (longer since these change less frequently)

  CardSwiperBloc({required GetAllCardSwiperPicturesUseCase getAllCardSwiperPicturesUseCase})
      : _getAllCardSwiperPicturesUseCase = getAllCardSwiperPicturesUseCase,
        super(CardSwiperInitial()) {
    on<CardSwiperEvent>((event, emit) {}); // You can handle any other events here if needed
    on<GetAllCardSwiperPicturesEvent>(_onGetAllCardSwiperPictures);
    on<RefreshCardSwiperPicturesEvent>(_onRefreshCardSwiperPictures);
  }

  void _onGetAllCardSwiperPictures(
    GetAllCardSwiperPicturesEvent event,
    Emitter<CardSwiperState> emit,
  ) async {
    // First, check if the pictures are cached in persistent storage
    final box = Hive.box('shops');
    final cachedData = box.get('cardSwiperPictures');

    if (cachedData != null) {
      final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
      final cachedPictures = cachedItems.map((item) {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final itemData = Map<String, dynamic>.from(item as Map);
        return CardSwiperPicturesEntinty(
          image: itemData['image'] ?? '',
        );
      }).toList();
      
      if (cachedPictures.isNotEmpty) {
        // If the pictures are cached, emit them immediately and update our cache
        _cachedPictures = cachedPictures;
        _lastFetchTime = DateTime.now();
        allPictures = cachedPictures;
        print('✅ Card swiper: Loaded ${cachedPictures.length} cached images');
        emit(CardSwiperSuccess(pictures: cachedPictures));
        
        // ALWAYS return immediately when we have cached data - whether online or offline
        return;
      }
    }

    // If no cached data and we're offline, emit failure instead of loading forever
    if (CacheManager.isOffline) {
      print('📱 Card swiper: Offline and no cached data available');
      emit(CardSwiperFailure(message: 'No cached images available offline'));
      return;
    }

    // Check if we have cached data and it's still valid (for in-memory cache)
    if (_lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry &&
        _cachedPictures.isNotEmpty) {
      // Return cached data without loading state
      emit(CardSwiperSuccess(pictures: _cachedPictures));
      return;
    }

    // If offline, try to use any available cached data (even if expired)
    if (CacheManager.isOffline) {
      if (_cachedPictures.isNotEmpty) {
        emit(CardSwiperSuccess(pictures: _cachedPictures));
      } else if (allPictures.isNotEmpty) {
        emit(CardSwiperSuccess(pictures: allPictures));
      } else {
        emit(CardSwiperFailure(message: 'You\'re offline and no cached images available'));
      }
      return;
    }

    // If not cached and online, fetch from the API
    emit(CardSwiperLoading(loadingPictures: allPictures));

    final res = await _getAllCardSwiperPicturesUseCase(NoParams());

    res.fold(
      (failure) {
        // If network error, try to use any available cached data
        if (failure.message.contains('Network') || failure.message.contains('Socket')) {
          if (_cachedPictures.isNotEmpty) {
            emit(CardSwiperSuccess(pictures: _cachedPictures));
          } else if (allPictures.isNotEmpty) {
            emit(CardSwiperSuccess(pictures: allPictures));
          } else {
            emit(CardSwiperFailure(message: 'Network error and no cached images available'));
          }
        } else {
          emit(CardSwiperFailure(message: failure.message));
        }
      },
        (pictures) async {
          // Cache the pictures after successful API response
          CacheManager.cache('cardSwiperPictures', pictures);
          
          // Also cache in persistent storage
          final box = Hive.box('shops');
          final cacheData = pictures.map((picture) => {
            'image': picture.image,
          }).toList();
          box.put('cardSwiperPictures', cacheData);
          
          // Pre-cache the images for offline use AND store in Hive
          final imageUrls = pictures.map((picture) => picture.image).toList();
          ImageCacheService.preCacheImages(imageUrls);
          
          // Store images as base64 in Hive for true offline persistence (non-blocking)
          _storeImagesInHive(pictures);
          
          // Verify the data was actually stored
          final storedData = box.get('cardSwiperPictures');
          print('🔍 Card swiper: Verifying stored data - ${storedData != null ? storedData.length : 0} items');
          
          allPictures = pictures;
          _cachedPictures = pictures;
          _lastFetchTime = DateTime.now();
          print('✅ Card swiper: Cached ${pictures.length} images');
          emit(CardSwiperSuccess(pictures: pictures));
        },
    );
  }

  void _onRefreshCardSwiperPictures(
    RefreshCardSwiperPicturesEvent event,
    Emitter<CardSwiperState> emit,
  ) async {
    // Force refresh by clearing cache and fetching fresh data
    _cachedPictures.clear();
    _lastFetchTime = null;
    CacheManager.clearCache('cardSwiperPictures');
    
    // Also clear persistent cache
    final box = Hive.box('shops');
    box.delete('cardSwiperPictures');
    
    add(GetAllCardSwiperPicturesEvent());
  }

  // Store images as base64 in Hive for offline persistence
  Future<void> _storeImagesInHive(List<CardSwiperPicturesEntinty> pictures) async {
    try {
      final box = Hive.box('shops');
      
      for (int i = 0; i < pictures.length; i++) {
        final picture = pictures[i];
        final imageUrl = picture.image;
        
        if (imageUrl.isNotEmpty) {
          try {
            // Download the image and convert to base64
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'cardSwiperImage_$i';
              await box.put(imageKey, base64Image);
              print('📸 Stored card swiper image $i in Hive');
            }
          } catch (e) {
            print('❌ Failed to store card swiper image $i: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing card swiper images in Hive: $e');
    }
  }
}
