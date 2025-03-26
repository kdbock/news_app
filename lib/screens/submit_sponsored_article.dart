import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SubmitSponsoredArticleScreen extends StatefulWidget {
  const SubmitSponsoredArticleScreen({super.key});

  @override
  _SubmitSponsoredArticleScreenState createState() =>
      _SubmitSponsoredArticleScreenState();
}

class _SubmitSponsoredArticleScreenState
    extends State<SubmitSponsoredArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _acceptDisclosure = false;
  File? _headerImage;

  // Form fields
  final _authorNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _ctaLinkController = TextEditingController();
  final _ctaTextController = TextEditingController();

  String? _selectedCategory;
  String _selectedDuration = '30';

  final List<String> _categories = [
    'Business',
    'Real Estate',
    'Health & Wellness',
    'Education',
    'Professional Services',
    'Local Interest',
    'Other',
  ];

  final Map<String, double> _durationPrices = {
    '7': 99.99,
    '30': 249.99,
    '90': 599.99,
  };

  @override
  void dispose() {
    _authorNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _ctaLinkController.dispose();
    _ctaTextController.dispose();
    super.dispose();
  }

  Future<void> _pickHeaderImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _headerImage = File(image.path);
      });
    }
  }

  Future<void> _submitArticle() async {
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

    if (!_acceptDisclosure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the sponsored content disclosure'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload header image if selected
      String? imageUrl;

      if (_headerImage != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          'sponsored_articles/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        await storageRef.putFile(_headerImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Calculate expiration date
      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: int.parse(_selectedDuration)));

      // Create article data
      final articleData = {
        'authorName': _authorNameController.text,
        'companyName': _companyNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'title': _titleController.text,
        'category': _selectedCategory,
        'content': _contentController.text,
        'ctaLink': _ctaLinkController.text,
        'ctaText': _ctaTextController.text,
        'headerImageUrl': imageUrl,
        'duration': int.parse(_selectedDuration),
        'price': _durationPrices[_selectedDuration],
        'isSponsored': true,
        'publishedAt': null, // Will be set after review and payment
        'expiresAt': Timestamp.fromDate(expiresAt),
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'status': 'pending_review', // For editorial workflow
      };

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('sponsored_articles')
          .add(articleData);

      if (mounted) {
        setState(() => _isLoading = false);

        // Navigate to payment screen
        Navigator.pushReplacementNamed(
          context,
          '/payment',
          arguments: {
            'id': docRef.id,
            'type': 'article',
            'title': _titleController.text,
            'amount': _durationPrices[_selectedDuration],
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting article: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Sponsored Article'),
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
                      'Submit a Sponsored Article',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2d2c31),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Promote your business or services with a sponsored article. All content is subject to editorial review.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Plans and pricing
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sponsorship Duration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Duration selection
                          RadioListTile<String>(
                            title: const Text('7 Days'),
                            subtitle: Text(
                              '\$${_durationPrices["7"]?.toStringAsFixed(2)}',
                            ),
                            value: '7',
                            groupValue: _selectedDuration,
                            activeColor: const Color(0xFFd2982a),
                            onChanged: (value) {
                              setState(() {
                                _selectedDuration = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('30 Days'),
                            subtitle: Text(
                              '\$${_durationPrices["30"]?.toStringAsFixed(2)}',
                            ),
                            value: '30',
                            groupValue: _selectedDuration,
                            activeColor: const Color(0xFFd2982a),
                            onChanged: (value) {
                              setState(() {
                                _selectedDuration = value!;
                              });
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('90 Days'),
                            subtitle: Text(
                              '\$${_durationPrices["90"]?.toStringAsFixed(2)}',
                            ),
                            value: '90',
                            groupValue: _selectedDuration,
                            activeColor: const Color(0xFFd2982a),
                            onChanged: (value) {
                              setState(() {
                                _selectedDuration = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Business Information
                          const Text(
                            'Business Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d2c31),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Author/Contact Information
                          TextFormField(
                            controller: _authorNameController,
                            decoration: const InputDecoration(
                              labelText: 'Author Name*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please enter author name'
                                        : null,
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _companyNameController,
                            decoration: const InputDecoration(
                              labelText: 'Company/Organization Name*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please enter company name'
                                        : null,
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Email*',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator:
                                      (value) =>
                                          value!.isEmpty
                                              ? 'Please enter contact email'
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
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Article Information
                          const Text(
                            'Article Content',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d2c31),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Article Title*',
                              border: OutlineInputBorder(),
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please enter article title'
                                        : null,
                          ),

                          const SizedBox(height: 16),

                          DropdownButtonFormField(
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
                                _selectedCategory = value as String;
                              });
                            },
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select a category'
                                        : null,
                          ),

                          const SizedBox(height: 16),

                          // Header image
                          const Text(
                            'Header Image (Recommended)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_headerImage != null)
                            Stack(
                              children: [
                                Container(
                                  height: 180,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_headerImage!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _headerImage = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
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
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _pickHeaderImage,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: const Text('Add Header Image'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFd2982a),
                                foregroundColor: Colors.white,
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Article content
                          TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              labelText: 'Article Content*',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Include relevant details about your business, services, or promotions.',
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please enter article content'
                                        : value.length < 100
                                        ? 'Content should be at least 100 characters'
                                        : null,
                            maxLines: 10,
                            minLines: 5,
                          ),

                          const SizedBox(height: 24),

                          // Call to action
                          const Text(
                            'Call-to-Action',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d2c31),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _ctaLinkController,
                            decoration: const InputDecoration(
                              labelText: 'Website URL*',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Where should readers go to learn more?',
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please enter website URL'
                                        : null,
                            keyboardType: TextInputType.url,
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _ctaTextController,
                            decoration: const InputDecoration(
                              labelText: 'Button Text*',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Example: "Visit Our Website", "Shop Now", "Learn More"',
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Please enter button text'
                                        : null,
                          ),

                          const SizedBox(height: 24),

                          // Disclosure
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Disclosure',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This content will be clearly labeled as "Sponsored Content" in compliance with FTC guidelines. Your article will be reviewed by our editorial team before publication.',
                                  style: TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),

                                CheckboxListTile(
                                  title: const Text(
                                    'I understand this is sponsored content',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  value: _acceptDisclosure,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  activeColor: const Color(0xFFd2982a),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptDisclosure = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submitArticle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFd2982a),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('CONTINUE TO PAYMENT'),
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
