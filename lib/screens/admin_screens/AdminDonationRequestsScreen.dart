import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDonationRequestsScreen extends StatelessWidget {
  const AdminDonationRequestsScreen({super.key});

  Future<String> _getUserName(String userId) async {
    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc['name'] ?? 'Unknown' : 'Unknown';
  }

  void _cancelRequestWithReason(
      String docId,
      String userId,
      BuildContext context,
      ) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("الغاء الطلب"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: "سبب الإلغاء",
            hintText: "ادخل السبب",
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("الغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              // 1. Update the request with status and explanation
              await FirebaseFirestore.instance
                  .collection('donations')
                  .doc(docId)
                  .update({'status': 'Canceled', 'explanation': reason});

              // 2. Create a notification for the user
              await FirebaseFirestore.instance.collection('notifications').add({
                'userId': userId,
                'title': 'Donation Request Cancelled',
                'message': 'Your donation request was cancelled because: $reason',
                'timestamp': Timestamp.now(),
                'read': false,
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم الغاء الطلب واشعار المستخدم'),
                ),
              );
            },
            child: const Text("التأكيد"),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(String docId, String userId, BuildContext context) async {
    try {
      // 1. Update the request status to Approved
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(docId)
          .update({'status': 'Approved'});

      // 2. Create a notification for the user
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Donation Request Approved',
        'message': 'Your donation request has been approved! The center will contact you soon.',
        'timestamp': Timestamp.now(),
        'read': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تأكيد الطلب وإشعار المستخدم'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving request: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            "طلبات التبرع",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
        ),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('لايوجد طلبات الي الان'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return FutureBuilder<String>(
                future: _getUserName(data['userId']),
                builder: (context, userSnapshot) {
                  final userName = userSnapshot.data ?? 'Loading...';

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(userName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Status: ${data['status']}"),
                          Text(
                            "Date: ${data['timestamp']?.toDate()?.toString().split('.')[0] ?? 'Unknown'}",
                          ),
                        ],
                      ),
                      trailing: data['status'] == 'Pending'
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                            onPressed: () => _approveRequest(
                              doc.id,
                              data['userId'],
                              context,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                            ),
                            onPressed: () => _cancelRequestWithReason(
                              doc.id,
                              data['userId'],
                              context,
                            ),
                          ),
                        ],
                      )
                          : Text(
                        data['status'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}