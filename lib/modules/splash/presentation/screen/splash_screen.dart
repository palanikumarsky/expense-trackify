import 'package:expensetrackify/constants/asset_path.dart';
import 'package:expensetrackify/modules/bottom_navigation_bar/bottom_navigation_bar.dart';
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
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const CustomBottomNavigationBar(),
      ),
    );
    // Check user type
    // String userType = userTypeStream.currentUserType;
    // if (userType == AppConstants.loggedUser) {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(
    //       builder: (context) => const CustomBottomNavigationBar(),
    //     ),
    //   );
    // } else {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(
    //       builder: (context) => const LoginScreen(),
    //     ),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // color: Colors.deepPurple,
          color: const Color.fromRGBO(65, 26, 129, 1.0),
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
