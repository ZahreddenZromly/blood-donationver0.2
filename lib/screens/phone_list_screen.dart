import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneListScreen extends StatefulWidget {
  const PhoneListScreen({Key? key}) : super(key: key);

  @override
  State<PhoneListScreen> createState() => _PhoneListScreenState();
}

class _PhoneListScreenState extends State<PhoneListScreen> {
  String? userBloodType;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    loadUserBloodType();
    setupNotifications();
  }

  Future<void> setupNotifications() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground: ${message.notification?.title}');
    });
  }

  Future<void> loadUserBloodType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final bloodType = doc.data()?['bloodType'];
      setState(() {
        userBloodType = bloodType;
      });
    }
  }

  Future<void> _callUser(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Future<void> sendBloodRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final bloodType = data?['bloodType'];
      final name = data?['name'] ?? 'Someone';
      final city = data?['city'] ?? 'Unknown';

      if (bloodType != null) {
        // Create blood request
        await FirebaseFirestore.instance.collection('requests').add({
          'userId': user.uid,
          'userName': name,
          'bloodType': bloodType,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Get all users with matching blood type
        final matchingUsers = await FirebaseFirestore.instance
            .collection('users')
            .where('bloodType', isEqualTo: bloodType)
            .where(FieldPath.documentId, isNotEqualTo: user.uid)
            .get();

        // Send notification to each matching user
        for (var userDoc in matchingUsers.docs) {
          final userId = userDoc.id;
          final userData = userDoc.data();
          final userName = userData['name'] ?? 'Donor';

          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': userId, // The recipient's user ID
            'senderId': user.uid, // Your user ID
            'senderName': name,
            'senderLocation': {
              'lat': data?['latitude'] ?? 0.0,
              'lng': data?['longitude'] ?? 0.0,
            },
            'title': 'Blood Request',
            'message': '$name in $city needs blood type $bloodType',
            'read': false,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'blood_request',
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent to donors with matching blood type')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userBloodType == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Donors"),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('bloodType', isEqualTo: userBloodType)
            .where(FieldPath.documentId, isNotEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading users"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No donors available"));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: sendBloodRequest,
                  child: const Text(
                    "Request Blood",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data = users[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: Text(
                          'Blood Type: ${data['bloodType'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'City: ${data['city'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.redAccent),
                          onPressed: () {
                            final phone = data['phone'];
                            if (phone != null) {
                              _callUser(phone);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}