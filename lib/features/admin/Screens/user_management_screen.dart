import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _filterUsers();
    });
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_users);
      return;
    }

    _filteredUsers =
        _users.where((user) {
          final email = user['email']?.toString().toLowerCase() ?? '';
          final firstName = user['firstName']?.toString().toLowerCase() ?? '';
          final lastName = user['lastName']?.toString().toLowerCase() ?? '';
          final displayName =
              user['displayName']?.toString().toLowerCase() ?? '';

          return email.contains(_searchQuery) ||
              firstName.contains(_searchQuery) ||
              lastName.contains(_searchQuery) ||
              displayName.contains(_searchQuery);
        }).toList();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // Fix the first issue: Don't orderBy a field that might not exist
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .get(); // Remove orderBy('name')

      final users =
          snapshot.docs.map((doc) {
            final data = doc.data();
            // Store firstName, lastName, and displayName separately for searching
            return {
              'id': doc.id,
              'firstName': data['firstName'] ?? '',
              'lastName': data['lastName'] ?? '',
              'displayName': data['displayName'] ?? '',
              'name':
                  data['firstName'] != null && data['lastName'] != null
                      ? '${data['firstName']} ${data['lastName']}'
                      : data['displayName'] ?? data['name'] ?? 'Unknown User',
              'email': data['email'] ?? 'No email',
              'isAdmin': data['isAdmin'] ?? false,
              'isContributor': data['isContributor'] ?? false,
              'isInvestor': data['isInvestor'] ?? false,
              'isBlocked': data['isBlocked'] ?? false,
              'userType': data['userType'] ?? 'customer',
              'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
              'lastActivity': data['lastLogin']?.toDate(),
            };
          }).toList();

      setState(() {
        _users = users;
        _filteredUsers = List.from(_users);
        _isLoading = false;
      });

      // Debug the loaded users
      debugPrint('Loaded ${_users.length} users');
      for (var user in _users) {
        debugPrint('User: ${user['name']}, Email: ${user['email']}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading users: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
    }
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

  // Change user type
  Future<void> _updateUserType(String userId, String newType) async {
    try {
      Map<String, dynamic> updates = {'userType': newType};

      // Set role flags based on type
      switch (newType) {
        case 'admin':
          updates['isAdmin'] = true;
          updates['isContributor'] = true;
          updates['isCustomer'] = true;
          break;
        case 'contributor':
          updates['isAdmin'] = false;
          updates['isContributor'] = true;
          updates['isCustomer'] = true;
          break;
        case 'investor':
          updates['isAdmin'] = false;
          updates['isContributor'] = false;
          updates['isInvestor'] = true;
          updates['isCustomer'] = true;
          break;
        default: // regular customer
          updates['isAdmin'] = false;
          updates['isContributor'] = false;
          updates['isInvestor'] = false;
          updates['isCustomer'] = true;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updates);

      // Refresh the list
      _loadUsers();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User type updated to $newType')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }

  // Send password reset email
  Future<void> _resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending reset email: $e')));
    }
  }

  // Block/unblock user
  Future<void> _toggleUserBlock(String userId, bool currentlyBlocked) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBlocked': !currentlyBlocked,
      });

      // Refresh the list
      _loadUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentlyBlocked ? 'User unblocked' : 'User blocked'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'admin':
        return Colors.red;
      case 'contributor':
        return Colors.blue;
      case 'investor':
        return Colors.green;
      default:
        return Colors.grey;
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
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 8,
              ),
            ),
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
                      final userId = user['id'];
                      final email = user['email'] ?? 'No email';
                      final name = [
                        user['firstName'] ?? '',
                        user['lastName'] ?? '',
                      ].where((s) => s.isNotEmpty).join(' ');
                      final userType = user['userType'] ?? 'customer';
                      final isBlocked = user['isBlocked'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ExpansionTile(
                          title: Text(name.isEmpty ? email : name),
                          subtitle: Text(email),
                          leading: CircleAvatar(
                            backgroundColor: _getUserTypeColor(userType),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          trailing:
                              isBlocked
                                  ? const Icon(Icons.block, color: Colors.red)
                                  : null,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User type selection
                                  Row(
                                    children: [
                                      const Text('User Type: '),
                                      const SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: userType,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'admin',
                                            child: Text('Admin'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'contributor',
                                            child: Text('Contributor'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'investor',
                                            child: Text('Investor'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'customer',
                                            child: Text('Customer'),
                                          ),
                                        ],
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            _updateUserType(userId, newValue);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Action buttons
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.password),
                                        label: const Text('Reset Password'),
                                        onPressed: () => _resetPassword(email),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        icon: Icon(
                                          isBlocked
                                              ? Icons.person_add
                                              : Icons.block,
                                        ),
                                        label: Text(
                                          isBlocked
                                              ? 'Unblock User'
                                              : 'Block User',
                                        ),
                                        onPressed:
                                            () => _toggleUserBlock(
                                              userId,
                                              isBlocked,
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isBlocked
                                                  ? Colors.green
                                                  : Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
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
