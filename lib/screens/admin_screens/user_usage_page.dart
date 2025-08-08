import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserUsagePage extends StatefulWidget {
  const UserUsagePage({super.key});

  @override
  State<UserUsagePage> createState() => _UserUsagePageState();
}

class _UserUsagePageState extends State<UserUsagePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(DocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      final data = doc.data() ?? {};
      // Read current status: prefer bool isActive, fallback to status string
      final bool isActiveNow =
          (data['isActive'] ?? (data['status'] == 'Active')) == true;

      await _firestore.collection('users').doc(doc.id).update({
        'isActive': !isActiveNow,
      });

      // If you ALSO want to keep the old string field in sync, uncomment:
      // await _firestore.collection('users').doc(doc.id).update({
      //   'isActive': !isActiveNow,
      //   'status': !isActiveNow ? 'Active' : 'Inactive',
      // });
    } catch (e) {
      debugPrint("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user status')),
      );
    }
  }

  void _showUserDetails(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final name = (data['name'] ?? 'Unnamed').toString();
    final role = (data['role'] ?? 'Not specified').toString();
    final bool isActive =
        (data['isActive'] ?? (data['status'] == 'Active')) == true;
    final statusText = isActive ? 'Active' : 'Inactive';

    String lastLoginText = 'No login data';
    final lastLogin = data['lastLogin'];
    if (lastLogin is Timestamp) {
      lastLoginText = lastLogin.toDate().toString();
    } else if (lastLogin != null) {
      lastLoginText = lastLogin.toString();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Role: $role'),
            Text('Last Login: $lastLoginText'),
            Text('Status: $statusText'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'User Management',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
        ),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Users list
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading users'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Get and (optionally) sort locally by name to avoid Firestore index issues
                  final docs = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aName =
                      (a.data()['name'] ?? '').toString().toLowerCase();
                      final bName =
                      (b.data()['name'] ?? '').toString().toLowerCase();
                      return aName.compareTo(bName);
                    });

                  // Filter by search
                  final filtered = docs.where((d) {
                    final name =
                    (d.data()['name'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No users found'));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data();
                      final name = (data['name'] ?? 'Unnamed').toString();
                      final bool isActive =
                          (data['isActive'] ?? (data['status'] == 'Active')) ==
                              true;

                      return Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading:
                          const Icon(Icons.person, color: Colors.teal),
                          title: Text(name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                              ),
                              Switch(
                                value: isActive,
                                onChanged: (_) => _toggleStatus(doc),
                              ),
                            ],
                          ),
                          onTap: () => _showUserDetails(doc),
                        ),
                      );
                    },
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
