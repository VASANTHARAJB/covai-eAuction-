// lib/otp_verification.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Required for Countdown Timer

// Import your main home/shell screen
import 'home_screen.dart'; 

// Import for password reset flow
import 'reset_password_screen.dart';

// CRITICAL IMPORT: To save the user ID after normal login
import 'auth_storage_service.dart';

// THEME COLOR
const Color royalBlue = Color(0xFF002366);

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isPasswordReset; 

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isPasswordReset = false, 
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // CONFIGURATION
  final String _baseUrl = "https://neoerainfotech.com/Covai/api/";
  bool _isLoading = false;

  // OTP Input Controllers & Focus Nodes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // TIMER VARIABLES
  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  bool _isExpired = false;

  final AuthStorageService _authStorage = AuthStorageService();

  @override
  void initState() {
    super.initState();
    _startCountdown(); // Start timer when screen loads
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer to prevent memory leaks
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // --- TIMER LOGIC ---
  void _startCountdown() {
    _isExpired = false;
    _secondsRemaining = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _isExpired = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String get _timerText {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message, [bool isError = true]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- API CALL: Verify OTP ---
  Future<void> _verifyOtp() async {
    if (_isExpired) {
      _showSnackBar('OTP has expired. Please request a new one.');
      return;
    }

    final otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _showSnackBar('Please enter the complete 6-digit OTP.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}verify_login.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': widget.email,
          'otp': otp,
          'type': 'otp',
        }),
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        _timer?.cancel(); // Stop timer on success
        _showSnackBar('Verification Successful!', false);

        if (!mounted) return;

        if (widget.isPasswordReset) {
          // Pass verified OTP to the next screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(
                email: widget.email, 
                otp: otp,
              ),
            ),
          );
        } else {
          // Normal Login Flow
          String fetchedUserId = responseData['user_id']?.toString() ?? '0';
          if (fetchedUserId != '0') {
            await _authStorage.saveUserData(fetchedUserId);
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreenShell(userId: fetchedUserId),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        _showSnackBar(responseData['message'] ?? 'OTP verification failed.');
      }
    } catch (e) {
      _showSnackBar('Network Error: Could not connect to the server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- API CALL: Resend OTP ---
  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}send_otp_check.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'email': widget.email}),
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        _startCountdown(); // Restart the timer
        _showSnackBar('New OTP has been sent to your mail.', false);
      } else {
        _showSnackBar(responseData['message'] ?? 'Failed to send OTP.');
      }
    } catch (e) {
      _showSnackBar('Network Error: Could not resend OTP.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: royalBlue,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.security_rounded, size: 80, color: royalBlue),
              const SizedBox(height: 20),

              // TIMER UI (Added here)
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
                      _isExpired ? "OTP EXPIRED" : "Valid for: $_timerText",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isExpired ? Colors.red : royalBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              Text(
                widget.isPasswordReset ? 'Verify to Reset Password' : 'OTP Verification',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: royalBlue),
              ),
              const SizedBox(height: 10),
              const Text('A 6-digit code has been sent to:', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(widget.email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

              const SizedBox(height: 40),

              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildOtpBox(index, context)),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _isExpired) ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isExpired ? Colors.grey : royalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Icon(Icons.verified_user_rounded),
                  label: Text(_isLoading ? 'Verifying...' : 'VERIFY OTP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 25),

              TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: const Text('Didn\'t receive the code? Resend', style: TextStyle(color: royalBlue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index, BuildContext context) {
    return Container(
      width: 45, height: 55,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: royalBlue.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: royalBlue),
          decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else { FocusScope.of(context).unfocus(); _verifyOtp(); }
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          },
        ),
      ),
    );
  }
}