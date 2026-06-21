import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  // static User? user = FirebaseHandler().firebaseAuth.currentUser;

  static Future<User?> loginWithGoogle() async {
    await GoogleSignIn().signOut(); // to sign out from any hanging auths.
    final GoogleSignIn googleSignIn =
    GoogleSignIn(scopes: ["profile", "email"]);
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    }
    return null;
  }

  static Future<bool> signOut() async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }
}