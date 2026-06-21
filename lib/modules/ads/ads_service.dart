import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  // Test ad unit IDs - Replace with your actual ad unit IDs
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Test ID
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  
  // Production ad unit IDs (uncomment and replace when ready for production)
  // static const String _bannerAdUnitId = 'your-production-banner-ad-unit-id';
  // static const String _interstitialAdUnitId = 'your-production-interstitial-ad-unit-id';

  bool _isInitialized = false;

  /// Initialize Google Mobile Ads
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('Google Mobile Ads initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize Google Mobile Ads: $e');
    }
  }

  /// Get banner ad unit ID based on platform
  String getBannerAdUnitId() {
    if (kDebugMode) {
      return _bannerAdUnitId;
    }
    // For production, you might want different IDs for different platforms
    return _bannerAdUnitId;
  }

  /// Get interstitial ad unit ID
  String getInterstitialAdUnitId() {
    if (kDebugMode) {
      return _interstitialAdUnitId;
    }
    return _interstitialAdUnitId;
  }

  /// Create a banner ad
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
      ),
    );
  }

  /// Create an interstitial ad
  InterstitialAd? createInterstitialAd({
    required Function() onAdLoaded,
    required Function() onAdFailedToLoad,
    required Function() onAdClosed,
  }) {
    InterstitialAd? interstitialAd;
    
    InterstitialAd.load(
      adUnitId: getInterstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          onAdLoaded();
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              onAdClosed();
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          onAdFailedToLoad();
        },
      ),
    );
    
    return interstitialAd;
  }

  /// Show interstitial ad
  Future<void> showInterstitialAd({
    required Function() onAdLoaded,
    required Function() onAdFailedToLoad,
    required Function() onAdClosed,
  }) async {
    final interstitialAd = createInterstitialAd(
      onAdLoaded: onAdLoaded,
      onAdFailedToLoad: onAdFailedToLoad,
      onAdClosed: onAdClosed,
    );
    
    if (interstitialAd != null) {
      await interstitialAd.show();
    }
  }

  /// Dispose ads
  void dispose() {
    // This method can be used to dispose any cached ads if needed
  }
} 