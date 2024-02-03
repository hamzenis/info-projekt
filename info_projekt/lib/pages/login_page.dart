import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/disableLogIn_service.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/pages/sign_up_page.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:info_projekt/widgets/form_container_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isSigning = false;
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();
  final DisableLogIn _disableLogIn = DisableLogIn();
  final _firestore = FirebaseFirestore.instance;

  bool? isDisabled = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              const Spacer(),
              const Text(
                "Login",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
                inputType: TextInputType.visiblePassword,
              ),
              InkWell(
                onTap: () async {
                  if (_emailController.text.isEmpty) {
                    showToast(message: "Please enter your email address.");
                    return;
                  }
                  try {
                    // Check if the email is registered
                    bool isRegistered =
                        await _auth.isEmailRegistered(_emailController.text);
                    if (isRegistered) {
                      await _firebaseAuth.sendPasswordResetEmail(
                          email: _emailController.text);
                      showToast(message: "Password reset email sent.");
                    } else {
                      showToast(
                          message: "This email address is not registered.");
                    }
                  } catch (e) {
                    showToast(message: "An error occurred: $e");
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  alignment: Alignment.topRight,
                  child: const Text(
                    'Forgot Password ?',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey,
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {
                  _signIn();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _isSigning
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      UserCredential? credential =
          await _auth.signInWithEmailAndPassword(email, password);

      if (credential != null && credential.user != null) {
        // Reset disableCounter on succesfull Login
        await _disableLogIn.updateDisableCounter(credential.user!.uid, 0);

        final User user = credential.user!;

        if (!user.emailVerified) {
          if (!mounted) return;
          // Email is not verified
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Email not verified"),
              content: const Text(
                  "A verification email has been sent to your email address. Please verify your email and try to login again."),
              actions: <Widget>[
                TextButton(
                  child: const Text("Resend Email"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );

          await _auth.resendVerificationEmail();
        } else {
          if (mounted) {
            Navigator.pushReplacementNamed(context, "/homePageNew");
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String email = _emailController.text.trim();

      if (e.code == 'wrong-password') {
        showToast(message: 'Invalid password.');
        var disableUserUri = Uri.parse(
            //"http://127.0.0.1:5050/wrong_password");
            "http://134.119.216.59:5050/wrong_password");
        try {
          var response = await http.post(
            disableUserUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          );

          if (response.statusCode == 202) {
            await _firestore.collection("mail").add({
              'to': email,
              'template': {
                'name': "activate",
                'data': {
                  'reactivate_link':
                      //"http://127.0.0.1:5050/reset?email=$email",
                      "http://134.119.216.59:5050/reset?email=$email",
                },
              },
            });
          }
        } catch (e) {
          print(e);
        }
      }
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        showToast(message: 'Invalid email or password.');
      } else if (e.code == 'too-many-requests' || e.code == 'user-disabled') {
        showToast(message: 'An error occoured: ${e.code}');
      }
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }
}
