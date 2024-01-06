import 'package:flutter/material.dart';

class PasswordDialog extends StatefulWidget {
  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Password'),
      content: TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(labelText: 'Password'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
                context); // Close the dialog without returning any value
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context,
                _passwordController.text); // Return the password to the caller
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
