import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/firebase_config/firebase_options.dart';
import 'modules/splash/presentation/screen/splash_screen.dart';
import 'utils/pref.dart';
import 'utils/user_type_stream.dart';
import 'package:expensetrackify/constants/app_constants.dart';
import 'modules/ads/ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Prefs.loadTheme();
  await Prefs.loadCurrency();
  
  // Initialize user type stream
  await userTypeStream.initialize();
  
  // Initialize Google Mobile Ads
  await AdsService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Prefs.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            brightness: Brightness.light,
            cardColor: Colors.grey[100],
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
            brightness: Brightness.dark,
            cardColor: Colors.grey[900],
          ),
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
