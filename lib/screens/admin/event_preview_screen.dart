import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventPreviewScreen extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;

  const EventPreviewScreen({super.key, required this.id, required this.data});

  @override
  State<EventPreviewScreen> createState() => _EventPreviewScreenState();
}

class _EventPreviewScreenState extends State<EventPreviewScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final eventDate = widget.data['eventDate'] as Timestamp?;
    final formattedDate =
        eventDate != null
            ? DateFormat.yMMMd().add_jm().format(eventDate.toDate())
            : 'Date not specified';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Event'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
      ),
      body:
          _isProcessing
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.data['title'] ?? 'Untitled Event',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Event details
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Date & Time', formattedDate),
                            const Divider(),
                            _buildDetailRow(
                              'Location',
                              widget.data['location'] ?? 'Not specified',
                            ),
                            const Divider(),
                            _buildDetailRow(
                              'Organizer',
                              widget.data['organizerName'] ?? 'Not specified',
                            ),
                            const Divider(),
                            _buildDetailRow(
                              'Contact',
                              widget.data['contactEmail'] ?? 'Not specified',
                            ),
                            if (widget.data['isSponsored'] == true) ...[
                              const Divider(),
                              _buildDetailRow('Sponsored', 'Yes'),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Description
                    const Text(
                      'Event Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.data['description'] ??
                            'No description provided.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    // Image if available
                    if (widget.data['imageUrl'] != null &&
                        widget.data['imageUrl'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Event Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.data['imageUrl'],
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.error),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Approval buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => _processEvent(approved: false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => _processEvent(approved: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd2982a),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Future<void> _processEvent({required bool approved}) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Update the event status
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.id)
          .update({
            'status': approved ? 'approved' : 'rejected',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': FirebaseAuth.instance.currentUser?.uid,
          });

      if (!mounted) return;

      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Event ${approved ? 'approved' : 'rejected'} successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing event: $e')));
    }
  }
}
