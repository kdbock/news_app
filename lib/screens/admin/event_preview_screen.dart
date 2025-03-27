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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final DateTime eventDate =
        widget.data['startDate']?.toDate() ?? DateTime.now();
    final String formattedDate = DateFormat(
      'EEEE, MMMM d, yyyy',
    ).format(eventDate);
    final String formattedTime =
        widget.data['allDay'] == true
            ? 'All Day'
            : '${DateFormat('h:mm a').format(eventDate)} - ${DateFormat('h:mm a').format(eventDate.add(const Duration(hours: 2)))}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Preview'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        actions: [
          if (widget.data['status'] == 'pending_review')
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: 'Approve Event',
              onPressed: _approveEvent,
            ),
          if (widget.data['status'] == 'pending_review')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              tooltip: 'Reject Event',
              onPressed: _rejectEvent,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.data['status']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusLabel(widget.data['status']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Event title
                    Text(
                      widget.data['eventTitle'] ?? 'Untitled Event',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    const SizedBox(height: 8),

                    // Organization
                    Text(
                      widget.data['organizerName'] ?? 'Unknown Organizer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),

                    // Date and time
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(formattedDate),
                      subtitle: Text(formattedTime),
                    ),

                    // Location
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(
                        widget.data['venue'] ?? 'No location specified',
                      ),
                    ),

                    // Event Type
                    if (widget.data['eventType'] != null)
                      ListTile(
                        leading: const Icon(Icons.category),
                        title: Text(widget.data['eventType']),
                      ),

                    const Divider(),

                    // Description
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      widget.data['description'] ?? 'No description provided',
                    ),

                    // Additional info
                    if (widget.data['additionalInfo'] != null &&
                        widget.data['additionalInfo']
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Additional Information',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(widget.data['additionalInfo']),
                    ],

                    const SizedBox(height: 32),

                    // Submitter info
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Contact: ${widget.data['contactName'] ?? widget.data['organizerName'] ?? 'N/A'}',
                          ),
                          Text(
                            'Email: ${widget.data['contactEmail'] ?? widget.data['organizerEmail'] ?? 'N/A'}',
                          ),
                          Text(
                            'Phone: ${widget.data['contactPhone'] ?? widget.data['organizerPhone'] ?? 'N/A'}',
                          ),
                          if (widget.data['submittedAt'] != null)
                            Text(
                              'Submitted on: ${DateFormat('MM/dd/yyyy').format(widget.data['submittedAt'].toDate())}',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending_review':
        return 'PENDING REVIEW';
      case 'published':
        return 'PUBLISHED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'UNKNOWN';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending_review':
        return Colors.orange;
      case 'published':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _approveEvent() async {
    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.id)
          .update({
            'status': 'published',
            'publishedAt': FieldValue.serverTimestamp(),
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event approved and published')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving event: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectEvent() async {
    try {
      // Show dialog to get rejection reason
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => _buildRejectDialog(),
      );

      if (reason == null) return;

      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.id)
          .update({
            'status': 'rejected',
            'rejectionReason': reason,
            'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
            'reviewedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event rejected')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting event: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildRejectDialog() {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Reject Event'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Reason for rejection',
          hintText: 'Provide feedback to the submitter',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('REJECT'),
        ),
      ],
    );
  }
}
