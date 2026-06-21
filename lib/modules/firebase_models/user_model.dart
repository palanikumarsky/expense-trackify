import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String email;
  final String photoUrl;
  final bool isActive;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.isActive,
  });

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      userId: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isActive': isActive,
    };
  }
}
