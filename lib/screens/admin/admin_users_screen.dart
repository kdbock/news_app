import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neusenews/services/role_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoadUsers();
  }

  Future<void> _checkAdminAndLoadUsers() async {
    setState(() => _isLoading = true);

    try {
      bool isAdmin = await RoleService.hasAdminAccess();
      if (!isAdmin) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have administrator access'),
            ),
          );
        }
        return;
      }

      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    _users =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'email': data['email'] ?? '',
            'userType': data['userType'] ?? 'customer',
            'isAdmin': data['isAdmin'] ?? false,
            'isContributor': data['isContributor'] ?? false,
            'isInvestor': data['isInvestor'] ?? false,
            'isCustomer': data['isCustomer'] ?? true,
          };
        }).toList();

    // Sort users by user type, then by name
    _users.sort((a, b) {
      if (a['userType'] != b['userType']) {
        // Sort by user type priority: admin, contributor, investor, customer
        final typeOrder = {
          'administrator': 0,
          'contributor': 1,
          'investor': 2,
          'customer': 3,
        };
        return (typeOrder[a['userType']] ?? 3).compareTo(
          typeOrder[b['userType']] ?? 3,
        );
      }

      // If same type, sort by name
      String nameA = '${a['firstName']} ${a['lastName']}';
      String nameB = '${b['firstName']} ${b['lastName']}';
      return nameA.compareTo(nameB);
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      setState(() => _isLoading = true);

      // Create two separate maps - one for role boolean flags and another for userType string
      final Map<String, bool> roleBooleans = {
        'isAdmin': newRole == 'administrator',
        'isContributor': newRole == 'contributor',
        'isInvestor': newRole == 'investor',
        'isCustomer': newRole == 'customer',
      };

      // Update role booleans first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(roleBooleans);

      // Then update user type separately
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'userType': newRole,
      });

      await _loadUsers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User role updated to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating user role: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2d2c31),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFd2982a)),
              )
              : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getUserTypeColor(user['userType']),
                        child: Text(
                          user['firstName'].isNotEmpty
                              ? user['firstName'][0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('${user['firstName']} ${user['lastName']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email']),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(user['userType']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user['userType'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showRoleEditDialog(user),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'administrator':
        return Colors.red;
      case 'contributor':
        return Colors.blue;
      case 'investor':
        return Colors.purple;
      case 'customer':
      default:
        return Colors.green;
    }
  }

  void _showRoleEditDialog(Map<String, dynamic> user) {
    String selectedRole = user['userType'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Edit User Role: ${user['firstName']} ${user['lastName']}',
            ),
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      title: const Text('Administrator'),
                      subtitle: const Text('Full system access'),
                      value: 'administrator',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setStateDialog(() => selectedRole = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Contributor'),
                      subtitle: const Text('Can submit content'),
                      value: 'contributor',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setStateDialog(() => selectedRole = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Investor'),
                      subtitle: const Text('Access to financial data'),
                      value: 'investor',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setStateDialog(() => selectedRole = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Customer'),
                      subtitle: const Text('Standard user access'),
                      value: 'customer',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setStateDialog(() => selectedRole = value!);
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateUserRole(user['id'], selectedRole);
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
    );
  }
}
