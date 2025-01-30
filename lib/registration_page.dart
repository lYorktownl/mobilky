import 'package:flutter/material.dart';
import 'users_page.dart';

class RegistrationPage extends StatelessWidget {
  final Function(User) onRegister;

  const RegistrationPage({required this.onRegister, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController loginController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: loginController,
              decoration: InputDecoration(labelText: 'Login'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    loginController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  final newUser = User(
                    name: nameController.text,
                    login: loginController.text,
                    password: passwordController.text,
                  );
                  onRegister(newUser);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}