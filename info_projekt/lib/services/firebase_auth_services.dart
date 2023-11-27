import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/widgets/toast.dart';

class FirebaseAuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;

Future<User?> signUpWithEmailAndPassword(String email, String password) async {
  try {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = credential.user;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
    return user;
  } on FirebaseAuthException catch (e) {
    // Handle exceptions
  }
  return null;
}


Future<User?> signInWithEmailAndPassword(String email, String password) async {
  try {
    UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    User? user = credential.user;
    if (user != null && !user.emailVerified) {
      showToast(message: 'Please verify your email address.');
      return null; // Prevent login if not verified
    }
    return user;
  } on FirebaseAuthException catch (e) {
    // Handle exceptions
  }
  return null;
}

}
