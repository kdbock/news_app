import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neusenews/features/advertising/models/ad.dart';
import 'package:neusenews/features/advertising/models/ad_type.dart';
import 'package:neusenews/features/advertising/models/ad_status.dart';
import 'package:neusenews/features/advertising/screens/advertiser/ad_checkout_screen.dart';
import 'package:neusenews/features/advertising/utils/image_validator.dart';
import 'package:neusenews/utils/error_handler.dart';

class AdCreationScreen extends StatefulWidget {
  final AdType? initialAdType;

  const AdCreationScreen({super.key, this.initialAdType});

  @override
  State<AdCreationScreen> createState() => _AdCreationScreenState();
}

class _AdCreationScreenState extends State<AdCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Form controllers
  final _businessNameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  // Form data
  late AdType _selectedAdType;
  File? _imageFile;
  DateTime? _startDate;
  DateTime? _endDate;
  int _durationWeeks = 1;
  double _adCost = 0.0;

  // Weekly rates by ad type
  final Map<AdType, double> _weeklyRates = {
    AdType.titleSponsor: 249.0,
    AdType.inFeedDashboard: 149.0,
    AdType.inFeedNews: 99.0,
    AdType.weather: 199.0,
  };

  // Add validation constants
  final _urlRegex = RegExp(r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$');
  final _minHeadlineLength = 5;
  final _maxHeadlineLength = 70;
  final _minDescriptionLength = 10;
  final _maxDescriptionLength = 250;

  // Create a loading state and form validation state
  bool _isSubmitting = false;
  bool _imageValidated = false;
  String? _imageErrorMessage;

  @override
  void initState() {
    super.initState();
    _selectedAdType = widget.initialAdType ?? AdType.inFeedNews;
    _calculateCost();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _headlineController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _calculateCost() {
    setState(() {
      _adCost = _weeklyRates[_selectedAdType]! * _durationWeeks;
    });
  }

  void _updateEndDate() {
    if (_startDate != null) {
      _endDate = _startDate!.add(Duration(days: _durationWeeks * 7));
      _endDateController.text = DateFormat('MM/dd/yyyy').format(_endDate!);
    }
  }

  // Enhanced validation methods
  String? validateBusinessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your business name';
    }
    if (value.length < 2) {
      return 'Business name must be at least 2 characters';
    }
    return null;
  }

  String? validateHeadline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a headline';
    }
    if (value.length < _minHeadlineLength) {
      return 'Headline must be at least $_minHeadlineLength characters';
    }
    if (value.length > _maxHeadlineLength) {
      return 'Headline cannot exceed $_maxHeadlineLength characters';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a description';
    }
    if (value.length < _minDescriptionLength) {
      return 'Description must be at least $_minDescriptionLength characters';
    }
    if (value.length > _maxDescriptionLength) {
      return 'Description cannot exceed $_maxDescriptionLength characters';
    }
    return null;
  }

  String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a URL';
    }
    if (!_urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL (e.g., https://example.com)';
    }
    return null;
  }

  // Update _pickImage method with validation
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // Reasonable size for ads
        maxHeight: 1200,
        imageQuality: 80, // Good quality with reasonable size
      );

      if (pickedFile == null) return;
      
      final imageFile = File(pickedFile.path);
      
      // Validate image
      final validationResult = await ImageValidator.validateImage(
        imageFile,
        aspectRatioType: _getRequiredAspectRatio(),
      );
      
      setState(() {
        if (validationResult.isValid) {
          _imageFile = imageFile;
          _imageErrorMessage = null;
          _imageValidated = true;
        } else {
          _imageErrorMessage = validationResult.errorMessage;
          _imageValidated = false;
        }
      });
    } catch (e) {
      setState(() {
        _imageErrorMessage = 'Error selecting image: ${e.toString()}';
        _imageValidated = false;
      });
    }
  }

  // Get required aspect ratio based on selected ad type
  String _getRequiredAspectRatio() {
    switch (_selectedAdType) {
      case AdType.titleSponsor:
        return 'banner'; // 2:1 aspect ratio
      case AdType.inFeedNews:
        return 'square'; // 1:1 aspect ratio
      case AdType.inFeedDashboard:
        return 'square'; // 1:1 aspect ratio
      case AdType.weather:
        return 'banner'; // 2:1 aspect ratio
      default:
        return 'banner';
    }
  }

  // Improved submitForm method with proper error handling
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Form validation failed
      return;
    }
    
    if (_imageFile == null || !_imageValidated) {
      setState(() {
        _imageErrorMessage = 'Please select a valid image for your ad';
      });
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      // Get current user ID
      final String? businessId = FirebaseAuth.instance.currentUser?.uid;

      if (businessId == null) {
        ErrorHandler.handleAdError(
          context, 
          'You must be logged in to create an advertisement',
          'No authenticated user',
          severity: ErrorSeverity.high
        );
        return;
      }

      // Create ad object
      final Ad newAd = Ad(
        businessId: businessId,
        businessName: _businessNameController.text.trim(),
        headline: _headlineController.text.trim(),
        description: _descriptionController.text.trim(),
        linkUrl: _ensureHttpProtocol(_linkController.text.trim()),
        type: _selectedAdType,
        status: AdStatus.pending,
        startDate: _startDate!,
        endDate: _endDate!,
        cost: _adCost,
      );

      // Navigate to checkout screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdCheckoutScreen(
            ad: newAd, 
            imageFile: _imageFile!,
          ),
        ),
      );
    } catch (e) {
      ErrorHandler.handleAdError(
        context,
        'Error creating advertisement',
        e,
        severity: ErrorSeverity.medium,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Ensure URLs have proper http/https prefix
  String _ensureHttpProtocol(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _startDateController.text = DateFormat('MM/dd/yyyy').format(_startDate!);
        _updateEndDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Advertisement'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ad Type Selection
              Text(
                'Select Ad Type',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              
              // Ad type dropdown
              DropdownButtonFormField<AdType>(
                value: _selectedAdType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: AdType.values.map((type) {
                  return DropdownMenuItem<AdType>(
                    value: type,
                    child: Text(_getAdTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedAdType = newValue;
                      _calculateCost();
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Business Name
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
                validator: validateBusinessName,
              ),
              
              const SizedBox(height: 16),
              
              // Ad Headline
              TextFormField(
                controller: _headlineController,
                decoration: const InputDecoration(
                  labelText: 'Headline',
                  border: OutlineInputBorder(),
                  hintText: 'Enter a catchy headline for your ad',
                ),
                maxLength: _maxHeadlineLength,
                validator: validateHeadline,
              ),
              
              const SizedBox(height: 8),
              
              // Ad Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe your product or service briefly',
                ),
                maxLines: 3,
                maxLength: _maxDescriptionLength,
                validator: validateDescription,
              ),
              
              const SizedBox(height: 8),
              
              // Link URL
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link URL',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., https://yoursite.com',
                ),
                keyboardType: TextInputType.url,
                validator: validateUrl,
              ),
              
              const SizedBox(height: 16),
              
              // Ad Image
              Text(
                'Ad Image',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              
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
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to upload image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              
              // Show image error if any
              if (_imageErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _imageErrorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                
              const SizedBox(height: 16),
              
              // Campaign Duration
              Text(
                'Campaign Duration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: () => _selectStartDate(context),
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) => value?.isEmpty ?? true 
                        ? 'Please select a start date' 
                        : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _durationWeeks,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                      ),
                      items: [1, 2, 4, 8, 12].map((duration) {
                        return DropdownMenuItem<int>(
                          value: duration,
                          child: Text('$duration week${duration > 1 ? 's' : ''}'),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _durationWeeks = newValue;
                            _updateEndDate();
                            _calculateCost();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _endDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.event),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Cost Summary
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cost Summary',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Weekly Rate:'),
                          Text('\$${_weeklyRates[_selectedAdType]!.toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Duration:'),
                          Text('$_durationWeeks week${_durationWeeks > 1 ? 's' : ''}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Cost:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_adCost.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONTINUE TO PAYMENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getAdTypeDisplayName(AdType type) {
    switch (type) {
      case AdType.titleSponsor:
        return 'Title Sponsor';
      case AdType.inFeedDashboard:
        return 'In-Feed Dashboard Ad';
      case AdType.inFeedNews:
        return 'In-Feed News Ad';
      case AdType.weather:
        return 'Weather Sponsor';
      case AdType.bannerAd:
        return 'Banner Ad';
    }
  }
}