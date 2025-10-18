import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../bloc/all_products/all_products_bloc.dart';
import '../bloc/all_categories/all_categories_bloc.dart';
import '../widgets/product_tile.dart';
import 'package:compareitr/core/services/ad_mob_service.dart';

class ProductPage extends StatefulWidget {
  final String categoryName;
  final String shopName;

  const ProductPage({
    super.key,
    required this.categoryName,
    required this.shopName,
  });

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  String? selectedSubCategory = 'All';
  static late AdMobService _adMobService;
  InterstitialAd? _interstitialAd; // Make this instance non-static
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    // ADS DISABLED - Commented out to prevent ads from showing
    // _adMobService = context.read<AdMobService>();
    // _loadInterstitialAd(); // Preload the interstitial ad

    context.read<AllProductsBloc>().add(
          GetProductsByCategoryEvent(
            shopName: widget.shopName,
            category: widget.categoryName,
          ),
        );
    context.read<AllCategoriesBloc>().add(
          GetCategoriesByShopNameEvent(shopName: widget.shopName),
        );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose(); // Properly dispose of the ad
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<AllCategoriesBloc, AllCategoriesState>(
          builder: (context, state) {
            if (state is CategoriesByShopNameSuccess) {
              return PopupMenuButton<String>(
                initialValue: widget.categoryName,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.categoryName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                onSelected: (String newCategory) {
                  // Increment tap count and show ad if applicable
                  if (newCategory != widget.categoryName) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductPage(
                          categoryName: newCategory,
                          shopName: widget.shopName,
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) {
                  return state.categories.map((category) {
                    return PopupMenuItem<String>(
                      value: category.categoryName,
                      child: Text(category.categoryName),
                    );
                  }).toList();
                },
              );
            }
            return Text(
              widget.categoryName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          BlocBuilder<AllProductsBloc, AllProductsState>(
            builder: (context, state) {
              final List<String> subCategories =
                  state is GetProductsByCategorySuccess
                      ? state.subCategories
                      : (state is GetProductsBySubCategorySuccess
                          ? AllProductsBloc.subCategories
                          : []);

              if (subCategories.isNotEmpty) {
                final allSubCategories = ['All', ...subCategories];

                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allSubCategories.length,
                    itemBuilder: (context, index) {
                      final subCategory = allSubCategories[index];
                      final isSelected = selectedSubCategory == subCategory;

                      return GestureDetector(
                        onTap: () {
                           // Increment tap count and show ad if applicable
                          setState(() {
                            selectedSubCategory = subCategory;
                          });

                          if (subCategory == 'All') {
                            context.read<AllProductsBloc>().add(
                                  GetProductsByCategoryEvent(
                                    shopName: widget.shopName,
                                    category: widget.categoryName,
                                  ),
                                );
                          } else {
                            context.read<AllProductsBloc>().add(
                                  GetProductsBySubCategoryEvent(
                                    shopName: widget.shopName,
                                    category: widget.categoryName,
                                    subCategory: subCategory,
                                  ),
                                );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.all(3.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green
                                : (Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.grey[850] 
                                    : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              subCategory,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 15,
                                color: isSelected 
                                    ? Colors.white 
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return const SizedBox(height: 0);
            },
          ),
          Expanded(
            child: BlocBuilder<AllProductsBloc, AllProductsState>(
              builder: (context, state) {
                if (state is GetProductsByCategorySuccess ||
                    state is GetProductsBySubCategorySuccess) {
                  final products = state is GetProductsByCategorySuccess
                      ? state.products
                      : (state as GetProductsBySubCategorySuccess).products;

                  if (products.isEmpty) {
                    return const Center(
                      child: Text('No products found'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                       // Increment tap count when navigating products
                      return ProductTile(product: products[index]);
                    },
                  );
                } else if (state is GetProductsByCategoryLoading ||
                    state is GetProductsBySubCategoryLoading) {
                  return Center(child: CircularProgressIndicator(color: Colors.green));
                } else if (state is GetProductsByCategoryFailure ||
                    state is GetProductsBySubCategoryFailure) {
                  final message = state is GetProductsByCategoryFailure
                      ? (state as GetProductsByCategoryFailure).message
                      : (state as GetProductsBySubCategoryFailure).message;
                  return Center(child: Text(message));
                }
                return Center(child: CircularProgressIndicator(color: Colors.green));
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Load the interstitial ad - ADS DISABLED
  // void _loadInterstitialAd() {
  // print('Attempting to load interstitial ad...');
  // InterstitialAd.load(
  //   adUnitId: _adMobService.interstitialAdUnitId!,
  //   request: const AdRequest(),
  //   adLoadCallback: InterstitialAdLoadCallback(
  //     onAdLoaded: (InterstitialAd ad) {
  //       print('Interstitial ad loaded successfully.');
  //       _interstitialAd = ad;
  //     },
  //     onAdFailedToLoad: (LoadAdError error) {

  //       print('Failed to load interstitial ad: $error');
  //       _interstitialAd = null;
  //        // Reset the interstitial ad instance
  //     },
  //   ),
  // );
  // }

// ADS DISABLED - Commented out to prevent ads from showing
// void _showInterstitialAd() {
//   if (_interstitialAd != null) {
//     print('Showing interstitial ad...');
//     _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (InterstitialAd ad) {
//         print('Interstitial ad dismissed.');
//         ad.dispose();
//         _loadInterstitialAd(); // Reload the ad after it is dismissed
//       },
//       onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
//         print('Failed to show interstitial ad: $error');
//         ad.dispose();
//         _loadInterstitialAd();
//       },
//     );
//     _interstitialAd!.show();
//     _interstitialAd = null; // Reset the ad instance after showing
//   } else {
//     print('Interstitial ad is not ready yet.');
//   }
// }

// ADS DISABLED - Commented out to prevent ads from showing
// void _incrementTapAndShowAd() {
//   _tapCount++;
//   print('Tap count incremented: $_tapCount');
//   if (_tapCount >= 100) {
//     _tapCount = 0; // Reset tap count
//     _showInterstitialAd();
//   }
// }

}