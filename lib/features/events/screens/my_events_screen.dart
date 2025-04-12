import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:neusenews/widgets/app_drawer.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingEvents = [];
  List<Map<String, dynamic>> _approvedEvents = [];
  List<Map<String, dynamic>> _rejectedEvents = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Query events created by this user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('createdBy', isEqualTo: user.uid)
          .get();
      
      List<Map<String, dynamic>> pending = [];
      List<Map<String, dynamic>> approved = [];
      List<Map<String, dynamic>> rejected = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending_review';
        final eventData = {
          'id': doc.id,
          ...data,
        };
        
        if (status == 'approved') {
          approved.add(eventData);
        } else if (status == 'rejected') {
          rejected.add(eventData);
        } else {
          pending.add(eventData);
        }
      }
      
      if (mounted) {
        setState(() {
          _pendingEvents = pending;
          _approvedEvents = approved;
          _rejectedEvents = rejected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading your events: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: const Color(0xFFd2982a),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending (${_pendingEvents.length})'),
            Tab(text: 'Approved (${_approvedEvents.length})'),
            Tab(text: 'Rejected (${_rejectedEvents.length})'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFd2982a)))
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventsList(_pendingEvents, 'pending'),
                  _buildEventsList(_approvedEvents, 'approved'),
                  _buildEventsList(_rejectedEvents, 'rejected'),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/submit-event').then((_) => _loadEvents());
        },
        backgroundColor: const Color(0xFFd2982a),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEventsList(List<Map<String, dynamic>> events, String status) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'approved' ? Icons.check_circle : 
              status == 'rejected' ? Icons.cancel : 
              Icons.hourglass_empty,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              status == 'approved' ? 'No approved events' :
              status == 'rejected' ? 'No rejected events' :
              'No pending events',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (status == 'pending')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/submit-event');
                },
                icon: const Icon(Icons.add),
                label: const Text('SUBMIT NEW EVENT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = events[index];
        final eventDate = event['eventDate'] as Timestamp?;
        final formattedDate = eventDate != null
            ? DateFormat('MMM d, yyyy').format(eventDate.toDate())
            : 'Date not specified';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator at top
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: status == 'approved' ? Colors.green[100] :
                         status == 'rejected' ? Colors.red[100] :
                         Colors.orange[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'approved' ? Icons.check_circle : 
                      status == 'rejected' ? Icons.cancel : 
                      Icons.pending,
                      size: 16,
                      color: status == 'approved' ? Colors.green : 
                             status == 'rejected' ? Colors.red :
                             Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status == 'approved' ? 'Approved' :
                      status == 'rejected' ? 'Rejected' :
                      'Pending Review',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'approved' ? Colors.green[800] : 
                               status == 'rejected' ? Colors.red[800] :
                               Colors.orange[800],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Event details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'] ?? 'Untitled Event',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event['location'] ?? 'No location',
                            style: TextStyle(color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          event['startTime'] ?? 'No time specified',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    
                    // Show rejection reason if rejected
                    if (status == 'rejected' && event['rejectionReason'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red[200]!)
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(event['rejectionReason']),
                          ],
                        ),
                      ),
                    
                    // Action buttons
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // View full details
                            _showFullDetails(context, event);
                          },
                          child: const Text('VIEW DETAILS'),
                        ),
                        const SizedBox(width: 8),
                        if (status == 'rejected')
                          ElevatedButton(
                            onPressed: () {
                              _resubmitEvent(event);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFd2982a),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('RESUBMIT'),
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
    );
  }
  
  void _showFullDetails(BuildContext context, Map<String, dynamic> event) {
    final eventDate = event['eventDate'] as Timestamp?;
    final formattedDate = eventDate != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(eventDate.toDate())
        : 'Date not specified';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    event['imageUrl'],
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                event['title'] ?? 'Untitled Event',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Date & Time', '$formattedDate\n${event['startTime'] ?? 'Time not specified'}'),
              _buildDetailRow('Location', event['location'] ?? 'No location provided'),
              _buildDetailRow('Organizer', event['organizer'] ?? 'Not specified'),
              if (event['description'] != null) 
                _buildDetailRow('Description', event['description']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd2982a),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  void _resubmitEvent(Map<String, dynamic> event) {
    // Navigate to submit event screen with the event data
    Navigator.pushNamed(
      context, 
      '/submit-event',
      arguments: event,
    ).then((_) => _loadEvents());
  }
}