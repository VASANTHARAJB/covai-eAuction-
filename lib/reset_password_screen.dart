// lib/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Required for Timer
import 'login_screen.dart';

const Color royalBlue = Color(0xFF002366);

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  
  // TIMER VARIABLES
  late Timer _timer;
  int _start = 300; // 5 minutes in seconds
  bool _isExpired = false;

  final String _baseUrl = "https://neoerainfotech.com/Covai/api/";

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer.cancel(); // Clean up timer to prevent memory leaks
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _isExpired = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String get timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, [bool isError = true]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _isStrongPassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
        .hasMatch(password);
  }

  Future<void> _resetPassword() async {
    if (_isExpired) {
      _showSnackBar('OTP has expired. Please request a new one.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}reset_password.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp_code": widget.otp,
          "new_password": _newPasswordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        _showSnackBar('Password reset successful!', false);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        _showSnackBar(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _showSnackBar('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Set New Password'),
        backgroundColor: royalBlue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.lock_reset_rounded, size: 80, color: royalBlue),
                const SizedBox(height: 10),
                
                // TIMER UI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isExpired ? Colors.red.shade50 : royalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: _isExpired ? Colors.red : royalBlue),
                      const SizedBox(width: 8),
                      Text(
                        _isExpired ? "OTP EXPIRED" : "Expires in: $timerText",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isExpired ? Colors.red : royalBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                const Text(
                  'Create New Password',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: royalBlue),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: _inputDecoration('New Password', _obscureNew, 
                      () => setState(() => _obscureNew = !_obscureNew)),
                  validator: (value) => (value == null || !_isStrongPassword(value)) 
                      ? 'Password too weak' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: _inputDecoration('Confirm Password', _obscureConfirm, 
                      () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  validator: (value) => (value != _newPasswordController.text) 
                      ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isExpired) ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isExpired ? Colors.grey : royalBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('RESET PASSWORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (_isExpired)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Request New OTP", style: TextStyle(color: Colors.red)),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, bool obscure, VoidCallback onToggle) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline, color: royalBlue),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: royalBlue),
        onPressed: onToggle,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}