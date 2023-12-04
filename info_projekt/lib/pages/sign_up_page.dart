import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';
import 'package:info_projekt/widgets/toast.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/widgets/form_container_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController =
      TextEditingController(); // New controller

  bool isSigningUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("SignUp"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sign Up",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _confirmPasswordController,
                hintText: "Confirm Password",
                isPasswordField: true,
              ),
              SizedBox(height: 30),
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
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            "Sign Up",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  SizedBox(
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
                    child: Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

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
        Navigator.pushNamed(context, "/login");
      } else {
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        DocumentReference userDocRef = await firestore.collection('Users').add({
          'email': email,
          'UID': user.uid,
          'balance': '',
          'iban': '',
          'verified': true, // Update 'verified' to true upon email verification
        });

        CollectionReference transactionHistoryRef =
            userDocRef.collection('transaction_history');
        await transactionHistoryRef.add({
          'price': 00.00,
          'order_date': Timestamp.now(),
          'name': '',
          'symbol': '',
          'buy': 'false',
          'selling_price': 00.00,
          'quantity': 0,
          'total_cost': 0,
          'transaction_fee': 0,
        });

        CollectionReference balanceHistoryRef =
            userDocRef.collection('balance_history');
        await balanceHistoryRef.add({
          'amount': 00.00,
          'date': Timestamp.now(),
          'description': '',
          'withdraw': false,
        });

        showToast(message: "Email already verified. Please log in.");
        Navigator.pushNamed(context, "/login");
      }
    } else {
      // Error handling is already done in the signUpWithEmailAndPassword method.
      // So, no need to show an additional error message here.
    }
  }
}
