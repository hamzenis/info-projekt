import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/services/firestore_service.dart';

//this class handles the authentification of a user in the database.

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService firestoreService = FirestoreService();
  final LoginPage logInPage = const LoginPage();

//counts failed tries (in a row) to log in; reset when successfull log in
  bool? isDisabled = false;
  String? userEmail;

//handles the sign up and checks if there is already a user registered with the email adress
  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showToast(message: 'The email address is already in use.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      userEmail = email;

      return credential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  Future<void> resendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      final List<String> userSignInMethods =
          await _auth.fetchSignInMethodsForEmail(email);
      //print("User sign-in methods: $userSignInMethods");
      return userSignInMethods.isNotEmpty;
    } catch (e) {
      //print("Firebase error: $e");
      return false;
    }
  }

  Future<bool> reauthenticateUser(String? password) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (password != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        try {
          await user.reauthenticateWithCredential(credential);
          return true;
        } catch (e) {
          showToast(message: "Incorrect password");
          return false;
        }
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  //allows to identify user with his ID by email
  Future<String?> getUidByEmail(String email) async {
    try {
      final result = await _auth.fetchSignInMethodsForEmail(email);
      //print("UID by email: $result");
      if (result.isNotEmpty) {
        // print("UID by email if: ${result[0]}");
        var user = _auth.currentUser;
        return user?.uid;
      }
    } catch (e) {
      //print('Error getting UID by email: $e');
      return null;
    }
    return null;
  }
}
