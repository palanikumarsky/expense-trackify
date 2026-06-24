import 'package:flutter/material.dart';

import 'modules/splash/presentation/screen/splash_screen.dart';
import 'utils/pref.dart';
import 'package:expensetrackify/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.loadTheme();
  await Prefs.loadCurrency();
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
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
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
