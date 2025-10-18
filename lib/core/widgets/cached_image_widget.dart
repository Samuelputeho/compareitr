import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:compareitr/core/services/image_cache_service.dart';
import 'package:compareitr/core/common/cache/cache.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheManager: ImageCacheService.cacheManager,
        placeholder: (context, url) => placeholder ?? _buildPlaceholder(context),
        errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(context),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 40,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.7),
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 40,
      ),
    );
  }
}

class CachedCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? child;

  const CachedCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: imageUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                cacheManager: ImageCacheService.cacheManager,
                placeholder: (context, url) => _buildPlaceholder(context),
                errorWidget: (context, url, error) => _buildErrorWidget(context),
              ),
            )
          : child ?? _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Icon(
      Icons.person_outline,
      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
      size: radius,
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Icon(
      Icons.person_off_outlined,
      color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.7),
      size: radius,
    );
  }
}

class OfflineAwareImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const OfflineAwareImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: _buildOfflinePlaceholder(context),
      errorWidget: _buildOfflineErrorWidget(context),
    );
  }

  Widget _buildOfflinePlaceholder(BuildContext context) {
    final isOffline = CacheManager.isOffline;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffline ? Icons.cloud_off_outlined : Icons.image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: (width != null && height != null) 
                ? (width! < height! ? width! * 0.3 : height! * 0.3)
                : 30,
          ),
          if (isOffline) ...[
            const SizedBox(height: 4),
            Text(
              'Offline',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfflineErrorWidget(BuildContext context) {
    final isOffline = CacheManager.isOffline;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isOffline 
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffline ? Icons.cloud_off_outlined : Icons.broken_image_outlined,
            color: isOffline
                ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)
                : Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.7),
            size: (width != null && height != null) 
                ? (width! < height! ? width! * 0.3 : height! * 0.3)
                : 30,
          ),
          if (isOffline) ...[
            const SizedBox(height: 4),
            Text(
              'No cached image',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

