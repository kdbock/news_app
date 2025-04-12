import 'package:flutter/material.dart';

class AdFeedbackOverlay extends StatelessWidget {
  final String adId;

  const AdFeedbackOverlay({super.key, required this.adId});

  void _handleFeedback(String value) {
    // Handle feedback logic here
    debugPrint('Feedback selected: $value for Ad ID: $adId');
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 16),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: "not_interested",
          child: Text("Not interested in this"),
        ),
        const PopupMenuItem(
          value: "report",
          child: Text("Report this ad"),
        ),
        const PopupMenuItem(
          value: "why",
          child: Text("Why am I seeing this?"),
        ),
      ],
      onSelected: _handleFeedback,
    );
  }
}