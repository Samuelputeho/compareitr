import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/all_products/all_products_bloc.dart';
import '../pages/product_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:compareitr/core/services/ad_mob_service.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';

class CategoryTile extends StatelessWidget {
  final String catName;
  final String imageUrl;
  final String storeName;

  static late AdMobService _adMobService;
  static InterstitialAd? _interstitialAd;
  static int _tapCount = 0;

  const CategoryTile({
    super.key,
    required this.catName,
    required this.imageUrl,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    // ADS DISABLED - Commented out to prevent ads from showing
    // Initialize AdMobService
    // _adMobService = context.read<AdMobService>();
    // _loadInterstitialAd(); // Ensure the interstitial ad is loaded

    return GestureDetector(
      onTap: () {
        _tapCount++;
        print('Category tile tapped $_tapCount times');

        if (_tapCount == 100) {
          _tapCount = 0; // Reset tap count
          // ADS DISABLED - Commented out to prevent ads from showing
          // _showInterstitialAd();
        }

        // Trigger the Bloc event to fetch products by category
        context.read<AllProductsBloc>().add(
              GetProductsByCategoryEvent(
                shopName: storeName,
                category: catName,
              ),
            );

        // Navigate to the ProductPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              shopName: storeName,
              categoryName: catName,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[850] 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: imageUrl.startsWith('http')
                    ? HiveImageWidget(
                        imageUrl: imageUrl,
                        hiveKey: 'categoryImage_${catName.hashCode}',
                        fit: BoxFit.contain,
                        errorWidget: const Icon(Icons.error),
                      )
                    : Image.asset(
                        imageUrl,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                catName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Load the interstitial ad - ADS DISABLED
  // static void _loadInterstitialAd() {
  //   InterstitialAd.load(
  //     adUnitId: _adMobService.interstitialAdUnitId!,
  //     request: const AdRequest(),
  //     adLoadCallback: InterstitialAdLoadCallback(
  //       onAdLoaded: (InterstitialAd ad) {
  //         _interstitialAd = ad;
  //         print('Interstitial ad loaded');
  //       },
  //       onAdFailedToLoad: (LoadAdError error) {
  //         _interstitialAd = null;
  //         print('Failed to load interstitial ad: $error');
  //       },
  //     ),
  //   );
  // }

  /// Show the interstitial ad - ADS DISABLED
  // static void _showInterstitialAd() {
  //   if (_interstitialAd != null) {
  //     _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
  //       onAdDismissedFullScreenContent: (InterstitialAd ad) {
  //         ad.dispose();
  //         _loadInterstitialAd(); // Load a new ad after the previous one is dismissed
  //       },
  //       onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
  //         ad.dispose();
  //         _loadInterstitialAd(); // Load a new ad after failure
  //         print('Failed to show interstitial ad: $error');
  //       },
  //     );
  //     _interstitialAd!.show();
  //     _interstitialAd = null; // Reset the interstitial ad
  //   } else {
  //     print('Interstitial ad not ready yet.');
  //   }
  // }
}
