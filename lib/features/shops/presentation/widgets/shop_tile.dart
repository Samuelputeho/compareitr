import 'package:flutter/material.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';

class ShopTile extends StatelessWidget {
  final String shopName;
  final String shopLogo;
  final GestureTapCallback? onTap; // Changed to GestureTapCallback?

  const ShopTile({
    super.key,
    required this.shopName,
    required this.shopLogo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: Container(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: HiveImageWidget(
                imageUrl: shopLogo,
                hiveKey: 'shopLogo_${shopName.hashCode}',
                height: 100,
                width: 100,
                fit: BoxFit.contain,
                errorWidget: const Icon(Icons.error, size: 100, color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
