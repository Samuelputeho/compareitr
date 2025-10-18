import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/widgets/hive_image_widget.dart';
import 'package:compareitr/features/recently_viewed/presentation/bloc/recent_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/common/entities/product_entity.dart';
import '../../presentation/pages/product_details_page.dart'; // Import the ProductDetailsPage
import '../../../../core/services/ad_mob_service.dart'; // Import your AdMobService

class ProductTile extends StatelessWidget {
  final ProductEntity product;

  static late AdMobService _adMobService;
  static InterstitialAd? _interstitialAd;
  static int _tapCount = 0;

  const ProductTile({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    // ADS DISABLED - Commented out to prevent ads from showing
    // _adMobService = context.read<AdMobService>(); // Initialize AdMobService
    // _loadInterstitialAd(); // Ensure the interstitial ad is loaded

    return GestureDetector(
      onTap: () {
        _tapCount++;
        print('Product tile tapped: $_tapCount times');

        if (_tapCount == 100) {
          _tapCount = 0; // Reset tap count
          // ADS DISABLED - Commented out to prevent ads from showing
          // _showInterstitialAd(); // Show the interstitial ad
        }

        final recentId =
            (context.read<AppUserCubit>().state as AppUserLoggedIn).user.id;

        // Simply add the product to recently viewed - the bloc will handle duplicates
        context.read<RecentBloc>().add(AddRecentItem(
          name: product.name,
          image: product.imageUrl,
          measure: product.measure,
          shopName: product.shopName,
          recentId: recentId,
          price: product.price,
        ));

        // Navigate to the ProductDetailsPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[850] 
                    : Colors.grey[200],
              ),
              child: Padding(
                padding: EdgeInsets.all(5),
                child: HiveImageWidget(
                  imageUrl: product.imageUrl,
                  hiveKey: 'productImage_${product.name.hashCode}',
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                product.name,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'N\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ADS DISABLED - Commented out to prevent ads from showing
  // static void _loadInterstitialAd() {
  //   InterstitialAd.load(
  //     adUnitId: _adMobService.interstitialAdUnitId!,
  //     request: const AdRequest(),
  //     adLoadCallback: InterstitialAdLoadCallback(
  //       onAdLoaded: (InterstitialAd ad) {
  //         _interstitialAd = ad;
  //         print('Interstitial ad loaded successfully');
  //       },
  //       onAdFailedToLoad: (LoadAdError error) {
  //         _interstitialAd = null;
  //         print('Failed to load interstitial ad: $error');
  //       },
  //     ),
  //   );
  // }

  // ADS DISABLED - Commented out to prevent ads from showing
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
