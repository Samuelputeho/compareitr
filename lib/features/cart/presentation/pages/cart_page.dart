import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/common/entities/cart_entity.dart';
import 'package:compareitr/core/common/entities/shop_entity.dart';
import 'package:compareitr/core/utils/show_snackbar.dart';
import 'package:compareitr/features/cart/presentation/widgets/cart_tile.dart';
import 'package:compareitr/features/location/presentation/pages/location_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:compareitr/features/cart/presentation/bloc/cart_bloc_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:compareitr/features/shops/presentation/bloc/all_shops/all_shops_bloc.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  BannerAd? _bannerAd;
  List<dynamic> _cartItemsWithAds = [];

  @override
  void initState() {
    super.initState();

    // Animation controller for color changes
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration for one blink cycle
    )..repeat(reverse: true); // Repeat the animation back and forth

    // Log the current user state
    final appUserState = context.read<AppUserCubit>().state;
    print("AppUserCubit State: $appUserState"); // Log the state

    if (appUserState is AppUserLoggedIn) {
      final cartId = appUserState.user.id; // Fetch the cartId from the logged-in user
      print("CartId: $cartId"); // Log the cartId

      // Dispatch GetCartItems event only if cartId is not empty
      if (cartId.isNotEmpty) {
        print("Dispatching GetCartItems event...");
        context.read<CartBloc>().add(GetCartItems(cartId: cartId));
      } else {
        print("CartId is empty, skipping GetCartItems event.");
      }
    } else {
      print("User is not logged in.");
    }

    // ADS DISABLED - Commented out to prevent ads from showing
    // Initialize the banner ad
    // _bannerAd = BannerAd(
    //   size: AdSize.fullBanner,
    //   adUnitId: context.read<AdMobService>().bannerAdUnitId!, // Use your actual ad unit ID
    //   request: AdRequest(),
    //   listener: BannerAdListener(
    //     onAdLoaded: (ad) {
    //       print('Banner Ad loaded successfully');
    //     },
    //     onAdFailedToLoad: (ad, error) {
    //       print('Banner Ad failed to load: $error');
    //       ad.dispose();
    //     },
    //   ),
    // )..load();
  }

  // ADS DISABLED - Simple function to populate cart items without ads
  void _addBannerAds(List<CartEntity> cartItems) {
    _cartItemsWithAds.clear(); // Clear the previous list
    for (int i = 0; i < cartItems.length; i++) {
      _cartItemsWithAds.add(cartItems[i]); // Add the cart item
      // No ads added - just cart items
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Dispose of the banner ad
    _controller.dispose();
    super.dispose();
  }


  // Get list of closed shops
  List<String> _getClosedShops(List<CartEntity> cartItems, List<dynamic> shops) {
    final closedShops = <String>[];
    print('🔍 Checking shop hours for ${cartItems.length} cart items against ${shops.length} shops');
    print('🕐 Current time: ${DateTime.now()}');
    
    for (final cartItem in cartItems) {
      print('🔍 Processing cart item: ${cartItem.shopName}');
      try {
        // Try exact match first, then case-insensitive match, then fuzzy matching
        dynamic shop;
        try {
          shop = shops.firstWhere((shop) => shop.shopName == cartItem.shopName);
          print('✅ Exact match found for: ${cartItem.shopName}');
        } catch (e) {
          print('❌ No exact match for: ${cartItem.shopName}');
          try {
            // If exact match fails, try case-insensitive match
            shop = shops.firstWhere((shop) => shop.shopName.toLowerCase() == cartItem.shopName.toLowerCase());
            print('✅ Case-insensitive match found for: ${cartItem.shopName}');
          } catch (e2) {
            print('❌ No case-insensitive match for: ${cartItem.shopName}');
            // Try fuzzy matching for common variations
            final cartShopLower = cartItem.shopName.toLowerCase();
            if (cartShopLower.contains('picknpay') || cartShopLower.contains('pick')) {
              // Try to find a shop that might be PickNPay
              shop = shops.firstWhere((shop) => 
                shop.shopName.toLowerCase().contains('pick') || 
                shop.shopName.toLowerCase().contains('pay'));
              print('✅ Fuzzy match found for: ${cartItem.shopName}');
            } else {
              // Re-throw the original exception
              throw e2;
            }
          }
        }
        
        print('🔍 Shop found: ${cartItem.shopName} -> ${shop.shopName}');
        print('🔍 Operating hours object: ${shop.operatingHours}');
        
        if (shop.operatingHours != null) {
          final operatingHours = shop.operatingHours!;
          print('🕐 Shop: ${cartItem.shopName}');
          print('   - Monday: ${operatingHours.weeklyHours['monday']?.openTime}-${operatingHours.weeklyHours['monday']?.closeTime} (${operatingHours.weeklyHours['monday']?.isOpen == true ? 'Open' : 'Closed'})');
          print('   - Tuesday: ${operatingHours.weeklyHours['tuesday']?.openTime}-${operatingHours.weeklyHours['tuesday']?.closeTime} (${operatingHours.weeklyHours['tuesday']?.isOpen == true ? 'Open' : 'Closed'})');
          print('   - Wednesday: ${operatingHours.weeklyHours['wednesday']?.openTime}-${operatingHours.weeklyHours['wednesday']?.closeTime} (${operatingHours.weeklyHours['wednesday']?.isOpen == true ? 'Open' : 'Closed'})');
          print('   - Thursday: ${operatingHours.weeklyHours['thursday']?.openTime}-${operatingHours.weeklyHours['thursday']?.closeTime} (${operatingHours.weeklyHours['thursday']?.isOpen == true ? 'Open' : 'Closed'})');
          print('   - Friday: ${operatingHours.weeklyHours['friday']?.openTime}-${operatingHours.weeklyHours['friday']?.closeTime} (${operatingHours.weeklyHours['friday']?.isOpen == true ? 'Open' : 'Closed'})');
          print('   - Saturday: ${operatingHours.weeklyHours['saturday']?.openTime}-${operatingHours.weeklyHours['saturday']?.closeTime} (${operatingHours.weeklyHours['saturday']?.isOpen == true ? 'Open' : 'Closed'})');
          print('   - Sunday: ${operatingHours.weeklyHours['sunday']?.openTime}-${operatingHours.weeklyHours['sunday']?.closeTime} (${operatingHours.weeklyHours['sunday']?.isOpen == true ? 'Open' : 'Closed'})');
          
          final isOpen = operatingHours.isCurrentlyOpen();
          print('🔍 Is shop open: $isOpen');
          
          if (!isOpen) {
            closedShops.add(cartItem.shopName);
            print('❌ Shop is closed: ${cartItem.shopName}');
          } else {
            print('✅ Shop is open: ${cartItem.shopName}');
          }
        } else {
          print('⚠️ No operating hours for shop: ${cartItem.shopName}');
          print('⚠️ Assuming shop is always open (no hours restriction)');
          // If no operating hours, assume shop is open (24/7)
        }
      } catch (e) {
        print('❌ Shop not found in shops list: ${cartItem.shopName}');
        print('❌ Available shops: ${shops.map((s) => s.shopName).toList()}');
        // Shop not found - assume open
        continue;
      }
    }
    
    print('🔍 Total closed shops found: ${closedShops.length}');
    
    // Summary of issues found
    final shopsWithoutHours = cartItems.where((item) {
      try {
        final shop = shops.firstWhere((shop) => shop.shopName == item.shopName);
        return shop.operatingHours == null;
      } catch (e) {
        return true; // Shop not found counts as no hours
      }
    }).map((item) => item.shopName).toList();
    
    if (shopsWithoutHours.isNotEmpty) {
      print('⚠️ Shops without operating hours data: $shopsWithoutHours');
      print('⚠️ These shops are assumed to be always open (24/7)');
    }
    
    return closedShops;
  }





  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appUserState = context.read<AppUserCubit>().state;
    if (appUserState is AppUserLoggedIn) {
      final cartId = appUserState.user.id;
      if (cartId.isNotEmpty) {
        context.read<CartBloc>().add(GetCartItems(cartId: cartId));
      }
    }
    
    // Load shops data for operating hours validation
    context.read<AllShopsBloc>().add(GetAllShopsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
              iconSize: 20,
            ),
          ),
        ),
        title: const Text('Cart'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.more_horiz_outlined),
                iconSize: 20,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          } else if (state is CartError) {
            return Center(child: Text(state.message));
          } else if (state is CartLoaded) {
            final cartItems = state.cartItems;

            // ADS DISABLED - Add cart items without ads
            // Add banner ads to the cart items
            _addBannerAds(cartItems);

            // Calculate subtotal (sum of products only)
            double subtotal = cartItems.fold(
                0, (sum, item) => sum + (item.price * item.quantity));
            
            // Calculate per-shop service fees
            double totalServiceFee = _calculatePerShopServiceFees(cartItems);
            
            // Calculate total (subtotal + total service fee)
            double totalPrice = subtotal + totalServiceFee;

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: _cartItemsWithAds.length,
                      separatorBuilder: (context, index) => SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        final item = _cartItemsWithAds[index];
                        if (item is CartEntity) {
                          return CartTile(
                            cartItem: item,
                            onRemove: () {
                              final cartId = item.cartId;
                              final productId = item.id;

                              if (cartId.isNotEmpty) {
                                context.read<CartBloc>().add(
                                  RemoveCartItem(
                                    cartId: cartId,
                                    productId: productId,
                                  ),
                                );
                              }
                            },
                            onIncrease: () {
                              context.read<CartBloc>().add(
                                UpdateCartItem(
                                  cartId: item.cartId,
                                  id: item.id,
                                  quantity: item.quantity + 1,
                                ),
                              );
                            },
                            onDecrease: () {
                              if (item.quantity > 1) {
                                context.read<CartBloc>().add(
                                  UpdateCartItem(
                                    cartId: item.cartId,
                                    id: item.id,
                                    quantity: item.quantity - 1,
                                  ),
                                );
                              } else {
                                context.read<CartBloc>().add(RemoveCartItem(
                                  cartId: item.cartId,
                                  productId: item.id,
                                ));
                              }
                            },
                          );
                        }
                        // ADS DISABLED - Commented out to prevent ads from showing
                        // else if (item is BannerAd) {
                        //   return Container(
                        //     height: 60,
                        //     child: AdWidget(ad: item),
                        //   );
                        // }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal:',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              'N\$ ${subtotal.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        Divider(height: 24, thickness: 1.5),
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'N\$ ${totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return ElevatedButton(
                              onPressed: () async {
                                print('🛒 Buy button pressed');
                                final cartState = context.read<CartBloc>().state;
                                if (cartState is CartLoaded) {
                                  print('🛒 Cart is loaded with ${cartState.cartItems.length} items');
                                  
                                  // Check if all shops are open
                                  final shopsState = context.read<AllShopsBloc>().state;
                                  print('🛒 Shops state: $shopsState');
                                  
                                  // If shops data is loaded, check for closed shops
                                  if (shopsState is AllShopsSuccess) {
                                    print('🛒 Shops data is loaded with ${shopsState.shops.length} shops');
                                    print('🛒 Cart items: ${cartState.cartItems.map((item) => item.shopName).toList()}');
                                    print('🛒 Available shops: ${shopsState.shops.map((shop) => shop.shopName).toList()}');
                                    
                                    final closedShops = _getClosedShops(cartState.cartItems, shopsState.shops);
                                    if (closedShops.isNotEmpty) {
                                      print('❌ Found closed shops: $closedShops');
                                      // Show snackbar instead of dialog for closed shops
                                      showSnackBar(context, 'Some shops in your cart are currently closed. Please try again when they are open.');
                                      return;
                                    } else {
                                      print('✅ All shops are open, proceeding to location page');
                                    }
                                  } else {
                                    // If shops data is not loaded yet, wait for it or show error
                                    print('⚠️ Shops data not loaded yet, state: $shopsState');
                                    showSnackBar(context, 'Loading shop information... Please try again in a moment.');
                                    return;
                                  }
                                  
                                  // All shops are open, proceed to location page
                                  print('🚀 Navigating to location page');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LocationSelectionPage(
                                        totalPrice: totalPrice,
                                        townCenter: const LatLng(-22.5609, 17.0658),
                                        cartItems: cartState.cartItems,
                                      ),
                                    ),
                                  );
                                } else {
                                  print('❌ Cart is not loaded, state: $cartState');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorTween(
                                  begin: Colors.green,
                                  end: Colors.black,
                                ).evaluate(_controller),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14.0),
                              ),
                              child: Text(
                                'Buy Through App',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('No items in cart.'));
        },
      ),
    );
  }

  /// Calculate service fees per shop based on each shop's service fee percentage
  double _calculatePerShopServiceFees(List<CartEntity> cartItems) {
    // Group cart items by shop
    Map<String, List<CartEntity>> itemsByShop = {};
    for (var item in cartItems) {
      itemsByShop.putIfAbsent(item.shopName, () => []).add(item);
    }

    double totalServiceFee = 0.0;
    
    // Get shops data to access service fee percentages
    final shopsState = context.read<AllShopsBloc>().state;
    List<ShopEntity> shops = [];
    
    if (shopsState is AllShopsSuccess) {
      shops = shopsState.shops;
    }

    // Calculate service fee for each shop
    for (var entry in itemsByShop.entries) {
      String shopName = entry.key;
      List<CartEntity> shopItems = entry.value;
      
      // Calculate subtotal for this shop
      double shopSubtotal = shopItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
      
      // Find the shop to get its service fee percentage
      double shopServiceFeePercentage = 15.0; // Default fallback
      
      try {
        final shop = shops.firstWhere((shop) => shop.shopName == shopName);
        shopServiceFeePercentage = shop.serviceFeePercentage;
        print('🏪 Shop: $shopName, Service Fee: ${shopServiceFeePercentage}%');
      } catch (e) {
        print('⚠️ Shop not found: $shopName, using default 15%');
        // Use default percentage if shop not found
      }
      
      // Calculate service fee for this shop
      double shopServiceFee = shopSubtotal * (shopServiceFeePercentage / 100);
      totalServiceFee += shopServiceFee;
      
      print('💰 Shop: $shopName, Subtotal: N\$${shopSubtotal.toStringAsFixed(2)}, Service Fee: N\$${shopServiceFee.toStringAsFixed(2)} (${shopServiceFeePercentage}%)');
    }

    print('💳 Total Service Fee: N\$${totalServiceFee.toStringAsFixed(2)}');
    return totalServiceFee;
  }
}