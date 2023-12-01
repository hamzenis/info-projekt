  import 'dart:async';  // Import for Timer
  import 'package:flutter/material.dart';
  import 'package:info_projekt/services/firebase_auth_services.dart';  // Import FirebaseAuthService
  import 'package:info_projekt/widgets/toast.dart';  // Import showToast

  class VerifyEmailPage extends StatefulWidget {
    @override
    _VerifyEmailPageState createState() => _VerifyEmailPageState();
  }

  class _VerifyEmailPageState extends State<VerifyEmailPage> {
    final FirebaseAuthService _auth = FirebaseAuthService();  // FirebaseAuthService instance
    bool _isButtonDisabled = false;

void _onResendEmail() async {
  if (_isButtonDisabled) {
    print("Button is currently disabled"); // Debug print
    return;
  }

  setState(() {
    _isButtonDisabled = true;
  });

  try {
    await _auth.resendVerificationEmail();
    showToast(message: "Verification email sent again and you can resend it again in 60 seconds",durationInSeconds: 5);
  } catch (e) {
    print("Error in sending email: $e"); // Log any exceptions
  }

  // Set a timer for 60 seconds
  Timer(Duration(seconds: 60), () {
    setState(() {
      _isButtonDisabled = false;
    });
    print("Button is re-enabled"); // Debug print
  });
} 


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify Email")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "A verification email has been sent to your email address.",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                ),
                icon: Icon(Icons.email, size: 32),
                label: Text(
                  'Resend Email',
                  style: TextStyle(fontSize: 24),
                ),
                onPressed: _isButtonDisabled ? null : _onResendEmail,
              ),
              SizedBox(height: 8),
              TextButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 24),
                ),
                onPressed: () => Navigator.pushNamed(context, "/login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
