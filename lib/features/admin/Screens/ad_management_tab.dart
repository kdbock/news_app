import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdManagementTab extends StatelessWidget {
  const AdManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ads').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No ads found.'));
        }

        final ads = snapshot.data!.docs;

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return ListTile(
              title: Text(ad['title'] ?? 'Untitled Ad'),
              subtitle: Text('Cost: \$${ad['cost'] ?? 0}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('ads')
                      .doc(ad.id)
                      .delete();
                },
              ),
            );
          },
        );
      },
    );
  }
}
