import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/services/ad_service.dart';
import 'package:neusenews/features/ads/screens/ad_confirmation_screen.dart';
import 'package:neusenews/widgets/payment_form.dart';

class AdCheckoutScreen extends StatefulWidget {
  final Ad ad;
  final File imageFile;

  const AdCheckoutScreen({
    super.key,
    required this.ad,
    required this.imageFile,
  });

  @override
  State<AdCheckoutScreen> createState() => _AdCheckoutScreenState();
}

class _AdCheckoutScreenState extends State<AdCheckoutScreen> {
  final AdService _adService = AdService();
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _processPayment() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Upload image to Firebase Storage
      final String imageUrl = await _uploadImage();

      // 2. Update ad with image URL
      final Ad updatedAd = widget.ad.copyWith(imageUrl: imageUrl);

      // 3. Save ad to Firestore
      final String adId = await _adService.createAd(updatedAd);

      // 4. Navigate to confirmation page
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AdConfirmationScreen(ad: updatedAd.copyWith(id: adId)),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process payment: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<String> _uploadImage() async {
    // Create a unique filename based on timestamp
    final String fileName = 'ads/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

    // Upload image
    final UploadTask uploadTask = storageRef.putFile(widget.imageFile);
    final TaskSnapshot snapshot = await uploadTask;

    // Get download URL
    return await snapshot.ref.getDownloadURL();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFFd2982a),
      ),
      body:
          _isProcessing
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFd2982a)),
                    SizedBox(height: 16),
                    Text(
                      'Processing your payment...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ad Image Preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    widget.imageFile,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Ad Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getAdTypeDisplayName(widget.ad.type),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.ad.headline,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatDate(widget.ad.startDate)} to ${_formatDate(widget.ad.endDate)}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            // Price breakdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text('\$${widget.ad.cost.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tax:'),
                                const Text(
                                  '\$0.00',
                                ), // Assuming no tax for simplicity
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '\$${widget.ad.cost.toStringAsFixed(2)}',
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

                    // Payment Information
                    const Text(
                      'Payment Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Form (Will need to implement the PaymentForm widget separately)
                    PaymentForm(
                      amount: widget.ad.cost,
                      onPaymentComplete: _processPayment,
                    ),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
