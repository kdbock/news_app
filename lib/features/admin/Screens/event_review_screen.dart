import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventReviewScreen extends StatefulWidget {
  const EventReviewScreen({super.key});

  @override
  _EventReviewScreenState createState() => _EventReviewScreenState();
}

class _EventReviewScreenState extends State<EventReviewScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingEvents = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchPendingEvents();
  }

  Future<void> _fetchPendingEvents() async {
    setState(() => _isLoading = true);

    try {
      // Check if user is admin
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to access this page.');
      }

      // Get events that need review
      final snapshot =
          await _firestore
              .collection('events')
              .where('status', isEqualTo: 'pending_review')
              .orderBy('createdAt', descending: true)
              .get();

      debugPrint('Found ${snapshot.docs.length} pending events');

      final events =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title'] ?? 'Untitled Event',
              'description': data['description'] ?? '',
              'location': data['location'] ?? 'No location specified',
              'eventDate': data['eventDate']?.toDate() ?? DateTime.now(),
              'startTime': data['startTime'] ?? '',
              'endTime': data['endTime'] ?? '',
              'organizer': data['organizer'] ?? 'Unknown Organizer',
              'contactName': data['contactName'] ?? '',
              'contactEmail': data['contactEmail'] ?? '',
              'contactPhone': data['contactPhone'] ?? '',
              'eventType': data['eventType'] ?? '',
              'ticketLink': data['ticketLink'] ?? '',
              'hashtags': data['hashtags'] ?? '',
              'ageRestrictions': data['ageRestrictions'] ?? '',
              'rainDate': data['rainDate']?.toDate(),
              'imageUrl': data['imageUrl'] ?? '',
              'isSponsored': data['isSponsored'] ?? true,
              'submissionFee': data['submissionFee'] ?? 0,
              'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
            };
          }).toList();

      setState(() {
        _pendingEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching pending events: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading events: $e')));
      }
    }
  }

  Future<void> _approveEvent(String id) async {
    try {
      setState(() => _isLoading = true);

      // Set the status to published and add approvedAt date
      await _firestore.collection('events').doc(id).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      // Refresh the list
      await _fetchPendingEvents();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event approved successfully!')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving event: $e')));
    }
  }

  Future<void> _rejectEvent(String id) async {
    try {
      // Show dialog to get rejection reason
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => _buildRejectDialog(),
      );

      if (reason == null) {
        return; // User cancelled
      }

      setState(() => _isLoading = true);

      // Set the status to rejected and add reason
      await _firestore.collection('events').doc(id).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Refresh the list
      await _fetchPendingEvents();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event rejected')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting event: $e')));
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
          hintText: 'Provide feedback to the event organizer',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Review'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _fetchPendingEvents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : _pendingEvents.isEmpty
              ? const Center(child: Text('No pending events to review'))
              : ListView.builder(
                itemCount: _pendingEvents.length,
                itemBuilder: (context, index) {
                  final event = _pendingEvents[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event image if available
                        if (event['imageUrl'] != null &&
                            event['imageUrl'].isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: event['imageUrl'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFd2982a),
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.error),
                                ),
                          ),

                        // Event details
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      event['title'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${event['submissionFee']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFd2982a),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Event date and time
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat(
                                      'MMMM d, yyyy',
                                    ).format(event['eventDate']),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${event['startTime']} - ${event['endTime']}',
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Location
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(event['location'])),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Organizer
                              Row(
                                children: [
                                  const Icon(Icons.business, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(event['organizer'])),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Submission date
                              Text(
                                'Submitted: ${DateFormat('MMM d, yyyy').format(event['createdAt'])}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed:
                                        () => _showFullEventDetails(event),
                                    child: const Text('VIEW DETAILS'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _rejectEvent(event['id']),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('REJECT'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _approveEvent(event['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('APPROVE'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  void _showFullEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Event Details'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event image
                    if (event['imageUrl'] != null &&
                        event['imageUrl'].isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: event['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                      ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Event metadata section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Date',
                            DateFormat(
                              'MMMM d, yyyy',
                            ).format(event['eventDate']),
                          ),
                          _buildDetailRow(
                            'Time',
                            '${event['startTime']} - ${event['endTime']}',
                          ),
                          _buildDetailRow('Location', event['location']),
                          _buildDetailRow('Organizer', event['organizer']),
                          _buildDetailRow('Event Type', event['eventType']),
                          if (event['rainDate'] != null)
                            _buildDetailRow(
                              'Rain Date',
                              DateFormat(
                                'MMMM d, yyyy',
                              ).format(event['rainDate']),
                            ),
                          if (event['ageRestrictions'] != null &&
                              event['ageRestrictions'].isNotEmpty)
                            _buildDetailRow(
                              'Age Restrictions',
                              event['ageRestrictions'],
                            ),
                          if (event['ticketLink'] != null &&
                              event['ticketLink'].isNotEmpty)
                            _buildDetailRow('Ticket Link', event['ticketLink']),
                          if (event['hashtags'] != null &&
                              event['hashtags'].isNotEmpty)
                            _buildDetailRow('Hashtags', event['hashtags']),
                        ],
                      ),
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
                    Text(event['description']),

                    const SizedBox(height: 16),

                    // Contact information
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Contact Name', event['contactName']),
                    _buildDetailRow('Contact Email', event['contactEmail']),
                    _buildDetailRow('Contact Phone', event['contactPhone']),

                    const SizedBox(height: 16),

                    // Submission information
                    const Text(
                      'Submission Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Submission Fee',
                      '\$${event['submissionFee']}',
                    ),
                    _buildDetailRow(
                      'Submission Date',
                      DateFormat('MMMM d, yyyy').format(event['createdAt']),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => _rejectEvent(event['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('REJECT EVENT'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _approveEvent(event['id']);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('APPROVE EVENT'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
