import 'package:flutter/material.dart';
import 'package:FoundIt_admin_panel/admin_home.dart';

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

  final Color _primaryColor = const Color(0xFFB5E575);
  final Color _textColor = const Color(0xFF1E1E1E);
  final Color _bgColor = const Color(0xFFF9F9F9); 

  void _handleLogin() {
    setState(() => _errorMessage = null);

    if (_emailController.text.trim() == _adminEmail && 
        _passwordController.text == _adminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHome()), 
      );
    } else {
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
            width: 400, 
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.admin_panel_settings_outlined, size: 56, color: Colors.green[800]),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Admin Portal',
                    style: TextStyle(color: _textColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildLabel('Admin ID / Email'),
                TextField(
                  controller: _emailController,
                  style: TextStyle(color: _textColor),
                  decoration: _getInputDecoration(hintText: 'admin@foundit.com'),
                ),
                const SizedBox(height: 24),

                _buildLabel('Password'),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: _textColor),
                  decoration: _getInputDecoration(
                    hintText: '••••••••', 
                    errorText: _errorMessage
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Access Dashboard', 
                      style: TextStyle(color: Colors.green[900], fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.w700, 
          color: Colors.grey.shade800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration({required String hintText, String? errorText}) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
      ),
    );
  }
}