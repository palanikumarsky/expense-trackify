import 'package:expensetrackify/constants/app_constants.dart';
import 'package:expensetrackify/constants/asset_path.dart';
import 'package:expensetrackify/modules/bottom_navigation_bar/bottom_navigation_bar.dart';
import 'package:expensetrackify/modules/profile/presentation/screen/login_screen.dart';
import 'package:expensetrackify/utils/user_type_stream.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isStoredAsLoggedIn =
        userTypeStream.currentUserType == AppConstants.loggedUser;
    final hasFirebaseSession = FirebaseAuth.instance.currentUser != null;

    if (isStoredAsLoggedIn && hasFirebaseSession) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CustomBottomNavigationBar(),
        ),
      );
    } else {
      // Heal stale SharedPreferences state if Firebase session is gone
      if (isStoredAsLoggedIn && !hasFirebaseSession) {
        await userTypeStream.setUserType(AppConstants.guest);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(65, 26, 129, 1.0),
        ),
        child: Center(
          child: Image.asset(
            PngAssets.splashBgImagePng,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
