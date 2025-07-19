import 'package:blood_donation/login_system/login_or_register.dart';
import 'package:blood_donation/screens/navbar.dart';
import 'package:blood_donation/screens/user_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/user_nav_bar.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> hasProfileData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return false;
      final data = doc.data()!;
      return data.containsKey('name') && data.containsKey('age') && data.containsKey('bloodType');
    } catch (e) {
      print('❌ Error checking profile data: $e');
      return false;
    }
  }

  Future<void> saveFCMToken(String userId) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final existingToken = userDoc.data()?['fcmToken'];

      if (existingToken != fcmToken) {
        await userRef.update({'fcmToken': fcmToken});
        print('✅ FCM token updated in Firestore.');
      } else {
        print('ℹ️ FCM token already up to date.');
      }
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginOrRegister();
          }

          final user = snapshot.data!;

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const LoginOrRegister();
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

              if (userData == null) {
                return const LoginOrRegister();
              }

              // 🚫 Check if the account is deactivated
              if (userData['isActive'] == false) {
                FirebaseAuth.instance.signOut();
                return const DeactivatedAccountScreen();
              }

              // ✅ Save FCM token
              saveFCMToken(user.uid);

              final role = userData['role'];
              final isSuperAdmin = user.email == 'superadmin@gmail.com';

              if (role == 'admin' || isSuperAdmin) {
                return const NavBar();
              }

              return FutureBuilder<bool>(
                future: hasProfileData(user.uid),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (profileSnapshot.hasData && profileSnapshot.data == true) {
                    return const UserNavBar();
                  } else {
                    return const ProfileFormPage();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class DeactivatedAccountScreen extends StatelessWidget {
  const DeactivatedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Your account is deactivated.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Please contact the super admin for support.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginOrRegister()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Back to Login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
