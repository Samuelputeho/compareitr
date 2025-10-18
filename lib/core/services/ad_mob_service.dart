import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  Future<InitializationStatus> initialization;

  AdMobService(this.initialization);

  // Feature flag to enable/disable ads - set to false to disable all ads
  static const bool _adsEnabled = false; // TODO: Set to true when AdMob account is reactivated

  bool get areAdsEnabled => _adsEnabled;

  String? get bannerAdUnitId {
    if (kReleaseMode) {
      if (Platform.isIOS) {
        return "ca-app-pub-8299342896498209/6662644139";
      } else if (Platform.isAndroid) {
        return "ca-app-pub-8299342896498209/8714092406";
      }
    } else {
      if (Platform.isIOS) {
        return "ca-app-pub-3940256099942544/2934735716";
      } else if (Platform.isAndroid) {
        return "ca-app-pub-3940256099942544/6300978111";
      }
    }
    return null;
  }

  String? get interstitialAdUnitId {
    if (kReleaseMode) {
      if (Platform.isIOS) {
        return "ca-app-pub-8299342896498209/8727337176";
      } else if (Platform.isAndroid) {
        return "ca-app-pub-8299342896498209/6019376806";
      }
    } else {
      if (Platform.isIOS) {
        return "ca-app-pub-3940256099942544/4411468910";
      } else if (Platform.isAndroid) {
        return "ca-app-pub-3940256099942544/1033173712";
      }
    }
    return null;
  }

  String? get rewardAdUnitId {
    if (kReleaseMode) {
      if (Platform.isIOS) {
        return "ca-app-pub-8299342896498209/4897866823";
      } else if (Platform.isAndroid) {
        return "ca-app-pub-8299342896498209/9153076100";
      }
    } else {
      if (Platform.isIOS) {
        return "ca-app-pub-3940256099942544/1712485313";
      } else if (Platform.isAndroid) {
        return "ca-app-pub-3940256099942544/5224354917";
      }
    }
    return null;
  }

  final BannerAdListener bannerListener = BannerAdListener(
    onAdLoaded: (Ad ad) => print('Ad loaded.'),
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      ad.dispose();
      print('Ad failed to load: $error');
    },
    onAdOpened: (Ad ad) => print('Ad opened.'),
    onAdClosed: (Ad ad) => print('Ad closed.'),
  );

}