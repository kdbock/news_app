import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class SubmitPressReleaseScreen extends StatefulWidget {
  const SubmitPressReleaseScreen({super.key});

  @override
  State<SubmitPressReleaseScreen> createState() => _SubmitPressReleaseScreenState();
}

class _SubmitPressReleaseScreenState extends State<SubmitPressReleaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _termsAccepted = false;
  File? _imageFile;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _organizationController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contentController = TextEditingController();
  final _websiteLinkController = TextEditingController();
  
  // Category selection
  String? _selectedCategory;
  final List<String> _categories = [
    'Business',
    'Community',
    'Education',
    'Government',
    'Health',
    'Nonprofit',
    'Sports',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contentController.dispose();
    _websiteLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    
    try {
      final String fileName = 'press_releases/${DateTime.now().millisecondsSinceEpoch}_${path.basename(_imageFile!.path)}';
      final Reference storageRef = _storage.ref().child(fileName);
      
      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

  Future<void> _submitPressRelease() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check if category is selected
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    
    // Check terms acceptance
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if user is logged in
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('You must be logged in to submit a press release');
      }

      // Upload image if provided
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
      }

      // Prepare press release data
      final pressReleaseData = {
        'userId': user.uid,
        'title': _titleController.text,
        'organization': _organizationController.text,
        'contactName': _contactNameController.text,
        'contactEmail': _contactEmailController.text,
        'contactPhone': _contactPhoneController.text,
        'content': _contentController.text,
        'category': _selectedCategory,
        'websiteLink': _websiteLinkController.text,
        'imageUrl': imageUrl,
        'status': 'pending_review', // Needs admin approval
        'submittedAt': FieldValue.serverTimestamp(),
        'publishedAt': null,
      };

      // Save to Firestore
      await _firestore.collection('press_releases').add(pressReleaseData);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press release submitted successfully! It will be reviewed by our team.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _formKey.currentState?.reset();
        setState(() {
          _selectedCategory = null;
          _termsAccepted = false;
          _imageFile = null;
        });
        
        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting press release: $e')),
        );
      }
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
        title: const Text('Submit Press Release'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFd2982a)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intro section
                    const Text(
                      'Submit a Press Release',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFd2982a),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Share your organization\'s news with our community. All press releases are subject to review before publication.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Basic information
                    _buildSectionHeader('Basic Information'),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Press Release Title',
                        border: OutlineInputBorder(),
                        hintText: 'Enter a clear, descriptive title',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        } else if (value.length < 5) {
                          return 'Title is too short';
                        } else if (value.length > 100) {
                          return 'Title is too long (max 100 characters)';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Organization',
                        border: OutlineInputBorder(),
                        hintText: 'Your organization or company name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your organization name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select a category'),
                      value: _selectedCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    // Contact information
                    _buildSectionHeader('Contact Information'),
                    
                    TextFormField(
                      controller: _contactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        border: OutlineInputBorder(),
                        hintText: 'Person to contact about this press release',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a contact name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Email',
                        border: OutlineInputBorder(),
                        hintText: 'Email address for inquiries',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a contact email';
                        } else if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'Phone number for inquiries',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 24),

                    // Press Release Content
                    _buildSectionHeader('Press Release Content'),
                    
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                        hintText: 'Enter the full text of your press release',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the press release content';
                        } else if (value.length < 100) {
                          return 'Content is too short (min 100 characters)';
                        } else if (value.length > 5000) {
                          return 'Content is too long (max 5000 characters)';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _websiteLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Website Link (optional)',
                        border: OutlineInputBorder(),
                        hintText: 'https://www.yourorganization.com',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    
                    const SizedBox(height: 24),

                    // Image Upload
                    _buildSectionHeader('Featured Image (optional)'),
                    
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _imageFile!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to add an image',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Recommended size: 1200 x 630 pixels',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Terms and Conditions
                    _buildSectionHeader('Terms and Conditions'),
                    
                    CheckboxListTile(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                      title: const Text(
                        'I confirm that I have the rights to publish this content and accept the terms and conditions',
                        style: TextStyle(fontSize: 14),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFd2982a),
                    ),
                    
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitPressRelease,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFd2982a),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'SUBMIT PRESS RELEASE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
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
        const SizedBox(height: 8),
      ],
    );
  }
}