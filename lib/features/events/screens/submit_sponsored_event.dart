import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
// Remove the cloud_functions import for now
// import 'package:cloud_functions/cloud_functions.dart';

class SubmitSponsoredEventScreen extends StatefulWidget {
  const SubmitSponsoredEventScreen({super.key});

  @override
  State<SubmitSponsoredEventScreen> createState() =>
      _SubmitSponsoredEventScreenState();
}

class _SubmitSponsoredEventScreenState
    extends State<SubmitSponsoredEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;
  final List<XFile> _eventImages = <XFile>[];
  final ImagePicker _imagePicker = ImagePicker();

  // Form fields
  final _organizationController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactRoleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _eventTitleController = TextEditingController();
  final _venueController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ticketLinkController = TextEditingController();
  final _hashtagsController = TextEditingController();
  final _ageRestrictionsController = TextEditingController();

  // Payment fields
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  DateTime? _rainDate;

  final List<String> _eventTypes = [
    'Concert',
    'Festival',
    'Fundraiser',
    'Workshop',
    'Conference',
    'Sports Event',
    'Exhibition',
    'Other',
  ];

  String? _selectedEventType;
  // Fixed price of $25 instead of tiers
  final double _eventSubmissionPrice = 25.00;

  bool _isProcessingPayment = false;
  String? _paymentError;
  String? _paymentIntentId;

  @override
  void dispose() {
    _organizationController.dispose();
    _contactNameController.dispose();
    _contactRoleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _eventTitleController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _ticketLinkController.dispose();
    _hashtagsController.dispose();
    _ageRestrictionsController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate the current step before proceeding
    if (_currentStep == 0) {
      if (_organizationController.text.isEmpty ||
          _contactNameController.text.isEmpty ||
          _emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_eventTitleController.text.isEmpty ||
          _selectedEventType == null ||
          _startDate == null ||
          _venueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    }

    setState(() {
      if (_currentStep < 3) {
        _currentStep += 1;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep -= 1;
      }
    });
  }

  Future<void> _pickEventImage() async {
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
        setState(() {
          // Only allow one image for events
          _eventImages.clear();
          _eventImages.add(selectedImages.first);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (photo != null && mounted) {
        setState(() {
          // Replace any existing image
          _eventImages.clear();
          _eventImages.add(photo);
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

  Future<void> _submitEvent() async {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Validate payment form
    if (_paymentFormKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all payment fields')),
      );
      return;
    }

    // Process payment
    setState(() {
      _isProcessingPayment = true;
      _paymentError = null;
    });

    try {
      // Simulate payment processing with a delay
      await Future.delayed(const Duration(seconds: 2));

      // Fix the truncated payment intent ID generation
      _paymentIntentId =
          'mock_payment_${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _isProcessingPayment = false;
        _isLoading = true;
      });

      // Save event to Firestore
      final String eventId = await _saveEventToFirestore();

      if (mounted) {
        setState(() => _isLoading = false);

        // Show confirmation dialog
        await _showConfirmationDialog(eventId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _isLoading = false;
          _paymentError = e.toString();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting event: $e')));
      }
    }
  }

  // Complete the Firestore document creation with all required fields
  Future<String> _saveEventToFirestore() async {
    if (_startDate == null) throw Exception('Start date is required');

    // Create a DateTime object with date and time combined
    final DateTime eventDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );

    // Format times for display
    final String formattedStartTime =
        _startTime != null ? _startTime!.format(context) : '12:00 PM';
    final String? formattedEndTime = _endTime?.format(context);

    try {
      String? imageUrl;
      if (_eventImages.isNotEmpty) {
        final File imageFile = File(_eventImages.first.path);

        // Create a reference to Firebase Storage with a unique name
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child(
              '${DateTime.now().millisecondsSinceEpoch}_${_eventImages.first.name}',
            );

        // Upload the file
        final uploadTask = storageRef.putFile(imageFile);

        // Get the download URL after upload completes
        final taskSnapshot = await uploadTask;
        imageUrl = await taskSnapshot.ref.getDownloadURL();

        debugPrint('Image uploaded to: $imageUrl');
      }

      // Create the event document in Firestore with ALL required fields
      final docRef = await FirebaseFirestore.instance.collection('events').add({
        'title': _eventTitleController.text,
        'description': _descriptionController.text,
        'eventDate': Timestamp.fromDate(eventDateTime),
        'startTime': formattedStartTime,
        'endTime': formattedEndTime,
        'location': _venueController.text,
        'address': _addressController.text,
        'organizer': _organizationController.text,
        'contactName': _contactNameController.text,
        'contactRole': _contactRoleController.text,
        'contactEmail': _emailController.text,
        'contactPhone': _phoneController.text,
        'eventType': _selectedEventType,
        'ticketLink': _ticketLinkController.text,
        'hashtags': _hashtagsController.text,
        'ageRestrictions': _ageRestrictionsController.text,
        'rainDate': _rainDate != null ? Timestamp.fromDate(_rainDate!) : null,
        'imageUrl': imageUrl,
        'isSponsored': true,
        'paymentIntentId': _paymentIntentId,
        'status': 'pending_review',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'submissionFee': _eventSubmissionPrice,
      });

      return docRef.id;
    } catch (e) {
      debugPrint('Error saving event to Firestore: $e');
      rethrow;
    }
  }

  // Ensure the confirmation dialog works properly
  Future<void> _showConfirmationDialog(String eventId) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFd2982a),
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text('Submission Successful'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your event has been submitted successfully and will be reviewed by our team.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Event ID: $eventId',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Text(
                  'You will receive a confirmation email at ${_emailController.text} with further details.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text(
                      'Status: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Pending Admin Review',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Return to previous screen
              },
              child: const Text('CLOSE'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFd2982a),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushReplacementNamed('/dashboard');
              },
              child: const Text('GO TO DASHBOARD'),
            ),
          ],
        );
      },
    );
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    // Remove spaces
    value = value.replaceAll(' ', '');
    if (value.length < 13 || value.length > 19) {
      return 'Card number must be between 13-19 digits';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use format MM/YY';
    }

    try {
      final parts = value.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse('20${parts[1]}');

      final now = DateTime.now();
      final expiryDate = DateTime(year, month + 1, 0);

      if (month < 1 || month > 12) {
        return 'Invalid month';
      }

      if (expiryDate.isBefore(now)) {
        return 'Card has expired';
      }
    } catch (e) {
      return 'Invalid date format';
    }

    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(value)) {
      return 'CVV must be 3-4 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Community Event'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepTapped: (step) => setState(() => _currentStep = step),
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            ElevatedButton(
                              onPressed: _previousStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('BACK'),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed:
                                _currentStep == 3 ? _submitEvent : _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd2982a),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _currentStep == 3 ? 'SUBMIT & PAY' : 'NEXT',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    // Organization Info step
                    Step(
                      title: const Text('Organization Info'),
                      isActive: _currentStep >= 0,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _organizationController,
                            decoration: const InputDecoration(
                              labelText: 'Organization Name*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contactNameController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Person Name*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contactRoleController,
                            decoration: const InputDecoration(
                              labelText: 'Role in Organization',
                              border: OutlineInputBorder(),
                              helperText: 'e.g., Owner, Event Manager, etc.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email*',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone*',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),

                    // Event Details step
                    Step(
                      title: const Text('Event Details'),
                      isActive: _currentStep >= 1,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _eventTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Event Title*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Event Type*',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedEventType,
                            items:
                                _eventTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedEventType = value;
                              });
                            },
                            validator:
                                (value) => value == null ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().add(
                                        const Duration(days: 1),
                                      ),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (date != null) {
                                      setState(() => _startDate = date);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Date*',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _startDate != null
                                          ? DateFormat(
                                            'MM/dd/yyyy',
                                          ).format(_startDate!)
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
                                      setState(() => _startTime = time);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Time*',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    child: Text(
                                      _startTime != null
                                          ? _startTime!.format(context)
                                          : 'Select time',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _startDate ??
                                          DateTime.now().add(
                                            const Duration(days: 1),
                                          ),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (date != null) {
                                      setState(() => _endDate = date);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Date',
                                      helperText: 'Optional',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.calendar_today),
                                    ),
                                    child: Text(
                                      _endDate != null
                                          ? DateFormat(
                                            'MM/dd/yyyy',
                                          ).format(_endDate!)
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
                                      initialTime:
                                          _startTime ?? TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() => _endTime = time);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Time',
                                      helperText: 'Optional',
                                      border: OutlineInputBorder(),
                                      suffixIcon: Icon(Icons.access_time),
                                    ),
                                    child: Text(
                                      _endTime != null
                                          ? _endTime!.format(context)
                                          : 'Select time',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _venueController,
                            decoration: const InputDecoration(
                              labelText: 'Venue Name*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),

                    // Additional Info step
                    Step(
                      title: const Text('Additional Info'),
                      isActive: _currentStep >= 2,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Event Description*',
                              border: OutlineInputBorder(),
                              helperText: 'Max 300 characters',
                            ),
                            maxLines: 4,
                            maxLength: 300,
                            validator:
                                (value) => value!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ticketLinkController,
                            decoration: const InputDecoration(
                              labelText: 'Ticket/Registration Link',
                              border: OutlineInputBorder(),
                              helperText: 'Optional',
                              prefixText: 'https://',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate:
                                    _startDate ??
                                    DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => _rainDate = date);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Rain Date',
                                helperText: 'Optional',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _rainDate != null
                                    ? DateFormat(
                                      'MM/dd/yyyy',
                                    ).format(_rainDate!)
                                    : 'Select date if applicable',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _hashtagsController,
                            decoration: const InputDecoration(
                              labelText: 'Hashtags',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Separate with spaces (e.g., #LocalEvent #Music)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _ageRestrictionsController,
                            decoration: const InputDecoration(
                              labelText: 'Age Restrictions',
                              border: OutlineInputBorder(),
                              helperText:
                                  'e.g., 21+, All Ages, etc. (Optional)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Event Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Event Image Preview
                          if (_eventImages.isNotEmpty)
                            Container(
                              height: 150,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_eventImages.first.path),
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
                                              size: 40,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _eventImages.clear();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(153),
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
                              ),
                            ),

                          ElevatedButton.icon(
                            onPressed:
                                _eventImages.isEmpty ? _pickEventImage : null,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Event Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd2982a),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payment step
                    Step(
                      title: const Text('Payment'),
                      isActive: _currentStep >= 3,
                      content:
                          _isProcessingPayment
                              ? const Center(
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color(0xFFd2982a),
                                    ),
                                    SizedBox(height: 16),
                                    Text('Processing payment...'),
                                  ],
                                ),
                              )
                              : _paymentError != null
                              ? Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Payment Error: $_paymentError',
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _submitEvent,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFd2982a),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('TRY AGAIN'),
                                  ),
                                ],
                              )
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Community Event Submission',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Your event will be listed in our community calendar after review.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Payment Summary',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Event Listing Fee'),
                                            Text(
                                              '\$${_eventSubmissionPrice.toStringAsFixed(2)}',
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              '\$${_eventSubmissionPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFFd2982a),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Form(
                                    key: _paymentFormKey,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Payment Information',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // Card number field
                                          TextFormField(
                                            controller: _cardNumberController,
                                            decoration: const InputDecoration(
                                              labelText: 'Card Number',
                                              hintText: 'XXXX XXXX XXXX XXXX',
                                              border: OutlineInputBorder(),
                                              suffixIcon: Icon(
                                                Icons.credit_card,
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                            validator: _validateCardNumber,
                                            onChanged: (value) {
                                              // Auto-format card number
                                              final text = value.replaceAll(
                                                ' ',
                                                '',
                                              );
                                              if (text.length % 4 == 0 &&
                                                  text.length < 16) {
                                                _cardNumberController.text =
                                                    '$value ';
                                                _cardNumberController
                                                        .selection =
                                                    TextSelection.fromPosition(
                                                      TextPosition(
                                                        offset:
                                                            _cardNumberController
                                                                .text
                                                                .length,
                                                      ),
                                                    );
                                              }
                                            },
                                          ),

                                          const SizedBox(height: 16),

                                          // Card details row
                                          Row(
                                            children: [
                                              // Expiration date
                                              Expanded(
                                                child: TextFormField(
                                                  controller:
                                                      _expiryDateController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Expiry Date',
                                                        hintText: 'MM/YY',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  validator:
                                                      _validateExpiryDate,
                                                  onChanged: (value) {
                                                    // Auto-format expiry date
                                                    if (value.length == 2 &&
                                                        !value.contains('/')) {
                                                      _expiryDateController
                                                          .text = '$value/';
                                                      _expiryDateController
                                                              .selection =
                                                          TextSelection.fromPosition(
                                                            TextPosition(
                                                              offset:
                                                                  _expiryDateController
                                                                      .text
                                                                      .length,
                                                            ),
                                                          );
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // CVV
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _cvvController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'CVV',
                                                        hintText: 'XXX',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  obscureText: true,
                                                  validator: _validateCVV,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 16),

                                          // Name on card
                                          TextFormField(
                                            controller: _cardNameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Name on Card',
                                              border: OutlineInputBorder(),
                                            ),
                                            validator:
                                                (value) =>
                                                    value!.isEmpty
                                                        ? 'Required'
                                                        : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'By submitting, you agree to our terms and conditions.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Payment will be processed securely. You will receive a confirmation email after submission.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
