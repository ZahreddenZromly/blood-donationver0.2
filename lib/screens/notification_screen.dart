import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("No user logged in"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("الاشعارات"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'جعل الكل كمقروئة',
            onPressed: () async {
              final snapshots = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .where('read', isEqualTo: false)
                  .get();

              final batch = FirebaseFirestore.instance.batch();
              for (var doc in snapshots.docs) {
                batch.update(doc.reference, {'read': true});
              }

              await batch.commit();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('جميع الاشعارات مقروئة')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لاتوجد اشعارات حاليا'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'No title';
              final message = data['message'] ?? 'No message';
              final read = data['read'] ?? false;
              final timestamp = data['timestamp'] is Timestamp
                  ? (data['timestamp'] as Timestamp).toDate()
                  : null;

              return Dismissible(
                key: Key(notification.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("حذف الاشعار"),
                      content: const Text("هل انت متأكد من حذف الاشعار؟"),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("الغاء")),
                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("حذف")),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notification.id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم حذف الاشعار")),
                  );
                },
                child: InkWell(
                  onTap: () async {
                    if (!read) {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notification.id)
                          .update({'read': true});
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        isThreeLine: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: read ? FontWeight.normal : FontWeight.bold,
                                  color: Colors.redAccent,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (!read)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'New',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            if (timestamp != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${timestamp.toLocal().toString().substring(0, 16)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            const SizedBox(height: 8),
                            if (data['senderLocation'] != null)
                              ElevatedButton.icon(
                                onPressed: () {
                                  final location = data['senderLocation'];
                                  if (location['lat'] != null && location['lng'] != null) {
                                    Navigator.of(context).pushNamed(
                                      '/map',
                                      arguments: {
                                        'lat': location['lat'],
                                        'lng': location['lng'],
                                      },
                                    );
                                  }
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('العرض في الخريطة'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(
                          read ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: read ? Colors.green : Colors.grey,
                        ),
                      ),
                      const Divider(color: Colors.grey, thickness: 1.0, height: 0),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}