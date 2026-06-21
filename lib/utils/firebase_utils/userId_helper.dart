import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

class UserIDHelper {
  /// Converts a user email to a Base64-encoded Firestore-safe document ID
  String encodeUserID(String email) {
    return base64Url.encode(utf8.encode(email));
  }

  /// Decodes the Base64-encoded document ID back to the original email
  String decodeUserID(String encoded) {
    return utf8.decode(base64Url.decode(encoded));
  }

  /// Converts an email address into a Firestore-safe document ID
  /// using Base36 encoding (only a-z and 0-9, no special characters).
  String emailToBase36(String email) {
    final bytes = utf8.encode(email);
    final bigInt = BigInt.parse(
      bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join(),
      radix: 2,
    );
    return bigInt.toRadixString(36); // Firestore-safe alphanumeric ID
  }

  String generateUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid; // Use this as your collection/document ID
    return userId ?? "";
  }
}