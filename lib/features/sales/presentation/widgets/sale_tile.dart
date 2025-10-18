import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';

class SaleTile extends StatelessWidget {
  final String productName;
  final String productImage;
  final String currentPrice;
  final String oldPrice;
  final String saveAmount;
  final String measure;
  final String storeName;
  final VoidCallback onHeartTap;
  final VoidCallback onPlusTap;
  final bool isInCart;
  final bool isSaved;

  const SaleTile({
    super.key,
    required this.productName,
    required this.productImage,
    required this.currentPrice,
    required this.oldPrice,
    required this.saveAmount,
    required this.measure,
    required this.storeName,
    required this.onHeartTap,
    required this.onPlusTap,
    required this.isInCart,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.width * 0.7,
      width: MediaQuery.of(context).size.width * 0.43,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.35,
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: HiveImageWidget(
                    imageUrl: productImage,
                    hiveKey: 'saleProductImage_${productName.hashCode}',
                    fit: BoxFit.contain,
                  ),
                ),
                // Save amount badge (top-left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Save $saveAmount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                // Heart icon (save/like) - top-right
                Positioned(
                  top: 8,
                  right: 40,
                  child: GestureDetector(
                    onTap: onHeartTap,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? IconlyBold.heart : IconlyLight.heart,
                        color: isSaved ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Plus icon (add to cart) - top-right corner
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onPlusTap,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isInCart ? IconlyBold.plus : IconlyLight.plus,
                        color: isInCart ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Product name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          // Measure and store name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  measure,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Flexible(
                  child: Text(
                    storeName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Price container at bottom
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.green.shade700 : Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Old price (struck through)
                Text(
                  oldPrice,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                // Current price
                Text(
                  currentPrice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

