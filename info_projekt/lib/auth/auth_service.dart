import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      return userCredential.user;
    } catch (e) {
      print('Error during registration: $e');
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified before allowing login
      if (userCredential.user?.emailVerified ?? false) {
        return userCredential.user;
      } else {
        print('Email not verified.');
        return null;
      }
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;

      // Reauthenticate user with old password before changing password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user?.email ?? '',
        password: oldPassword,
      );

      await user?.reauthenticateWithCredential(credential);

      // Change password
      await user?.updatePassword(newPassword);

      return true; // Password changed successfully
    } catch (e) {
      print('Error changing password: $e');
      return false; // Failed to change password
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
