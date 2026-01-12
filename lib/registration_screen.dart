import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final String _baseUrl = "https://neoerainfotech.com/Covai/api/";
  final int _otpLength = 6;
  bool _isLoading = false;
  bool _isOtpVerified = false;

  // Professional Color Palette
  final Color primaryColor = const Color(0xFF1A237E); // Deep Indigo
  final Color secondaryColor = const Color(0xFF0D47A1); // Strong Blue

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  int _otpTimer = 0;
  Timer? _timer;

  String get _formattedTimer =>
      '${(_otpTimer ~/ 60).toString().padLeft(2, '0')}:${(_otpTimer % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(_otpLength, (_) => TextEditingController());
    _otpFocusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _showSnackBar(String message, [bool isError = true]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Minimum 8 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Requires one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Requires one number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Requires one special character';
    return null;
  }

  void _startLocalTimer() {
    setState(() {
      _otpSent = true;
      _otpTimer = 300;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_otpTimer > 0) {
          _otpTimer--;
        } else {
          t.cancel();
          _otpSent = false;
        }
      });
    });
  }

  Future<void> _sendOtpToApi() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Enter a valid Email address.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse('${_baseUrl}send_otp_registration.php'),
        body: json.encode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );
      var responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        _showSnackBar("OTP sent successfully", false);
        _startLocalTimer();
      } else {
        _showSnackBar(responseData['message'] ?? "Error occurred");
      }
    } catch (e) {
      _showSnackBar('Network Error: Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOtpOnly() async {
    final otp = _otpControllers.map((e) => e.text).join();
    if (otp.length != _otpLength) return;

    setState(() => _isLoading = true);
    try {
      var response = await http.post(
        Uri.parse('${_baseUrl}verify_otp_only.php'),
        body: json.encode({
          'email': _emailController.text.trim(),
          'otp_code': otp,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      var responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        setState(() => _isOtpVerified = true);
        _timer?.cancel();
        _showSnackBar("OTP Verified! Now set your password.", false);
      } else {
        _showSnackBar(responseData['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      _showSnackBar("Verification Error: Check server connection");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isOtpVerified) {
      _showSnackBar("Please verify OTP first");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    Map<String, dynamic> requestData = {
      'full_name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile': _contactController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
      'password': _passwordController.text,
      'otp_code': _otpControllers.map((e) => e.text).join(),
    };

    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}register_user.php'),
        body: json.encode(requestData),
        headers: {'Content-Type': 'application/json'},
      );
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        _showSnackBar("Registration Successful!", false);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        });
      } else {
        _showSnackBar(responseData['message'] ?? "Registration Failed");
      }
    } catch (e) {
      _showSnackBar('Network Error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _otpBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        enabled: !_isOtpVerified,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
        decoration: InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          fillColor: _isOtpVerified ? Colors.green.shade50 : Colors.white,
          filled: true,
        ),
        onChanged: (v) {
          if (v.length == 1) {
            if (index < _otpLength - 1) {
              FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
            } else {
              _otpFocusNodes[index].unfocus();
              _verifyOtpOnly();
            }
          } else if (v.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Create Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Join Covai E-Auction",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: primaryColor)),
              const SizedBox(height: 5),
              const Text("Fill in your details to get started",
                  style: TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 25),
              _buildField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded),
              _buildField(
                  controller: _contactController,
                  label: 'Mobile Number',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone),
              _buildField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.home_outlined),
              Row(
                children: [
                  Expanded(
                      child: _buildField(
                          controller: _cityController,
                          label: 'City',
                          icon: Icons.location_city_rounded)),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildField(
                          controller: _postalCodeController,
                          label: 'Postal Code',
                          icon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number)),
                ],
              ),
              _buildField(
                  controller: _emailController,
                  label: 'Email ID',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isOtpVerified),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Verify Email",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: primaryColor)),
                  if (_otpSent && _otpTimer > 0 && !_isOtpVerified)
                    Text("Expires in: $_formattedTimer",
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold)),
                  if (_otpSent && _otpTimer == 0 && !_isOtpVerified)
                    TextButton(
                        onPressed: _sendOtpToApi,
                        child: const Text("Resend OTP",
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold)))
                ],
              ),
              const SizedBox(height: 12),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_otpLength, _otpBox)),
              const SizedBox(height: 15),
              if (!_otpSent && !_isOtpVerified)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _sendOtpToApi,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text("Send Verification OTP"),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: secondaryColor,
                        side: BorderSide(color: secondaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              const SizedBox(height: 25),
              Opacity(
                opacity: _isOtpVerified ? 1.0 : 0.5,
                child: AbsorbPointer(
                  absorbing: !_isOtpVerified,
                  child: Column(
                    children: [
                      _buildField(
                        controller: _passwordController,
                        label: 'Create Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      _buildField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_rounded,
                        obscureText: _obscureConfirmPassword,
                        validator: (value) => value != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: _isOtpVerified
                      ? LinearGradient(colors: [primaryColor, secondaryColor])
                      : null,
                  color: _isOtpVerified ? null : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: _isOtpVerified
                      ? [
                          BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: _isOtpVerified && !_isLoading ? _register : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Complete Registration',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator ??
              (value) => (value == null || value.isEmpty)
                  ? '$label is required'
                  : null,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: primaryColor, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide:
                  BorderSide(color: primaryColor.withOpacity(0.5), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}