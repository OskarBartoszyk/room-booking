// lib/auth/registration_screen.dart
import 'package:flutter/material.dart';
import 'package:zpo/auth/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _errorMessage;

  void _register() async {
    setState(() {
      _errorMessage = null;
    });

    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      setState(() {
        _errorMessage = "Imię i nazwisko są wymagane.";
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Hasła nie pasują do siebie.";
      });
      return;
    }

    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        _firstNameController.text,
        _lastNameController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rejestracja przebiegła pomyślnie!')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Błąd rejestracji: ${e.toString().replaceAll('Exception: ', '')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarejestruj się'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dołącz do nas!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Imię',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwisko',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Potwierdź Hasło',
                  prefixIcon: Icon(Icons.lock_outline),
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
                onPressed: _register,
                child: const Text('Zarejestruj się'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Masz już konto? Zaloguj się',
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