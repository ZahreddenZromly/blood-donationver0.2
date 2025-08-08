import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DonationConfirmationScreen extends StatelessWidget {
  const DonationConfirmationScreen({super.key});

  Future<void> submitDonationRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final donationRequest = {
      'userId': user.uid,
      'status': 'Pending',
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('donations')
        .add(donationRequest);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("تم تأكيد الطلب"),
        content: const Text(
            "شكرا لك . طلب التبرع تم بنجاح\n الرجاء انتظار الرد"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
            child: const Text("نعم"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text("تأكيد الطلب"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/heartanimation.json',
                  height: 150,
                  repeat: true,
                  reverse: false,
                  animate: true,
                ),
                const SizedBox(height: 20),
                const Text(
                  "انت قريب !!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "بياناتك في أمان.\nاظغط علي الزر للتأكيد.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      "تأكيد الطلب",
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => submitDonationRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
