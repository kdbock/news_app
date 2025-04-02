import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/features/ads/screens/ad_checkout_screen.dart';

class AdCreationScreen extends StatefulWidget {
  final AdType? initialAdType;

  const AdCreationScreen({super.key, this.initialAdType});

  @override
  State<AdCreationScreen> createState() => _AdCreationScreenState();
}

class _AdCreationScreenState extends State<AdCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late AdType _selectedAdType;
  File? _imageFile;
  DateTime? _startDate;
  DateTime? _endDate;
  int _durationWeeks = 1;

  final _businessNameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  double _adCost = 0;

  final Map<AdType, double> _weeklyRates = {
    AdType.titleSponsor: 249.0,
    AdType.inFeedDashboard: 149.0,
    AdType.inFeedNews: 99.0,
    AdType.weather: 199.0,
  };

  @override
  void initState() {
    super.initState();
    _selectedAdType = widget.initialAdType ?? AdType.inFeedDashboard;
    _calculateCost();

    // Set initial start date to tomorrow
    _startDate = DateTime.now().add(const Duration(days: 1));
    _startDateController.text = DateFormat('MM/dd/yyyy').format(_startDate!);

    // Set initial end date based on duration
    _updateEndDate();
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
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
        _startDateController.text = DateFormat(
          'MM/dd/yyyy',
        ).format(_startDate!);
        _updateEndDate();
      });
    }
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
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image for your ad')),
        );
        return;
      }

      // Get current user ID
      final String? businessId = FirebaseAuth.instance.currentUser?.uid;

      if (businessId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to create an ad')),
        );
        return;
      }

      // Create ad object
      final Ad newAd = Ad(
        businessId: businessId,
        businessName: _businessNameController.text,
        headline: _headlineController.text,
        description: _descriptionController.text,
        imageUrl: '', // Will be populated by AdService
        linkUrl: _linkController.text,
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
          builder:
              (context) => AdCheckoutScreen(ad: newAd, imageFile: _imageFile!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Advertisement'),
        backgroundColor: const Color(0xFFd2982a),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ad Type Selection
              const Text(
                'Select Ad Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<AdType>(
                value: _selectedAdType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items:
                    AdType.values.map((AdType type) {
                      return DropdownMenuItem<AdType>(
                        value: type,
                        child: Text(
                          '${_getAdTypeDisplayName(type)} - \$${_weeklyRates[type]?.toStringAsFixed(2)}/week',
                        ),
                      );
                    }).toList(),
                onChanged: (AdType? newValue) {
                  setState(() {
                    _selectedAdType = newValue!;
                    _calculateCost();
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an ad type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Business Details
              const Text(
                'Business Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ad Content
              const Text(
                'Ad Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _headlineController,
                decoration: const InputDecoration(
                  labelText: 'Headline',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a headline';
                  }
                  if (value.length > 50) {
                    return 'Headline should be 50 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length > 200) {
                    return 'Description should be 200 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link URL',
                  border: OutlineInputBorder(),
                  hintText: 'https://www.yourbusiness.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a link URL';
                  }
                  final urlRegExp = RegExp(
                    r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
                  );
                  if (!urlRegExp.hasMatch(value)) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Upload
              const Text(
                'Ad Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to upload image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 16),

              // Duration Selection
              const Text(
                'Campaign Duration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      items:
                          [1, 2, 4, 8, 12].map((int duration) {
                            return DropdownMenuItem<int>(
                              value: duration,
                              child: Text(
                                '$duration week${duration > 1 ? 's' : ''}',
                              ),
                            );
                          }).toList(),
                      onChanged: (int? newValue) {
                        setState(() {
                          _durationWeeks = newValue!;
                          _updateEndDate();
                          _calculateCost();
                        });
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
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cost Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_getAdTypeDisplayName(_selectedAdType)} Rate:',
                          ),
                          Text(
                            '\$${_weeklyRates[_selectedAdType]?.toStringAsFixed(2)}/week',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Duration:'),
                          Text(
                            '$_durationWeeks week${_durationWeeks > 1 ? 's' : ''}',
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Cost:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_adCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFd2982a),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd2982a),
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
