import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SubmitNewsTipScreen extends StatefulWidget {
  const SubmitNewsTipScreen({super.key});

  @override
  State<SubmitNewsTipScreen> createState() => _SubmitNewsTipScreenState();
}

class _SubmitNewsTipScreenState extends State<SubmitNewsTipScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isAnonymous = false;
  final List<String> _mediaFiles = [];

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
    // Placeholder for image picker functionality
    setState(() {
      // Mock adding a media file
      if (_mediaFiles.length < 3) {
        _mediaFiles.add('media_${_mediaFiles.length + 1}.jpg');
      }
    });
  }

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

    setState(() => _isLoading = true);

    try {
      // Simulate submission with a delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Thank You!'),
                content: const Text(
                  'Your news tip has been submitted and will be reviewed by our editorial team. '
                  'We appreciate your contribution to local news.',
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
                              'We\'ll keep your identity private',
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
                                            Icons.photo,
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
