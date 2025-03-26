import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitSponsoredEventScreen extends StatefulWidget {
  const SubmitSponsoredEventScreen({super.key});

  @override
  State<SubmitSponsoredEventScreen> createState() =>
      _SubmitSponsoredEventScreenState();
}

class _SubmitSponsoredEventScreenState
    extends State<SubmitSponsoredEventScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;
  String? _selectedTier;
  final List<String> _eventImages = [];

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

  final Map<String, double> _sponsorshipTiers = {
    'Basic (1-day promotion)': 49.99,
    'Featured (3-day promotion)': 99.99,
    'Premium (7-day promotion)': 199.99,
  };

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
    // Placeholder for image picker functionality
    setState(() {
      // Mock adding an image
      if (_eventImages.length < 5) {
        _eventImages.add('event_image_${_eventImages.length + 1}.jpg');
      }
    });
  }

  Future<void> _submitEvent() async {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_selectedTier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sponsorship tier')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save event to Firestore
      await _saveEventToFirestore();

      // Simulate payment processing with a delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Event Submitted'),
                content: const Text(
                  'Your sponsored event has been submitted and will be reviewed shortly. '
                  'You will receive a confirmation email with details about your listing.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting event: $e')));
      }
    }
  }

  Future<void> _saveEventToFirestore() async {
    if (_startDate == null) return;

    // Create a DateTime object with date and time combined
    final DateTime eventDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );

    // Format times for display
    final String formattedStartTime =
        _startTime != null ? _startTime!.format(context) : '12:00 PM';

    final String? formattedEndTime =
        _endTime?.format(context);

    // Determine sponsorship tier duration
    int promotionDays = 1;
    if (_selectedTier == 'Featured (3-day promotion)') {
      promotionDays = 3;
    } else if (_selectedTier == 'Premium (7-day promotion)') {
      promotionDays = 7;
    }

    // Calculate promotion end date
    final DateTime promotionEndDate = DateTime.now().add(
      Duration(days: promotionDays),
    );

    try {
      // Create the event document in Firestore
      await FirebaseFirestore.instance.collection('events').add({
        'title': _eventTitleController.text,
        'description': _descriptionController.text,
        'location': '${_venueController.text}, ${_addressController.text}',
        'eventDate': Timestamp.fromDate(eventDateTime),
        'startTime': formattedStartTime,
        'endTime': formattedEndTime,
        'organizer': _organizationController.text,
        'contactName': _contactNameController.text,
        'contactEmail': _emailController.text,
        'contactPhone': _phoneController.text,
        'eventType': _selectedEventType,
        'isSponsored': true,
        'sponsorshipTier': _selectedTier,
        'promotionEndDate': Timestamp.fromDate(promotionEndDate),
        'ticketLink':
            _ticketLinkController.text.isEmpty
                ? null
                : 'https://${_ticketLinkController.text}',
        'hashtags': _hashtagsController.text,
        'ageRestrictions': _ageRestrictionsController.text,
        'rainDate': _rainDate != null ? Timestamp.fromDate(_rainDate!) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      rethrow; // Pass the error up to be handled by the calling function
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Sponsored Event'),
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

                          if (_eventImages.isNotEmpty)
                            Container(
                              height: 100,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _eventImages.length,
                                itemBuilder: (context, index) {
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
                                          color: Colors.grey[200],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.event,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _eventImages.removeAt(index);
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
                    Step(
                      title: const Text('Sponsorship & Payment'),
                      isActive: _currentStep >= 3,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Sponsorship Tier',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose how long you want your event to be promoted',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          ..._sponsorshipTiers.entries.map((entry) {
                            return RadioListTile<String>(
                              title: Text(entry.key),
                              value: entry.key,
                              groupValue: _selectedTier,
                              onChanged: (value) {
                                setState(() {
                                  _selectedTier = value;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
