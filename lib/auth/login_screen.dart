import 'package:flutter/material.dart';
import 'package:zpo/admin/admin_panel_screen.dart'; 
import 'package:zpo/auth/auth_service.dart';
import 'package:zpo/auth/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;

  void _login() async {
    setState(() {
      _errorMessage = null;
    });

   
    if (_emailController.text.trim() == 'admin@gmail.com' &&
        _passwordController.text.trim() == 'AdminPassword!') {

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
      );
      return; 
    }
 
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

    } catch (e) {
      setState(() {
        _errorMessage =
            "Błąd logowania: ${e.toString().replaceAll('Exception: ', '')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zaloguj się'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Witaj z powrotem!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Hasło',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Zaloguj się'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Nie masz konta? Zarejestruj się',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}