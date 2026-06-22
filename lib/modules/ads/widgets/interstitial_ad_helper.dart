import 'package:expensetrackify/modules/ads/ads_service.dart';

class InterstitialAdHelper {
  static final InterstitialAdHelper _instance = InterstitialAdHelper._internal();
  factory InterstitialAdHelper() => _instance;
  InterstitialAdHelper._internal();

  int _actionCount = 0;
  static const int _showAdAfterActions = 5; // Show ad after every 5 actions

  /// Track user actions and show interstitial ad periodically
  Future<void> trackActionAndShowAd({
    required String actionName,
    Function()? onAdShown,
    Function()? onAdFailed,
  }) async {
    _actionCount++;
    
    // Show ad after every N actions
    if (_actionCount >= _showAdAfterActions) {
      _actionCount = 0; // Reset counter
      
      await AdsService().showInterstitialAd(
        onAdLoaded: () {
        },
        onAdFailedToLoad: () {
          onAdFailed?.call();
        },
        onAdClosed: () {
          onAdShown?.call();
        },
      );
    }
  }

  /// Show interstitial ad immediately
  Future<void> showAdNow({
    required String actionName,
    Function()? onAdShown,
    Function()? onAdFailed,
  }) async {
    await AdsService().showInterstitialAd(
      onAdLoaded: () {
      },
      onAdFailedToLoad: () {
        onAdFailed?.call();
      },
      onAdClosed: () {
        onAdShown?.call();
      },
    );
  }

  /// Reset action counter
  void resetActionCounter() {
    _actionCount = 0;
  }

  /// Get current action count
  int get actionCount => _actionCount;
} 