import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class EditProfileScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String zipCode;
  final String birthday;
  final bool textAlerts;
  final bool dailyDigest;
  final bool sportsNewsletter;
  final bool politicalNewsletter;
  final String? profileImageUrl;

  const EditProfileScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.zipCode,
    required this.birthday,
    required this.textAlerts,
    required this.dailyDigest,
    required this.sportsNewsletter,
    required this.politicalNewsletter,
    this.profileImageUrl,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  final bool _isSaving = false;
  String _errorMessage = '';
  DateTime? _selectedDate;
  File? _imageFile;
  String? _profileImageUrl;
  bool _isUploading = false;

  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _zipCodeController;
  late TextEditingController _birthdayController;

  // Newsletter subscriptions
  late bool _textAlerts;
  late bool _dailyDigest;
  late bool _sportsNewsletter;
  late bool _politicalNewsletter;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _zipCodeController = TextEditingController(text: widget.zipCode);
    _birthdayController = TextEditingController(text: widget.birthday);

    _textAlerts = widget.textAlerts;
    _dailyDigest = widget.dailyDigest;
    _sportsNewsletter = widget.sportsNewsletter;
    _politicalNewsletter = widget.politicalNewsletter;

    // Parse birthday string to DateTime if needed
    if (widget.birthday.isNotEmpty) {
      try {
        _selectedDate = DateFormat('MM/dd/yyyy').parse(widget.birthday);
      } catch (e) {
        // If parsing fails, keep _selectedDate as null
      }
    }

    // Initialize existing profile image
    _profileImageUrl = widget.profileImageUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _zipCodeController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _imageFile = File(pickedFile.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_imageFile == null) return _profileImageUrl;

    try {
      setState(() => _isUploading = true);

      // Create file reference
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(_imageFile!.path)}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      // Upload file
      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _isUploading = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImageUrl != null || _imageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _profileImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;

      if (user != null) {
        // Upload image if changed
        final imageUrl = await _uploadProfileImage(user.uid);

        // Update display name in Firebase Auth
        await user.updateDisplayName(
          '${_firstNameController.text} ${_lastNameController.text}',
        );

        // Update email if changed and not empty
        if (_emailController.text.isNotEmpty &&
            _emailController.text != user.email) {
          await user.updateEmail(_emailController.text);
        }

        // Update Firestore user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({
              'firstName': _firstNameController.text,
              'lastName': _lastNameController.text,
              'phone': _phoneController.text,
              'zipCode': _zipCodeController.text,
              'birthday': _birthdayController.text,
              'textAlerts': _textAlerts,
              'dailyDigest': _dailyDigest,
              'sportsNewsletter': _sportsNewsletter,
              'politicalNewsletter': _politicalNewsletter,
              'profileImageUrl': imageUrl,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context); // Return to profile screen
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error updating profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF2d2c31),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFd2982a)),
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFd2982a),
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFFd2982a),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image section
              Center(
                child: Stack(
                  children: [
                    // Profile image
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(
                          0xFFd2982a,
                        ).withOpacity(0.2),
                        backgroundImage: _getProfileImage(),
                        child: _getProfileImagePlaceholder(),
                      ),
                    ),

                    // Edit button
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFd2982a),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // Loading indicator overlay
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Personal Information section
              _buildSectionHeader('Personal Information'),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name*',
                      ),
                      validator:
                          (value) => value!.isNotEmpty ? null : 'Required',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name*',
                      ),
                      validator:
                          (value) => value!.isNotEmpty ? null : 'Required',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email*'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (value) =>
                        value!.isNotEmpty
                            ? !RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)
                                ? 'Enter a valid email'
                                : null
                            : 'Required',
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number*'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isNotEmpty ? null : 'Required',
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _zipCodeController,
                decoration: const InputDecoration(labelText: 'ZIP Code*'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value!.isNotEmpty
                            ? value.length != 5
                                ? 'Enter a valid 5-digit ZIP code'
                                : null
                            : 'Required',
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _birthdayController,
                    decoration: const InputDecoration(
                      labelText: 'Birthday',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Newsletter Subscriptions section
              _buildSectionHeader('Newsletter Subscriptions'),

              CheckboxListTile(
                title: const Text('Text News Alerts'),
                value: _textAlerts,
                onChanged: (value) => setState(() => _textAlerts = value!),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFd2982a),
              ),

              CheckboxListTile(
                title: const Text('Neuse News Daily Digest'),
                value: _dailyDigest,
                onChanged: (value) => setState(() => _dailyDigest = value!),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFd2982a),
              ),

              CheckboxListTile(
                title: const Text('Neuse News Sports Newsletter'),
                value: _sportsNewsletter,
                onChanged:
                    (value) => setState(() => _sportsNewsletter = value!),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFd2982a),
              ),

              CheckboxListTile(
                title: const Text('NC Political News Newsletter'),
                value: _politicalNewsletter,
                onChanged:
                    (value) => setState(() => _politicalNewsletter = value!),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFd2982a),
              ),

              const SizedBox(height: 32),

              // Save button at bottom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd2982a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_profileImageUrl != null) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  Widget? _getProfileImagePlaceholder() {
    if (_imageFile == null && _profileImageUrl == null) {
      return const Icon(Icons.person, size: 60, color: Color(0xFFd2982a));
    }
    return null;
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFd2982a),
          ),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }
}
