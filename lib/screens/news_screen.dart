import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اخر الاخبار'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('news')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final newsList = snapshot.data!.docs;
          if (newsList.isEmpty) return const Center(child: Text('لاتوجد اخبار'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final news = newsList[index];
              final newsId = news.id;
              final title = news['title'] ?? '';
              final description = news['description'] ?? '';
              final timestamp = news['timestamp'] as Timestamp;

              String? base64String = news.data().toString().contains('imageBase64') ? news['imageBase64'] : null;

              Uint8List? imageBytes;
              if (base64String != null && base64String.isNotEmpty) {
                try {
                  if (base64String.contains(',')) {
                    base64String = base64String.split(',').last;
                  }
                  imageBytes = base64Decode(base64String);
                } catch (e) {
                  print('Error decoding image: $e');
                  imageBytes = null;
                }
              }

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 6,
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageBytes != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.memory(
                          imageBytes,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          if (user != null)
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('news')
                                  .doc(newsId)
                                  .collection('reactions')
                                  .doc(user.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final hasReacted = snapshot.data?.exists ?? false;

                                return Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        hasReacted ? Icons.favorite : Icons.favorite_border,
                                        color: hasReacted ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () async {
                                        final reactionRef = FirebaseFirestore.instance
                                            .collection('news')
                                            .doc(newsId)
                                            .collection('reactions')
                                            .doc(user.uid);

                                        if (hasReacted) {
                                          await reactionRef.delete();
                                        } else {
                                          await reactionRef.set({
                                            'userId': user.uid,
                                            'timestamp': FieldValue.serverTimestamp(),
                                          });
                                        }
                                      },
                                    ),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('news')
                                          .doc(newsId)
                                          .collection('reactions')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) return const SizedBox.shrink();
                                        final count = snapshot.data!.docs.length;
                                        return Text(
                                          '$count',
                                          style: const TextStyle(fontSize: 16),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
