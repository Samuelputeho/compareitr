import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/features/cart/presentation/bloc/cart_bloc_bloc.dart';
import 'package:compareitr/features/sales/presentation/bloc/saleproducts_bloc.dart';
import 'package:compareitr/features/sales/presentation/widgets/sale_tile.dart';
import 'package:compareitr/features/saved/presentation/bloc/saved_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SaleDetailsPage extends StatefulWidget {
  final String? storeName;
  final DateTime? startDate;
  final DateTime? endDate;

  const SaleDetailsPage({
    Key? key,
    required this.storeName,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _SaleDetailsPageState createState() => _SaleDetailsPageState();
}

class _SaleDetailsPageState extends State<SaleDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch the event to get products when the page is initialized
    context.read<SaleProductBloc>().add(GetAllSaleProductsEvent());
  }

  // Helper function to check if date ranges exactly match
  bool isDateRangeExactMatch(
      DateTime productStartDate, DateTime productEndDate) {
    final widgetStartDate = widget.startDate ?? DateTime.now();
    final widgetEndDate = widget.endDate ?? DateTime.now();

    return productStartDate.isAtSameMomentAs(widgetStartDate) &&
           productEndDate.isAtSameMomentAs(widgetEndDate);
  }

  Widget buildProductCard(dynamic product) {
    final double price = product.price?.toDouble() ?? 0.0;
    final double oldPrice = product.oldprice?.toDouble() ?? 0.0;
    final double saveAmount = oldPrice - price;

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        bool isInCart = false;
        if (cartState is CartLoaded) {
          isInCart = cartState.cartItems.any((cartItem) =>
            cartItem.itemName == product.name &&
            cartItem.shopName == product.storeName &&
            cartItem.price == price
          );
        }

        return BlocBuilder<SavedBloc, SavedState>(
          builder: (context, savedState) {
            bool isSaved = false;
            if (savedState is SavedLoaded) {
              isSaved = savedState.savedItems.any((savedItem) =>
                savedItem.name == product.name &&
                savedItem.shopName == product.storeName &&
                savedItem.price == price
              );
            }

            return SaleTile(
              productName: product.name ?? 'No Name',
              productImage: product.image ?? '',
              currentPrice: 'N\$${price.toStringAsFixed(2)}',
              oldPrice: 'N\$${oldPrice.toStringAsFixed(2)}',
              saveAmount: 'N\$${saveAmount.toStringAsFixed(2)}',
              measure: product.measure ?? '',
              storeName: product.storeName ?? '',
              isInCart: isInCart,
              isSaved: isSaved,
              onHeartTap: () async {
                try {
                  final savedItemsState = context.read<SavedBloc>().state;

                  if (savedItemsState is SavedLoaded) {
                    final exists = savedItemsState.savedItems.any((savedItem) =>
                      savedItem.name == product.name &&
                      savedItem.shopName == product.storeName &&
                      savedItem.price == price
                    );

                    if (exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product is already saved')),
                      );
                    } else {
                      final savedId = (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
                      context.read<SavedBloc>().add(AddSavedItem(
                        name: product.name ?? '',
                        image: product.image ?? '',
                        measure: product.measure ?? '',
                        shopName: product.storeName ?? '',
                        savedId: savedId,
                        price: price,
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added to saved items')),
                      );
                    }
                  }
                } catch (e) {
                  print('Error saving item: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              },
              onPlusTap: () async {
                try {
                  final cartState = context.read<CartBloc>().state;

                  if (cartState is CartLoaded) {
                    final exists = cartState.cartItems.any((cartItem) =>
                      cartItem.itemName == product.name &&
                      cartItem.shopName == product.storeName &&
                      cartItem.price == price
                    );

                    if (exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product is already in cart')),
                      );
                    } else {
                      final cartId = (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
                      
                      context.read<CartBloc>().add(AddCartItem(
                        cartId: cartId,
                        itemName: product.name ?? '',
                        shopName: product.storeName ?? '',
                        imageUrl: product.image ?? '',
                        price: price,
                        quantity: 1,
                        measure: product.measure ?? '',
                      ));

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added to cart')),
                      );
                    }
                  }
                } catch (e) {
                  print('Error adding to cart: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: $e')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.storeName ?? 'Sale Details'),
      ),
      body: BlocBuilder<SaleProductBloc, SaleproductsState>(
        builder: (context, state) {
          if (state is SaleproductsLoading) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          } else if (state is SaleproductsFailure) {
            return Center(child: Text(state.message));
          } else if (state is SaleproductsSuccess) {
            final filteredProducts = state.saleProducts.where((product) {
              debugPrint('Checking product: ${product.name}');

              // Ensure the store name matches or is null
              if (product.storeName != widget.storeName) {
                debugPrint('Product store mismatch: ${product.storeName}');
                return false; // Skip product if store name does not match
              }

              // Ensure the product's date range is valid and exactly matches
              if (product.startDate == null || product.endDate == null) {
                debugPrint('Product has missing date range: ${product.name}');
                return false; // Skip product if dates are missing
              }

              // Check if the product's sale period exactly matches the selected date range
              if (!isDateRangeExactMatch(product.startDate!, product.endDate!)) {
                debugPrint('Date range does not exactly match for product: ${product.name}');
                return false; // Skip product if date range doesn't exactly match
              }

              return true; // If both store and date range match exactly, include the product
            }).toList();

            if (filteredProducts.isEmpty) {
              return const Center(child: Text('No matching products available.'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.65,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return buildProductCard(filteredProducts[index]);
              },
            );
          }
          return const Center(child: Text('No products available.'));
        },
      ),
    );
  }
}
