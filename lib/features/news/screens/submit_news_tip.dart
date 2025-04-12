import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';

class SubmitNewsTipScreen extends StatefulWidget {
  const SubmitNewsTipScreen({super.key});

  @override
  State<SubmitNewsTipScreen> createState() => _SubmitNewsTipScreenState();
}

class _SubmitNewsTipScreenState extends State<SubmitNewsTipScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAnonymous = false;

  // Change the type to store actual XFile objects instead of just strings
  final List<XFile> _mediaFiles = <XFile>[];
  final ImagePicker _imagePicker = ImagePicker();

  // Form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _headlineController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourcesController = TextEditingController();

  String? _selectedCategory;
  DateTime? _incidentDate;
  TimeOfDay? _incidentTime;

  final List<String> _categories = [
    'Crime',
    'Event',
    'Local Government',
    'Business',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _headlineController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _sourcesController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    // Request permissions first
    final PermissionStatus photoStatus = await Permission.photos.request();

    if (photoStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo permission is required to upload images'),
          ),
        );
      }
      return;
    }

    // Show options in a bottom sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder:
            (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Photo Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromGallery();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Camera'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickFromCamera();
                    },
                  ),
                ],
              ),
            ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> selectedImages = await _imagePicker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (selectedImages.isNotEmpty && mounted) {
        final int remainingSlots = 3 - _mediaFiles.length;
        setState(() {
          // Add new images, respecting the 3 file limit
          if (remainingSlots > 0) {
            _mediaFiles.addAll(selectedImages.take(remainingSlots));
          }
        });

        if (selectedImages.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Maximum of 3 files allowed. Extra files were not added.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      if (_mediaFiles.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum of 3 files allowed')),
        );
        return;
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        setState(() {
          _mediaFiles.add(photo);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      }
    }
  }

  // Add this helper method to reset media files if needed
  void _resetMediaFiles() {
    setState(() {
      _mediaFiles.clear();
    });
  }

  // Update _submitTip to handle the image files
  Future<void> _submitTip() async {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    if (_incidentDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create document data
      final tipData = {
        'headline': _headlineController.text,
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'location': _locationController.text,
        'incidentDate':
            _incidentDate != null ? Timestamp.fromDate(_incidentDate!) : null,
        'incidentTime':
            _incidentTime != null
                ? '${_incidentTime!.hour}:${_incidentTime!.minute}'
                : null,
        'sources': _sourcesController.text,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending_review',
        'mediaUrls': <String>[],
        'anonymous': _isAnonymous,
      };

      // Add submitter info if not anonymous
      if (!_isAnonymous) {
        tipData['submitterName'] = _nameController.text;
        tipData['submitterEmail'] = _emailController.text;
        tipData['submitterPhone'] = _phoneController.text;
      }

      // Add user ID if logged in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        tipData['submitterId'] = currentUser.uid;
      }

      // Create document in Firestore first to get document ID
      final docRef = await FirebaseFirestore.instance
          .collection('news_tips')
          .add(tipData);

      debugPrint('Created news tip with ID: ${docRef.id}');

      // Upload media files if any
      if (_mediaFiles.isNotEmpty) {
        List<String> mediaUrls = [];

        for (final XFile media in _mediaFiles) {
          final File file = File(media.path);
          final String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${media.name}';

          // Create storage reference
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('news_tips')
              .child(docRef.id)
              .child(fileName);

          // Upload file
          final uploadTask = await storageRef.putFile(file);

          // Get download URL
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          mediaUrls.add(downloadUrl);

          debugPrint('Uploaded file to: $downloadUrl');
        }

        // Update document with media URLs
        await docRef.update({'mediaUrls': mediaUrls});
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // Show success dialog
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Thank You!'),
                content: const Text(
                  'Your news tip has been submitted for review by our editorial team.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Return to previous screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting news tip: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting news tip: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit News Tip'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit a News Tip',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d2c31),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Help us report on important local stories. Your tip will be reviewed by our editorial team.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contact Information
                          const Text(
                            'Your Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d2c31),
                            ),
                          ),

                          // Anonymous option
                          SwitchListTile(
                            title: const Text('Submit Anonymously'),
                            subtitle: const Text(
                              'We will make every attemot to keep your identity private',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _isAnonymous,
                            activeColor: const Color(0xFFd2982a),
                            onChanged: (value) {
                              setState(() {
                                _isAnonymous = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),

                          if (!_isAnonymous) ...[
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Your Name*',
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      value!.isEmpty
                                          ? 'Please enter your name'
                                          : null,
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email*',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator:
                                        (value) =>
                                            value!.isEmpty
                                                ? 'Please enter your email'
                                                : null,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                      border: OutlineInputBorder(),
                                      helperText: 'Optional',
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Tip Information
                          const Text(
                            'News Tip Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d2c31),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _headlineController,
                            decoration: const InputDecoration(
                              labelText: 'Headline/Subject*',
                              border: OutlineInputBorder(),
                              helperText: 'Brief summary of the news tip',
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please provide a headline'
                                        : null,
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Category*',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                _categories.map((category) {
                                  return DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select a category'
                                        : null,
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location*',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Address or intersection where this occurred',
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please enter the location'
                                        : null,
                          ),

                          const SizedBox(height: 16),

                          // Date and time
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 30),
                                      ),
                                      lastDate: DateTime.now(),
                                    );

                                    if (date != null) {
                                      setState(() {
                                        _incidentDate = date;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Date*',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _incidentDate != null
                                          ? DateFormat(
                                            'MM/dd/yyyy',
                                          ).format(_incidentDate!)
                                          : 'Select date',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );

                                    if (time != null) {
                                      setState(() {
                                        _incidentTime = time;
                                      });
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Time',
                                      border: OutlineInputBorder(),
                                      helperText: 'Optional',
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    child: Text(
                                      _incidentTime != null
                                          ? _incidentTime!.format(context)
                                          : 'Select time',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description*',
                              border: OutlineInputBorder(),
                              helperText: 'What happened? Who was involved?',
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please provide a description'
                                        : null,
                            maxLines: 5,
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _sourcesController,
                            decoration: const InputDecoration(
                              labelText: 'Sources*',
                              border: OutlineInputBorder(),
                              helperText:
                                  'How do you know this? Were you a witness?',
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please provide your sources'
                                        : null,
                            maxLines: 3,
                          ),

                          const SizedBox(height: 24),

                          // Media upload
                          const Text(
                            'Media',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d2c31),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Upload photos or videos related to this tip (maximum 3 files)',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Media preview
                          if (_mediaFiles.isNotEmpty)
                            Container(
                              height: 100,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _mediaFiles.length,
                                itemBuilder: (context, index) {
                                  final XFile mediaFile = _mediaFiles[index];
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            File(mediaFile.path),
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              debugPrint(
                                                'Error loading image: $error',
                                              );
                                              return const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _mediaFiles.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                          ElevatedButton.icon(
                            onPressed:
                                _mediaFiles.length < 3 ? _pickMedia : null,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: Text(
                              _mediaFiles.isEmpty
                                  ? 'Add Media'
                                  : 'Add More (${3 - _mediaFiles.length} left)',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd2982a),
                              foregroundColor: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitTip,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFd2982a),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('SUBMIT NEWS TIP'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
