import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DonationStatusScreen extends StatefulWidget {
  const DonationStatusScreen({super.key});

  @override
  State<DonationStatusScreen> createState() => _DonationStatusScreenState();
}

class _DonationStatusScreenState extends State<DonationStatusScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  DocumentSnapshot? latestDonation = null;  // Initialize to null
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLatestDonation();
  }

  Future<void> fetchLatestDonation() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('donations')  // Ensure this is the correct collection name
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    setState(() {
      latestDonation = snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
      isLoading = false;
    });
  }

  Future<void> cancelRequest() async {
    if (latestDonation != null) {
      // Show confirmation dialog before canceling
      bool? confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Cancellation'),
            content: const Text('Are you sure you want to cancel your donation request?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // User confirmed cancellation
                },
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // User canceled the action
                },
                child: const Text('No'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await FirebaseFirestore.instance
            .collection('donations')  // Ensure this is the correct collection name
            .doc(latestDonation!.id)
            .update({'status': 'cancelled'});

        // Refresh the UI
        await fetchLatestDonation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    // If no donation exists, show message
    if (latestDonation == null) {
      return const Scaffold(
        body: Center(child: Text("No donation request found.")),
      );
    }

    final status = latestDonation!['status'];

    return Scaffold(
      appBar: AppBar(title: const Text("Donation Status")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("Your request status: ${status.toString().toUpperCase()}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            if (status == 'waiting')
              ElevatedButton.icon(
                onPressed: cancelRequest,
                icon: const Icon(Icons.cancel),
                label: const Text("Cancel Request"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}