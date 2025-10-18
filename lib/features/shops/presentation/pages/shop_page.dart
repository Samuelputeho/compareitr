import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/services/ad_mob_service.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';
import 'package:compareitr/features/cart/presentation/bloc/cart_bloc_bloc.dart';
import 'package:compareitr/features/recently_viewed/presentation/bloc/recent_bloc.dart';
import 'package:compareitr/features/saved/presentation/bloc/saved_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

import '../bloc/all_categories/all_categories_bloc.dart';
import '../bloc/all_shops/all_shops_bloc.dart';
import '../widgets/nov_tile.dart';
import '../widgets/shop_tile.dart';
import 'categories_page.dart';
import 'package:compareitr/features/card_swiper/presentation/bloc/bloc/card_swiper_bloc.dart';


// Ensure this model is defined
// Adjust the import based on your project structure

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late Timer _timer;
  late AdMobService _adMobService;
  BannerAd? _banner;
  InterstitialAd? _interstitial;
  int _shopTileClickCount = 0;
  int _totalImages = 0; // Track the total number of images

  @override
  void initState() {
    super.initState();
    final recentId = (context.read<AppUserCubit>().state as AppUserLoggedIn)
        .user
        .id; 
        final cartId = (context.read<AppUserCubit>().state as AppUserLoggedIn)
        .user
        .id; 
        context.read<CartBloc>().add(GetCartItems(cartId: cartId));// Get user ID
    
    // Only fetch recently viewed items if not already loaded (like cart behavior)
    final recentState = context.read<RecentBloc>().state;
    if (recentState is! RecentLoaded) {
      context.read<RecentBloc>().add(GetRecentItems(recentId: recentId));
    }
    
    context.read<AllShopsBloc>().add(GetAllShopsEvent());
    final savedId = (context.read<AppUserCubit>().state as AppUserLoggedIn)
        .user
        .id; // Get user ID
    context
        .read<SavedBloc>()
        .add(GetSavedItems(savedId: savedId));

    context.read<AllCategoriesBloc>().add(GetAllCategoriesEvent());
    context
        .read<CardSwiperBloc>()
        .add(GetAllCardSwiperPicturesEvent()); // Fetch card swiper pictures
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      // Only auto-swipe if we have images loaded
      if (_totalImages > 0) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _totalImages; // Use dynamic image count
        });

        if (_currentIndex < _totalImages && _pageController.hasClients) {
          // Ensure this matches the actual number of pages and controller is attached
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      }
    });

    // ADS DISABLED - Commented out to prevent ads from showing
    // _adMobService = context.read<AdMobService>();
    // _createInterstitialAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ADS DISABLED - Commented out to prevent ads from showing
    // _adMobService = context.read<AdMobService>();
    // _adMobService.initialization.then((value) {
    //   print('AdMob initialized successfully'); // Log initialization
    //   setState(() {
    //     _banner = BannerAd(
    //       size: AdSize.fullBanner,
    //       adUnitId: _adMobService.bannerAdUnitId!,
    //       listener: BannerAdListener(
    //         onAdLoaded: (ad) {
    //           print('Banner Ad loaded successfully'); // Log successful load
    //         },
    //         onAdFailedToLoad: (ad, error) {
    //           print('Banner Ad failed to load: $error'); // Log load failure
    //           ad.dispose(); // Dispose of the ad if it fails to load
    //         },
    //       ),
    //       request: AdRequest(),
    //     )..load();
    //     _createInterstitialAd();
    //   });
    // });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _interstitial?.dispose();
    super.dispose();
  }

  void _showRemoveDialog(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Item'),
          content: Text('Are you sure you want to remove this item from recently viewed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final recentId = (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
                context.read<RecentBloc>().add(RemoveRecentlyItem(recentId: recentId, id: itemId)); // Dispatch the remove event
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    const double imageHeight = 150.0;
    const double dotSize = 12.0;
    const double dotSpacing = 8.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Sales container
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: double.infinity,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey.shade800 
                        : const Color.fromARGB(255, 219, 217, 217),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: BlocBuilder<CardSwiperBloc, CardSwiperState>(
                    builder: (context, state) {
                      if (state is CardSwiperLoading) {
                        return Center(child: CircularProgressIndicator(color: Colors.green));
                      } else if (state is CardSwiperFailure) {
                        return Center(child: Text(state.message));
                      } else if (state is CardSwiperSuccess) {
                        // Update the total images count for the timer
                        _totalImages = state.pictures.length;
                        
                        return PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: state.pictures.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: HiveImageWidget(
                                imageUrl: state.pictures[index].image,
                                hiveKey: 'cardSwiperImage_$index',
                                fit: BoxFit.fill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        );
                      }
                      return Center(child: Text('No images available'));
                    },
                  ),
                ),
                // Refresh button for card swiper
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        context.read<CardSwiperBloc>().add(RefreshCardSwiperPicturesEvent());
                      },
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Refresh card swiper images',
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  child: BlocBuilder<CardSwiperBloc, CardSwiperState>(
                    builder: (context, state) {
                      if (state is CardSwiperSuccess) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              List.generate(state.pictures.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: dotSpacing / 2),
                              width: _currentIndex == index
                                  ? dotSize
                                  : dotSize - 4,
                              height: _currentIndex == index
                                  ? dotSize
                                  : dotSize - 4,
                              decoration: BoxDecoration(
                                color: _currentIndex == index
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        );
                      }
                      return const SizedBox(); // Handle other states if necessary
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            BlocBuilder<RecentBloc, RecentState>(
              builder: (context, state) {
                final itemCount = state is RecentLoaded ? state.recentItems.length : 0;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          'Recently Viewed${itemCount > 0 ? ' ($itemCount)' : ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (itemCount > 0)
                          TextButton.icon(
                            onPressed: () {
                              _showClearAllDialog(context);
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        IconButton(
                          onPressed: () {
                            final recentId = (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
                            context.read<RecentBloc>().add(RefreshRecentItems(recentId: recentId));
                          },
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Refresh recently viewed items',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 15),
            BlocBuilder<RecentBloc, RecentState>(
              builder: (context, state) {
                if (state is RecentLoading) {
                  return Center(child: CircularProgressIndicator(color: Colors.green));
                } else if (state is RecentError) {
                  return Center(child: Text(state.message));
                } else if (state is RecentLoaded) {
                  final recentItems = state.recentItems.reversed.toList();
                  if (recentItems.isEmpty) {
                    return const Center(
                        child: Text('No recently viewed items'));
                  }
                  return SizedBox(
                    height: MediaQuery.of(context).size.width * 0.7,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentItems.length,
                      itemBuilder: (context, index) {
                        final item = recentItems[index];
                        return BlocBuilder<CartBloc, CartState>(
                          builder: (context, cartState) {
                            bool isInCart = false;
                            if (cartState is CartLoaded) {
                              isInCart = cartState.cartItems.any((cartItem) =>
                                cartItem.itemName == item.name &&
                                cartItem.shopName == item.shopName &&
                                cartItem.price == item.price
                              );
                            }

                            return BlocBuilder<SavedBloc, SavedState>(
                              builder: (context, savedState) {
                                bool isSaved = false;
                                if (savedState is SavedLoaded) {
                                  isSaved = savedState.savedItems.any((savedItem) =>
                                    savedItem.name == item.name &&
                                    savedItem.shopName == item.shopName &&
                                    savedItem.price == item.price
                                  );
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: NovTile(
                                    foodImage: item.image,
                                    foodName: item.name,
                                    foodPrice: 'N\$${item.price.toStringAsFixed(2)}',
                                    foodQuantity: item.measure,
                                    foodRating: '5.0',
                                    foodShop: item.shopName,
                                    isInCart: isInCart,
                                    isSaved: isSaved,
                                    onHeartTap: () async {
                                      try {
                                        // Fetch saved items from the bloc
                                        final savedItemsState =
                                            context.read<SavedBloc>().state;

                                        // Check if the state is loaded
                                        if (savedItemsState is SavedLoaded) {
                                          // Check if the item already exists in the saved items
                                          final exists = savedItemsState.savedItems
                                              .any((savedItem) {
                                            return savedItem.name == item.name &&
                                                savedItem.price == item.price;
                                          });

                                          if (exists) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                  content:
                                                      Text('Product is already added')),
                                            );
                                          } else {
                                            final savedId = (context
                                                    .read<AppUserCubit>()
                                                    .state as AppUserLoggedIn)
                                                .user
                                                .id;
                                            // Dispatch the AddSavedItem event to the bloc
                                            context.read<SavedBloc>().add(AddSavedItem(
                                                  name: item.name,
                                                  image: item.image,
                                                  measure: item.measure,
                                                  shopName: item.shopName,
                                                  savedId:
                                                      savedId, // Use your specific savedId here
                                                  price: item.price,
                                                ));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'Product added to saved items')),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Failed to fetch saved items')),
                                          );
                                        }
                                      } catch (e) {
                                        // Log the error
                                        print(
                                            'Error occurred while adding item to saved: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('An error occurred: $e')),
                                        );
                                      }
                                    },
                                    onPlusTap: () async {
                                      try {
                                        // Get cart state
                                        final cartState = context.read<CartBloc>().state;
                                        
                                        if (cartState is CartLoaded) {
                                          // Check if item already exists in cart
                                          final exists = cartState.cartItems.any((cartItem) =>
                                            cartItem.itemName == item.name &&
                                            cartItem.shopName == item.shopName &&
                                            cartItem.price == item.price
                                          );

                                          if (exists) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Product is already in cart')),
                                            );
                                          } else {
                                            // Get user ID for cart
                                            final cartId = (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
                                            
                                            // Add item to cart
                                            context.read<CartBloc>().add(AddCartItem(
                                              cartId: cartId,
                                              itemName: item.name,
                                              shopName: item.shopName,
                                              imageUrl: item.image,
                                              price: item.price,
                                              quantity: 1,
                                              measure: item.measure,
                                            ));

                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Product added to cart')),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        print('Error adding item to cart: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('An error occurred: $e')),
                                        );
                                      }
                                    },
                                    onRemoveTap: () {
                                      print('Removing item with ID: ${item.id}');
                                      _showRemoveDialog(context, item.id);
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  );
                }
                return const Center(child: Text('No recently viewed items'));
              },
            ),
            const SizedBox(height: 20),

            BlocBuilder<AllShopsBloc, AllShopsState>(
              builder: (context, state) {
                if (state is AllShopsSuccess) {
                  final allShopTypes = AllShopsBloc.getAllShopTypes();
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade700 
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).cardColor,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: state.currentFilter,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All'),
                          ),
                          ...allShopTypes.map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          )),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue == null) {
                            context.read<AllShopsBloc>().add(ClearShopFilterEvent());
                          } else {
                            context.read<AllShopsBloc>().add(FilterShopsByTypeEvent(shopType: newValue));
                          }
                        },
                        dropdownColor: Theme.of(context).cardColor,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  );
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade700 
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).cardColor,
                  ),
                  child: const Text(
                    'All',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            BlocBuilder<AllShopsBloc, AllShopsState>(
              builder: (context, state) {
                if (state is AllShopsLoading) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        childAspectRatio: 1,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.loadingShops.length,
                      itemBuilder: (context, index) {
                        final shop = state.loadingShops[index];
                        return ShopTile(
                          onTap: () {},
                          shopName: shop.shopName,
                          shopLogo: shop.shopLogoUrl,
                        );
                      },
                    ),
                  );
                }

                if (state is AllShopsSuccess) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        childAspectRatio: 1,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.shops.length,
                      itemBuilder: (context, index) {
                        final shop = state.shops[index];
                        return ShopTile(
                          onTap: () {
                            _shopTileClickCount++;
                            if (_shopTileClickCount == 100) {
                              // ADS DISABLED - Commented out to prevent ads from showing
                              // _showInterstitialAd();
                              _shopTileClickCount = 0;
                            }
                            context.read<AllCategoriesBloc>().add(
                              GetCategoriesByShopNameEvent(shopName: shop.shopName),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoriesPage(
                                  storeName: shop.shopName,
                                ),
                              ),
                            );
                          },
                          shopName: shop.shopName,
                          shopLogo: shop.shopLogoUrl,
                        );
                      },
                    ),
                  );
                }

                if (state is AllShopsFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<AllShopsBloc>().add(GetAllShopsEvent());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(
                  child: Text('No shops available'),
                );
              },
            ),
            // ADS DISABLED - Commented out to prevent ads from showing
            // if(_banner == null)
            //   const SizedBox(height: 1,)
            // else 
            // Column(
            //   children: [
            //     const SizedBox(height: 10,),
            //     Container( 
            //       height: 60,
            //       child: AdWidget(ad: _banner!),
            //     ),
            //   ],
            // ),
          ],
        ),
      );
  }

// ADS DISABLED - Commented out to prevent ads from showing
// void _createInterstitialAd() {
//   InterstitialAd.load(
//     adUnitId: _adMobService.interstitialAdUnitId!,
//     request: AdRequest(),
//     adLoadCallback: InterstitialAdLoadCallback(
//       onAdLoaded: (InterstitialAd ad) {
//         _interstitial = ad; // Store the loaded ad
//       },
//       onAdFailedToLoad: (LoadAdError error) {
//         _interstitial = null; // Set to null if loading fails
//         print('Interstitial ad failed to load: $error');
//       },
//     ),
//   );
// }

// ADS DISABLED - Commented out to prevent ads from showing
// void _showInterstitialAd() {
//   if (_interstitial != null ) {
//     _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (InterstitialAd ad) {
//         ad.dispose();
//         _createInterstitialAd();
//       },
//       onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
//         ad.dispose();
//         _createInterstitialAd();
//       },
//     );
//     _interstitial!.show();
//     _interstitial = null;
//   } else {
//     print('Interstitial ad is not ready or the user is ad-free.');
//   }
// }
  
  // Show confirmation dialog before clearing all recently viewed items
  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Clear All?',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to clear all recently viewed items? This action cannot be undone.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final recentId = (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;
              context.read<RecentBloc>().add(ClearAllRecentItems(recentId: recentId));
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ All recently viewed items cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}