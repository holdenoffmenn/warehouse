import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'solicitacoes_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() {
    if (_formKey.currentState!.validate()) {
      if (_emailController.text == 'admin' && _passwordController.text == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitacoesPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid credentials')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warehouse, size: 100, color: Colors.white)
                      .animate()
                      .fadeIn(duration: 1000.ms)
                      .slideY(begin: -1.0, end: 0.0),
                  SizedBox(height: 20),
                  Text(
                    'Warehouse Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ).animate().fadeIn(duration: 1200.ms).slideX(begin: 1.0, end: 0.0),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(duration: 1400.ms).slideX(begin: -1.0, end: 0.0),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ).animate().fadeIn(duration: 1600.ms).slideX(begin: 1.0, end: 0.0),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                    ),
                  ).animate().fadeIn(duration: 1800.ms).slideY(begin: 1.0, end: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
