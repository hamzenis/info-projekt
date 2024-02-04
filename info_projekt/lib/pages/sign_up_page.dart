import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/widgets/form_container_widget.dart';
import 'package:info_projekt/services/firestore_service.dart';

//This class handles the sign-up of a new user to the application

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  FirestoreService firestoreService = FirestoreService();
  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isSigningUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/tradematelogo_long.png',
                height: kIsWeb ? 100 : 50,
                width: 500,
              ),
              const SizedBox(height: 20),
              const Text(
                "Sign Up",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _confirmPasswordController,
                hintText: "Confirm Password",
                isPasswordField: true,
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  _signUp();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isSigningUp
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                          (route) => false);
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

//checks for the validity of the user password. password has to fullfill the following criteria:
//at least 8 characters long, contain uppercase and lowercase letters, special character, number
  bool isPasswordValid(String password) {
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;

    return hasUppercase &&
        hasDigits &&
        hasLowercase &&
        hasSpecialCharacters &&
        hasMinLength;
  }

  void _signUp() async {
    setState(() {
      isSigningUp = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;
    //Registration date gets stored in the database and shown in profile
    DateTime now = DateTime.now();
    String registrationDate = now.toString();

    if (password != confirmPassword) {
      showToast(message: "Passwords do not match.");
      setState(() {
        isSigningUp = false;
      });
      return;
    }

    if (!isPasswordValid(password)) {
      showToast(
        message:
            "Password must be at least 8 characters long and include at least one uppercase letter, one number, and one special character.",
      );
      setState(() {
        isSigningUp = false;
      });
      return;
    }

    final NavigatorState navigator = Navigator.of(context);

    User? user = await _auth.signUpWithEmailAndPassword(email, password);

    setState(() {
      isSigningUp = false;
    });

    if (user != null) {
      if (!user.emailVerified) {
        showToast(
          message:
              "Registration successful! Please check your email to verify your account.",
        );
        navigator.pushNamed("/verifyEmail");

        await firestoreService.saveUserDataToFirestore(email, registrationDate);
      } else {
        showToast(message: "Email already verified. Please log in.");
        navigator.pushNamed("/login");
      }
    } else {
      // Error handling is already done in the signUpWithEmailAndPassword method.
      // So, no need to show an additional error message here.
    }
  }
}
