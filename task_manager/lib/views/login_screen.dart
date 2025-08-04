import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager/views/task_list_screen.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: () => _authenticate(context),
                child: Text(_isLogin ? 'Login' : 'Register'),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _errorMessage = null;  // Clear the error message when switching modes
                  });
                },
                child: Text(_isLogin ? 'Create an account' : 'Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _authenticate(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text;
    final password = _passwordController.text;
    final isLogin = _isLogin;

    final navigator = Navigator.of(context);
    Theme.of(context);

    setState(() => _errorMessage = null);

    final errorMessage = isLogin
        ? await authProvider.signInWithEmailAndPassword(email, password)
        : await authProvider.registerWithEmailAndPassword(email, password);

    if (errorMessage != null) {
      setState(() {
        _errorMessage = errorMessage;
      });
    } else {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const TaskListScreen()),
      );
    }
  }
}
