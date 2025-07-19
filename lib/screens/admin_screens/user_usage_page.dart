import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserUsagePage extends StatefulWidget {
  const UserUsagePage({super.key});

  @override
  _UserUsagePageState createState() => _UserUsagePageState();
}

class _UserUsagePageState extends State<UserUsagePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> allUsers = [];
  List<DocumentSnapshot> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      setState(() {
        allUsers = querySnapshot.docs;
        filteredUsers = List.from(allUsers); // Initially show all users
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  void _filterUsers() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers =
          allUsers.where((user) {
            final name =
                user.data().toString().contains('name')
                    ? user['name'].toLowerCase()
                    : '';
            return name.contains(query);
          }).toList();
    });
  }

  void _toggleStatus(int index) {
    final user = filteredUsers[index];
    final currentStatus =
        user.data().toString().contains('status') ? user['status'] : 'Inactive';
    final newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';

    _firestore
        .collection('users')
        .doc(user.id)
        .update({'status': newStatus})
        .then((_) {
          _loadUsers(); // Reload users to reflect the change
        })
        .catchError((e) {
          print("Error updating status: $e");
        });
  }

  void _showUserDetails(DocumentSnapshot user) {
    final name =
        user.data().toString().contains('name') ? user['name'] : 'Unnamed';
    final role =
        user.data().toString().contains('role')
            ? user['role']
            : 'Not specified';
    final status =
        user.data().toString().contains('status') ? user['status'] : 'Unknown';
    final lastLogin =
        user.data().toString().contains('lastLogin')
            ? user['lastLogin']
            : 'No login data';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(name),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Role: $role'),
              Text('Last Login: $lastLogin'),
              Text('Status: $status'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Usage Page',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => _filterUsers(),
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  filteredUsers.isEmpty
                      ? const Center(child: Text("No users found."))
                      : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final name =
                              user.data().toString().contains('name')
                                  ? user['name']
                                  : 'Unnamed';
                          final status =
                              user.data().toString().contains('status')
                                  ? user['status']
                                  : 'Unknown';

                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.teal,
                              ),
                              title: Text(name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color:
                                          status == 'Active'
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.toggle_on,
                                      color: Colors.teal,
                                    ),
                                    onPressed: () => _toggleStatus(index),
                                  ),
                                ],
                              ),
                              onTap: () => _showUserDetails(user),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
