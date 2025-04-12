import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String refreshKey;
  
  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.refreshKey,
  });

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator> {
  String? _lastUpdated;
  
  @override
  void initState() {
    super.initState();
    _loadLastUpdatedTime();
  }
  
  Future<void> _loadLastUpdatedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString('last_updated_${widget.refreshKey}');
    
    if (mounted && timestamp != null) {
      setState(() {
        _lastUpdated = _formatTimestamp(DateTime.parse(timestamp));
      });
    }
  }
  
  Future<void> _saveLastUpdatedTime() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_updated_${widget.refreshKey}', now.toIso8601String());
    
    if (mounted) {
      setState(() {
        _lastUpdated = _formatTimestamp(now);
      });
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM dd, h:mm a').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_lastUpdated != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Updated: $_lastUpdated',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await widget.onRefresh();
              await _saveLastUpdatedTime();
            },
            color: const Color(0xFFd2982a),
            backgroundColor: Colors.white,
            strokeWidth: 3,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}