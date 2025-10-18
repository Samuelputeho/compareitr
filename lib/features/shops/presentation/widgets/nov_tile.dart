import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';

class NovTile extends StatelessWidget {
  final String foodName;
  final String foodImage;
  final String foodPrice;
  final String foodQuantity;
  final String foodRating;
  final String foodShop;
  final VoidCallback onHeartTap;
  final VoidCallback onPlusTap;
  final VoidCallback onRemoveTap;
  final bool isInCart;
  final bool isSaved;

  const NovTile({
    super.key,
    required this.foodName,
    required this.foodImage,
    required this.foodPrice,
    required this.foodQuantity,
    required this.foodRating,
    required this.foodShop,
    required this.onHeartTap,
    required this.onPlusTap,
    required this.onRemoveTap,
    required this.isInCart,
    required this.isSaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onLongPress: onRemoveTap,
      child: Container(
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
                      imageUrl: foodImage,
                      hiveKey: 'recentImage_${foodName.hashCode}',
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onHeartTap,
                      child: Icon(
                        isSaved ? IconlyBold.heart : IconlyLight.heart,
                        color: isSaved ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onPlusTap,
                      child: isInCart
                          ? Icon(
                              IconlyBold.plus, // Bold "Add" icon
                              color: Colors.green, // Green color if in cart
                            )
                          : Icon(
                              IconlyLight.plus, // Regular "Add" icon
                              color: Colors.grey, // Regular color if not in cart
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      foodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 17,
                        ),
                        Text(foodRating),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      foodQuantity,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      foodShop,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.green.shade700 : Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  foodPrice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
