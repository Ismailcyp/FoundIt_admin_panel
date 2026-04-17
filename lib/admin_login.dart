import 'package:flutter/material.dart';
import 'package:yalla_admin_panel/admin_home.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  final String _adminEmail = "smsm";
  final String _adminPassword = "admin";

  // Colors
  final Color _bgColor = const Color.fromARGB(255, 38, 2, 58);
  final Color _inputBgColor = const Color(0xFF1B1B28);
  final Color _primaryPurple = const Color(0xFF6E56FF);
  final Color _textSecondary = const Color(0xFF8E8E9F);

  void _handleLogin() {
    setState(() => _errorMessage = null);

    if (_emailController.text.trim() == _adminEmail && 
        _passwordController.text == _adminPassword) {
      // SUCCESS: Push to the Admin Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHome()), 
      );
    } else {
      // FAIL: Show error
      setState(() {
        _errorMessage = "Invalid admin credentials";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400, // Keeps it looking good on desktop/web
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: _inputBgColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(Icons.admin_panel_settings, size: 64, color: _primaryPurple),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'Admin Portal',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: "syne"),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field
                const Text('Email', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'admin@yallasafqa.com',
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
                    filled: true,
                    fillColor: _inputBgColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                const Text('Password', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
                    filled: true,
                    fillColor: _inputBgColor,
                    errorText: _errorMessage,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _handleLogin(), // Allows pressing 'Enter' to log in
                ),
                const SizedBox(height: 40),

                // Login Button
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Access Dashboard', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}