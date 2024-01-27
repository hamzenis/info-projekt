import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/pages/sign_up_page.dart';
import 'package:info_projekt/widgets/form_container_widget.dart';

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
        title: const Text(""),
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
              ),
              const SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
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
                    print(
                        "Is email registered: $isRegistered"); // Debugging log

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
                    print("Error: $e"); // Debugging log
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
        final User user = credential.user!;

        if (!user.emailVerified) {
          // Email is not verified
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Email not verified"),
              content: Text(
                  "A verification email has been sent to your email address. Please verify your email and try to login again."),
              actions: <Widget>[
                TextButton(
                  child: Text("Resend Email"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );

          await _auth.resendVerificationEmail();
        } else {
          Navigator.pushReplacementNamed(context, "/homePageNew");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        showToast(message: 'Invalid email or password.');
      } else {
        showToast(message: 'An error occurred: ${e.code}');
      }
    } finally {
      setState(() {
        _isSigning = false;
      });
    }
  }
}
