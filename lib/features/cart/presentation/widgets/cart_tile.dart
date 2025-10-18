import 'package:flutter/material.dart';
import 'package:compareitr/core/common/entities/cart_entity.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';

class CartTile extends StatelessWidget {
  final CartEntity cartItem;
  final Function() onRemove;
  final Function() onIncrease;
  final Function() onDecrease;

  const CartTile({
    Key? key,
    required this.cartItem,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate total price for this item
    double totalPrice = cartItem.price * cartItem.quantity;

    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[850] 
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product Image
          SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HiveImageWidget(
              imageUrl: cartItem.imageUrl,
              hiveKey: 'cartImage_${cartItem.itemName.hashCode}',
              width: 80,
              height: 95,
              fit: BoxFit.fitHeight,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        cartItem.itemName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.close, color: Colors.grey),
      onPressed: onRemove,
    ),
  ],
),
                  Text(
                    cartItem.shopName,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'N\$ ${totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          cartItem.measure.isNotEmpty ? cartItem.measure : 'Unit',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: onDecrease,
                              child: Container(
                                width: 22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.grey.shade600 
                                        : Colors.grey,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '-',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${cartItem.quantity}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(width: 4),
                            GestureDetector(
                              onTap: onIncrease,
                              child: Container(
                                width: 22,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.green.shade700 
                                      : Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '+',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
