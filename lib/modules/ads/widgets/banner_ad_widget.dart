import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;

  const BannerAdWidget({
    super.key,
    this.height,
    this.margin,
    this.showBorder = false,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = AdsService().createBannerAd();
    _bannerAd!.load().then((_) {
      if (mounted) {
        setState(() {
          _isLoaded = true;
          _isLoading = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoaded = false;
          _isLoading = false;
        });
      }
      debugPrint('Banner ad failed to load: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height ?? 50,
        margin: widget.margin,
        decoration: widget.showBorder
            ? BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height ?? 50,
      margin: widget.margin,
      decoration: widget.showBorder
          ? BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: AdWidget(ad: _bannerAd!),
    );
  }
} 