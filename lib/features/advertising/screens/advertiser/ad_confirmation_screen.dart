import 'package:flutter/material.dart';
import 'package:neusenews/features/advertising/models/ad.dart'; // Fixed import path
import 'package:neusenews/features/advertising/models/ad_type.dart'; // Added import
import 'package:intl/intl.dart';
import 'package:neusenews/screens/dashboard_screen.dart';

class AdConfirmationScreen extends StatelessWidget {
  final Ad ad;

  const AdConfirmationScreen({super.key, required this.ad});

  String _formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement Submitted'),
        backgroundColor: const Color(0xFFd2982a),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFFd2982a),
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Your advertisement has been submitted!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFd2982a),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Order ID:', ad.id ?? 'Processing'),
                    _buildInfoRow('Ad Type:', _getAdTypeDisplayName(ad.type)),
                    _buildInfoRow('Business:', ad.businessName),
                    _buildInfoRow(
                      'Duration:',
                      '${_formatDate(ad.startDate)} to ${_formatDate(ad.endDate)}',
                    ),
                    _buildInfoRow(
                      'Amount Paid:',
                      '\$${ad.cost.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow('Status:', 'Pending Approval'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What happens next?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Our team will review your advertisement within 24 hours. You will receive an email notification when your ad is approved and live on the app.',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                ),
                child: const Text(
                  'Return to Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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
      default:
        return 'Unknown'; // Added default case to prevent null return
    }
  }
}
