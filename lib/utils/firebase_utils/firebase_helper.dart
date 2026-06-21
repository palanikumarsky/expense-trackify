

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetrackify/modules/firebase_models/user_model.dart';
import 'package:expensetrackify/utils/firebase_utils/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FireStoreService {
  final FirebaseFirestore _db = FirebaseService.instance.fireStore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createOrUpdateFirebaseUserProfile(UserModel user) async {
    try {
      final usersCollection = _db.collection('users');

      CollectionReference users = FirebaseFirestore.instance.collection('users');
      QuerySnapshot querySnapshot = await users.where('email', isEqualTo: user.email).get();

      if (querySnapshot.docs.isNotEmpty) {
        await usersCollection.doc(user.userId).update(user.toMap());
      } else {
        // Create new user profile
        await usersCollection.doc(user.userId).set(user.toMap());
      }
    } catch (error) {
      print('Error creating/updating Firebase user profile: $error');
      // Don't throw error to avoid breaking the sign-in flow
    }
  }

  Future<void> deactivateFirebaseUserProfile(String userUid) async {
    try {
      final usersCollection = _db.collection('users');
      await usersCollection.doc(userUid).update({
        'isActive': false,
      });
      print('Firebase user profile deactivated successfully for UID: $userUid');
    } catch (error) {
      print('Error deactivating Firebase user profile: $error');
      // Don't throw error to avoid breaking the sign-out flow
    }
  }
}