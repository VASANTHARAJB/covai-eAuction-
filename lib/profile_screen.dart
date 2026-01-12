import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io'; // Required for File handling
import 'package:http/http.dart' as http; //
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:shared_preferences/shared_preferences.dart'; // For local path storage
import 'package:flutter/foundation.dart' show kIsWeb; // Needed for Web safety
import 'auth_storage_service.dart'; //
import 'user_profile_model.dart'; //
import 'login_screen.dart'; //

// --- Constants & Theme ---
const String apiBaseUrl = 'https://neoerainfotech.com/Covai/api/'; //
const String viewProfileEndpoint = '$apiBaseUrl/view_profile.php'; //
const String updateProfileEndpoint = '$apiBaseUrl/update_profile.php'; //

const Color royalBlue = Color(0xFF002366); //
const Color successGreen = Color(0xFF34C759); //

class EditableProfileScreen extends StatefulWidget {
  final String customerId; //
  final String currentUser; //

  const EditableProfileScreen({
    super.key,
    required this.customerId,
    required this.currentUser,
  });

  @override
  State<EditableProfileScreen> createState() => _EditableProfileScreenState();
}

class _EditableProfileScreenState extends State<EditableProfileScreen> {
  UserProfile? _currentUser; //
  bool _isLoading = true; //
  String? _actualCustomerId; //
  final AuthStorageService _authStorage = AuthStorageService(); //

  @override
  void initState() {
    super.initState();
    _loadCustomerIdAndFetchProfile(); //
  }

  Future<void> _handleLogout() async {
    await _authStorage.clearAuthData(); //
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _loadCustomerIdAndFetchProfile() async {
    String? storedId = await _authStorage.getUserId(); //
    if (storedId != null && storedId.isNotEmpty && storedId != '0') {
      _actualCustomerId = storedId; //
      await _fetchUserProfile(); //
    } else {
      _showSnackbar('Error: User session not found. Please log in.', isError: true); //
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserProfile() async {
    if (_actualCustomerId == null) return;
    setState(() => _isLoading = true); //

    try {
      final response = await http.post(
        Uri.parse(viewProfileEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"customer_id": _actualCustomerId}), //
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body); //
        if (data['status'] == 'success' && data['user'] is Map<String, dynamic>) {
          setState(() {
            _currentUser = UserProfile.fromJson(data['user']); //
            _isLoading = false;
          });
        } else {
          _showSnackbar(data['message'] ?? 'Failed to load profile', isError: true); //
          setState(() => _isLoading = false);
        }
      } else {
        _showSnackbar('Server Error: ${response.statusCode}', isError: true); //
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnackbar('Network Error. Check your connection.', isError: true); //
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, //
      appBar: AppBar(
        title: const Text('Account Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: royalBlue, //
        foregroundColor: Colors.white, //
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(onPressed: _handleLogout, child: const Text('Logout', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: royalBlue))
          : _currentUser == null
              ? const Center(child: Text('Profile session expired.'))
              : ProfileForm(
                  currentUser: _currentUser!,
                  onUpdate: (updatedUser) {
                    setState(() => _currentUser = updatedUser);
                    _showSnackbar('Profile updated successfully!');
                  },
                ),
    );
  }
}

class ProfileForm extends StatefulWidget {
  final UserProfile currentUser; //
  final Function(UserProfile) onUpdate; //

  const ProfileForm({super.key, required this.currentUser, required this.onUpdate});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>(); //
  bool _isSaving = false; //

  late TextEditingController _nameController; //
  late TextEditingController _emailController; //
  late TextEditingController _phoneController; //
  late TextEditingController _addressController; //

  File? _profileImage; //
  final ImagePicker _picker = ImagePicker(); //
  static const String _imageKey = "local_profile_image_path"; //

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name); //
    _emailController = TextEditingController(text: widget.currentUser.email); //
    _phoneController = TextEditingController(text: widget.currentUser.phoneNumber); //
    _addressController = TextEditingController(text: widget.currentUser.address); //
    _loadLocalImage(); //
  }

  Future<void> _loadLocalImage() async {
    final prefs = await SharedPreferences.getInstance(); //
    final String? imagePath = prefs.getString(_imageKey); //
    
    if (imagePath != null) {
      if (kIsWeb) {
        setState(() {
          _profileImage = File(imagePath); //
        });
      } else if (File(imagePath).existsSync()) {
        setState(() {
          _profileImage = File(imagePath); //
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path); //
        });
        final prefs = await SharedPreferences.getInstance(); //
        await prefs.setString(_imageKey, pickedFile.path); //
      }
    } catch (e) {
      _showLocalSnackbar("Error picking image: $e", isError: true); //
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); //
    _emailController.dispose(); //
    _phoneController.dispose(); //
    _addressController.dispose(); //
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true); //

    final updatedData = {
      "customer_id": widget.currentUser.userId, //
      "name": _nameController.text.trim(), //
      "email": _emailController.text.trim(), //
      "phone": _phoneController.text.trim(), //
      "address": _addressController.text.trim(), //
    };

    try {
      final response = await http.post(
        Uri.parse(updateProfileEndpoint),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedData), //
      );

      var data = jsonDecode(response.body); //

      if (response.statusCode == 200 && data['status'] == 'success') {
        final updatedUser = UserProfile(
          userId: widget.currentUser.userId, //
          name: updatedData["name"]!, //
          email: updatedData["email"]!, //
          phoneNumber: updatedData["phone"]!, //
          address: updatedData["address"]!, //
          kycStatus: widget.currentUser.kycStatus, //
          type: widget.currentUser.type, //
          status: widget.currentUser.status, //
        );
        widget.onUpdate(updatedUser); //
      } else {
        _showLocalSnackbar(data['message'] ?? 'Update failed', isError: true); //
      }
    } catch (e) {
      _showLocalSnackbar('Connection Error: $e', isError: true); //
    } finally {
      setState(() => _isSaving = false); //
    }
  }

  void _showLocalSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : successGreen));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: royalBlue, //
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                child: GestureDetector(
                  onTap: _pickImage, //
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200], //
                          backgroundImage: _profileImage != null 
                              ? (kIsWeb ? NetworkImage(_profileImage!.path) : FileImage(_profileImage!)) as ImageProvider
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person, size: 70, color: royalBlue)
                              : null,
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: royalBlue, //
                            child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 90),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: royalBlue)),
                  const SizedBox(height: 20),
                  _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _emailController, label: 'Email Address', icon: Icons.email_outlined, readOnly: true),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _phoneController, label: 'Phone Number', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _addressController, label: 'Address', icon: Icons.location_on_outlined, maxLines: 3),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royalBlue, //
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: _isSaving 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  
                  // NEW: ACCOUNT DETAILS DISPLAY CARD
                  const SizedBox(height: 40),
                  const Text('Account Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: royalBlue)),
                  const SizedBox(height: 15),
                  _buildStatusCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card to display kyc_status, type, and status from Database
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Account Status', widget.currentUser.status, Icons.verified_user_outlined),
          const Divider(),
          _buildInfoRow('KYC Status', widget.currentUser.kycStatus, Icons.assignment_ind_outlined),
          const Divider(),
          _buildInfoRow('Account Type', widget.currentUser.type, Icons.badge_outlined),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(
            value, 
            style: const TextStyle(fontWeight: FontWeight.bold, color: royalBlue, fontSize: 14)
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool readOnly = false, 
    int maxLines = 1, 
    TextInputType keyboardType = TextInputType.text
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => (value == null || value.isEmpty) ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: royalBlue), //
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: royalBlue, width: 2)),
      ),
    );
  }
}