import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .orderBy('name')
              .get();

      final users =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name':
                  data['firstName'] != null && data['lastName'] != null
                      ? '${data['firstName']} ${data['lastName']}'
                      : data['name'] ?? 'Unknown User',
              'email': data['email'] ?? 'No email',
              'isAdmin': data['isAdmin'] ?? false,
              'isContributor': data['isContributor'] ?? false,
              'isInvestor': data['isInvestor'] ?? false,
              'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
              'lastActivity': data['lastActivity']?.toDate(),
            };
          }).toList();

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }

    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      final name = user['name'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _editUserRoles(Map<String, dynamic> user) async {
    bool isAdmin = user['isAdmin'] ?? false;
    bool isContributor = user['isContributor'] ?? false;
    bool isInvestor = user['isInvestor'] ?? false;

    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Edit User Roles: ${user['name']}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('Admin'),
                      value: isAdmin,
                      onChanged: (value) {
                        setState(() => isAdmin = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Contributor'),
                      value: isContributor,
                      onChanged: (value) {
                        setState(() => isContributor = value ?? false);
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Investor'),
                      value: isInvestor,
                      onChanged: (value) {
                        setState(() => isInvestor = value ?? false);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).pop({
                          'isAdmin': isAdmin,
                          'isContributor': isContributor,
                          'isInvestor': isInvestor,
                        }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFd2982a),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('SAVE'),
                  ),
                ],
              );
            },
          ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user['id'])
            .update({
              'isAdmin': result['isAdmin'],
              'isContributor': result['isContributor'],
              'isInvestor': result['isInvestor'],
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Update local state
        setState(() {
          final index = _users.indexWhere((u) => u['id'] == user['id']);
          if (index >= 0) {
            _users[index]['isAdmin'] = result['isAdmin'];
            _users[index]['isContributor'] = result['isContributor'];
            _users[index]['isInvestor'] = result['isInvestor'];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User roles updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user roles: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFd2982a)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        Expanded(
          child:
              _filteredUsers.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserListItem(user);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> user) {
    String roleBadges = '';
    if (user['isAdmin'] == true) roleBadges += 'Admin, ';
    if (user['isContributor'] == true) roleBadges += 'Contributor, ';
    if (user['isInvestor'] == true) roleBadges += 'Investor, ';
    if (roleBadges.isNotEmpty) {
      roleBadges = roleBadges.substring(
        0,
        roleBadges.length - 2,
      ); // Remove trailing comma
    } else {
      roleBadges = 'Standard User';
    }

    final lastActivity =
        user['lastActivity'] != null
            ? DateFormat('MMM d, yyyy').format(user['lastActivity'])
            : 'Never';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(user['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']),
            const SizedBox(height: 4),
            Text(
              'Roles: $roleBadges',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Last activity: $lastActivity'),
          ],
        ),
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFd2982a),
          child: Text(
            user['name'].toString().isNotEmpty
                ? user['name'].toString().substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editUserRoles(user),
        ),
      ),
    );
  }
}
