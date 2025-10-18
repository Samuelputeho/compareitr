import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ImageCacheService {
  static const String _cacheKey = 'image_cache_manager';
  static CacheManager? _cacheManager;
  
  // Initialize the image cache service
  static Future<void> init() async {
    _cacheManager = CacheManager(
      Config(
        _cacheKey,
        stalePeriod: const Duration(days: 30), // Keep images for 30 days
        maxNrOfCacheObjects: 1000, // Max 1000 cached images
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
  }

  // Get the cache manager instance
  static CacheManager get cacheManager {
    if (_cacheManager == null) {
      throw Exception('ImageCacheService not initialized. Call init() first.');
    }
    return _cacheManager!;
  }

  // Pre-cache a list of images
  static Future<void> preCacheImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;
    
    try {
      final futures = imageUrls.map((url) => _preCacheSingleImage(url));
      await Future.wait(futures, eagerError: false);
      
      if (kDebugMode) {
        print('✅ Pre-cached ${imageUrls.length} images');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error pre-caching images: $e');
      }
    }
  }

  // Pre-cache a single image
  static Future<void> _preCacheSingleImage(String url) async {
    try {
      if (url.isEmpty) return;
      
      await cacheManager.downloadFile(url);
      if (kDebugMode) {
        print('📸 Cached image: $url');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to cache image $url: $e');
      }
    }
  }

  // Check if an image is cached
  static Future<bool> isImageCached(String url) async {
    if (url.isEmpty) return false;
    
    try {
      final fileInfo = await cacheManager.getFileFromCache(url);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  // Get cached image file
  static Future<File?> getCachedImageFile(String url) async {
    if (url.isEmpty) return null;
    
    try {
      final fileInfo = await cacheManager.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      return null;
    }
  }

  // Clear all cached images
  static Future<void> clearAllCache() async {
    try {
      await cacheManager.emptyCache();
      if (kDebugMode) {
        print('🗑️ Cleared all cached images');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing image cache: $e');
      }
    }
  }

  // Get cache size info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cachePath = '${cacheDir.path}/$_cacheKey';
      final cacheDirFile = Directory(cachePath);
      
      if (!cacheDirFile.existsSync()) {
        return {
          'exists': false,
          'size_bytes': 0,
          'file_count': 0,
        };
      }

      int totalSize = 0;
      int fileCount = 0;
      
      await for (final entity in cacheDirFile.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
          fileCount++;
        }
      }

      return {
        'exists': true,
        'size_bytes': totalSize,
        'size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'file_count': fileCount,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  // Pre-cache shop logos and product images
  static Future<void> preCacheShopImages(List<dynamic> shops) async {
    final imageUrls = <String>[];
    
    for (final shop in shops) {
      if (shop is Map<String, dynamic>) {
        final logoUrl = shop['shopLogoUrl'] as String?;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          imageUrls.add(logoUrl);
        }
      } else {
        // Handle entity objects
        final logoUrl = shop.shopLogoUrl;
        if (logoUrl.isNotEmpty) {
          imageUrls.add(logoUrl);
        }
      }
    }
    
    await preCacheImages(imageUrls);
  }

  // Pre-cache product images
  static Future<void> preCacheProductImages(List<dynamic> products) async {
    final imageUrls = <String>[];
    
    for (final product in products) {
      if (product is Map<String, dynamic>) {
        final imageUrl = product['imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      } else {
        // Handle entity objects
        final imageUrl = product.imageUrl;
        if (imageUrl.isNotEmpty) {
          imageUrls.add(imageUrl);
        }
      }
    }
    
    await preCacheImages(imageUrls);
  }
}
