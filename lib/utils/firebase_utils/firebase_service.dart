import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  FirebaseService._privateConstructor();

  static final FirebaseService instance = FirebaseService._privateConstructor();

  final FirebaseFirestore fireStore = FirebaseFirestore.instance;
}