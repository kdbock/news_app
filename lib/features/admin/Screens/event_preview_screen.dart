import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventPreviewScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const EventPreviewScreen({super.key, required this.id, required this.data});

  @override
  _EventPreviewScreenState createState() => _EventPreviewScreenState();
}

class _EventPreviewScreenState extends State<EventPreviewScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] ?? 'No Title';
    final description = widget.data['description'] ?? 'No description provided';
    final location = widget.data['location'] ?? 'No location specified';
    final imageUrl = widget.data['imageUrl'] ?? '';
    final eventDate = widget.data['eventDate']?.toDate() ?? DateTime.now();
    final startTime = widget.data['startTime'] ?? 'Not specified';
    final endTime = widget.data['endTime'] ?? 'Not specified';
    final organizer = widget.data['organizer'] ?? 'Unknown Organizer';
    final contactName = widget.data['contactName'] ?? '';
    final contactEmail = widget.data['contactEmail'] ?? '';
    final contactPhone = widget.data['contactPhone'] ?? '';
    final DateTime submittedAt =
        widget.data['submittedAt']?.toDate() ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Preview'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _approveEvent(),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _rejectEvent(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image if available
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.white54,
                          ),
                        ),
                  ),

                // Event details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date and time
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFFd2982a),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(eventDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFFd2982a),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$startTime - $endTime',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFd2982a),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 16),

                      // Organizer
                      const Text(
                        'Organizer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(organizer, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),

                      // Contact info
                      if (contactName.isNotEmpty ||
                          contactEmail.isNotEmpty ||
                          contactPhone.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (contactName.isNotEmpty)
                              Text(
                                'Name: $contactName',
                                style: const TextStyle(fontSize: 16),
                              ),
                            if (contactEmail.isNotEmpty)
                              Text(
                                'Email: $contactEmail',
                                style: const TextStyle(fontSize: 16),
                              ),
                            if (contactPhone.isNotEmpty)
                              Text(
                                'Phone: $contactPhone',
                                style: const TextStyle(fontSize: 16),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Submission info section
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
                              'Submission Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Submitted on ${DateFormat('MMM d, yyyy').format(submittedAt)}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status: Pending Review',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approveEvent() async {
    setState(() => _isLoading = true);

    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Approve Event'),
              content: const Text(
                'Are you sure you want to approve this event? '
                'It will be published immediately.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('APPROVE'),
                ),
              ],
            ),
      );

      if (confirm != true) {
        setState(() => _isLoading = false);
        return;
      }

      // Check if still mounted before showing snackbar
      if (!mounted) return;

      // Update event status in Firestore
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.id)
          .update({
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
          });

      // Check if still mounted before showing success message and navigating
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event approved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving event: $e')));
      }
    }
  }

  Future<void> _rejectEvent(BuildContext context) async {
    try {
      // Show dialog to get rejection reason
      final String? reason = await showDialog<String>(
        context: context,
        builder: (context) {
          final TextEditingController controller = TextEditingController();
          return AlertDialog(
            title: const Text('Reject Event'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please provide a reason for rejection:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter reason for rejection',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(controller.text),
                child: const Text('REJECT'),
              ),
            ],
          );
        },
      );

      if (reason == null || reason.isEmpty) return;

      setState(() => _isLoading = true);

      // Update event status in Firestore
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.id)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      // Check if still mounted before showing success message and navigating
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event rejected')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting event: $e')));
      }
    }
  }
}
