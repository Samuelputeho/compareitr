import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HiveImageWidget extends StatefulWidget {
  final String imageUrl;
  final String hiveKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const HiveImageWidget({
    super.key,
    required this.imageUrl,
    required this.hiveKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<HiveImageWidget> createState() => _HiveImageWidgetState();
}

class _HiveImageWidgetState extends State<HiveImageWidget> {
  Widget? _cachedWidget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(HiveImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.hiveKey != widget.hiveKey) {
      _cachedWidget = null;
      _isLoading = true;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      // First try to get from Hive (for offline use)
      // Try both boxes since images might be stored in different boxes
      Box? box = Hive.box('shops');
      var base64Image = box.get(widget.hiveKey);
      
      // If not found in shops box, try recently_viewed box
      if (base64Image == null) {
        box = Hive.box('recently_viewed');
        base64Image = box.get(widget.hiveKey);
      }
      
      // If still not found, try user_cache box
      if (base64Image == null) {
        box = Hive.box('user_cache');
        base64Image = box.get(widget.hiveKey);
      }
      
      if (base64Image != null && base64Image is String) {
        final bytes = base64Decode(base64Image);
        if (mounted) {
          setState(() {
            _cachedWidget = Image.memory(
              Uint8List.fromList(bytes),
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
            );
            _isLoading = false;
          });
        }
        return;
      }
      
      // If not in Hive, use network image
      if (mounted) {
        setState(() {
          _cachedWidget = CachedNetworkImage(
            imageUrl: widget.imageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            placeholder: (context, url) => widget.placeholder ?? _buildPlaceholder(context),
            errorWidget: (context, url, error) => widget.errorWidget ?? _buildErrorWidget(context),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedWidget = Container(
            width: widget.width,
            height: widget.height,
            color: Colors.red.withOpacity(0.3),
            child: Icon(Icons.error_outline),
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: _isLoading 
        ? (widget.placeholder ?? _buildPlaceholder(context))
        : (_cachedWidget ?? _buildErrorWidget(context)),
    );
  }


  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[250],
      child: Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        size: (widget.width != null && widget.height != null) 
            ? (widget.width! < widget.height! ? widget.width! * 0.4 : widget.height! * 0.4)
            : 40,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.onErrorContainer,
        size: (widget.width != null && widget.height != null) 
            ? (widget.width! < widget.height! ? widget.width! * 0.4 : widget.height! * 0.4)
            : 40,
      ),
    );
  }
}
