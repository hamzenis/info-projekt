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
    showToast(message: 'An error occurred: ${e.code}');
    return null; // Immediately return to avoid executing further lines
  }
}

Future<User?> signInWithEmailAndPassword(String email, String password) async {
  try {
    UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    User? user = credential.user;

    // Check if the user's email is verified
    if (user != null && !user.emailVerified) {
      showToast(message: 'Please verify your email address.');
      return null; // Stop further execution
    }

    return user; // Email is verified, return the user
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
      showToast(message: 'Invalid email or password.');
    } else {
      showToast(message: 'An error occurred: ${e.code}');
    }
    return null; // Stop further execution after handling the exception
  }
}

}
