import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

class PasswordDialog extends StatefulWidget {
  @override
  _PasswordDialogState createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm With Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Please enter your password to confirm this action:"),
          TextFormField(
            keyboardType: TextInputType.text,
            controller: _passwordController,
            obscureText:
                !_passwordVisible, // This will obscure text dynamically
            decoration: InputDecoration(
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).primaryColorDark,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, _passwordController.text);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
