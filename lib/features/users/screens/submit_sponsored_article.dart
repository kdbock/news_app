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
  final _paymentFormKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _acceptDisclosure = false;
  File? _headerImage;
  bool _isProcessingPayment = false;
  String? _paymentError;
  String? _paymentIntentId;

  // Fixed flat rate of $50
  final double _articleSubmissionPrice = 50.00;

  // Form fields
  final _authorNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _ctaLinkController = TextEditingController();
  final _ctaTextController = TextEditingController();

  // Payment fields
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardNameController = TextEditingController();

  String? _selectedCategory;

  final List<String> _categories = [
    'Business',
    'Real Estate',
    'Health & Wellness',
    'Education',
    'Professional Services',
    'Local Interest',
    'Other',
  ];

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
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
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

      // Generate a mock payment ID
      _paymentIntentId =
          'mock_payment_${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _isProcessingPayment = false;
        _isLoading = true;
      });

      // Upload header image if selected
      String? imageUrl;

      if (_headerImage != null) {
        try {
          // Create storage reference
          final storageRef = FirebaseStorage.instance.ref().child(
            'sponsored_articles/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

          // Try the direct approach first
          try {
            final uploadTask = await storageRef.putFile(_headerImage!);
            imageUrl = await uploadTask.ref.getDownloadURL();
          } catch (e) {
            if (e.toString().contains('PigeonSettableMetadata') ||
                e.toString().contains('null object reference')) {
              // Fallback approach with explicit metadata
              final metadata = SettableMetadata(
                contentType: 'image/jpeg',
                customMetadata: {'picked': 'true'},
              );

              final uploadTask = await storageRef.putFile(
                _headerImage!,
                metadata,
              );
              imageUrl = await uploadTask.ref.getDownloadURL();
            } else {
              rethrow;
            }
          }

          debugPrint('Uploaded header image to: $imageUrl');
        } catch (e) {
          debugPrint('Error uploading header image: $e');
          // Continue without image if upload fails
        }
      }

      // Calculate expiration date (30 days)
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30));

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
        'price': _articleSubmissionPrice,
        'isSponsored': true,
        'publishedAt': null, // Will be set after review
        'expiresAt': Timestamp.fromDate(expiresAt),
        'submittedAt': FieldValue.serverTimestamp(),
        'submittedBy': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'status': 'pending_review', // For editorial workflow
        'paymentStatus': 'paid',
        'paymentId': _paymentIntentId,
        'paymentDate': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('sponsored_articles')
          .add(articleData);

      if (mounted) {
        setState(() => _isLoading = false);

        // Show confirmation dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Article Submitted'),
                content: const Text(
                  'Your sponsored article has been submitted and will be reviewed shortly. '
                  'You will receive a confirmation email when your article is published.',
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
        setState(() {
          _isProcessingPayment = false;
          _isLoading = false;
          _paymentError = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting article: $e')));
      }
    }
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

                    // Flat rate pricing
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
                            'Sponsored Article',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('30 Days Publication'),
                              Text(
                                '\$${_articleSubmissionPrice.toStringAsFixed(2)}',
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

                          const SizedBox(height: 24),

                          // Payment section
                          const Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2d2c31),
                            ),
                          ),
                          const SizedBox(height: 16),

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
                                ],
                              )
                              : Form(
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
                                      // Card number field
                                      TextFormField(
                                        controller: _cardNumberController,
                                        decoration: const InputDecoration(
                                          labelText: 'Card Number',
                                          hintText: 'XXXX XXXX XXXX XXXX',
                                          border: OutlineInputBorder(),
                                          suffixIcon: Icon(Icons.credit_card),
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
                                            _cardNumberController.selection =
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
                                              controller: _expiryDateController,
                                              decoration: const InputDecoration(
                                                labelText: 'Expiry Date',
                                                hintText: 'MM/YY',
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: _validateExpiryDate,
                                              onChanged: (value) {
                                                // Auto-format expiry date
                                                if (value.length == 2 &&
                                                    !value.contains('/')) {
                                                  _expiryDateController.text =
                                                      '$value/';
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
                                              decoration: const InputDecoration(
                                                labelText: 'CVV',
                                                hintText: 'XXX',
                                                border: OutlineInputBorder(),
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

                                      const SizedBox(height: 16),
                                      const Text(
                                        'By submitting, you agree to our terms and conditions.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
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
                              child: const Text('SUBMIT & PAY \$50.00'),
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
