import 'package:expensetrackify/config/firebase_config/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseHandler {
  static final FirebaseHandler _instance =
  FirebaseHandler._internal();

  //create private constructor
  FirebaseHandler._internal();

  factory FirebaseHandler() {
    return _instance;
  }

  late FirebaseAuth firebaseAuth;
  late FirebaseAnalytics firebaseAnalytics;
  late FirebaseAnalyticsObserver firebaseAnalyticsObserver;

  Future<void> initializeFirebase() async {
    debugPrint("Singleton instance method called");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAuth = FirebaseAuth.instance;
    firebaseAnalytics = FirebaseAnalytics.instance;
    firebaseAnalyticsObserver =
        FirebaseAnalyticsObserver(analytics: firebaseAnalytics);
  }
}
