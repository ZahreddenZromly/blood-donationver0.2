import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DonorPage extends StatefulWidget {
  const DonorPage({super.key});

  @override
  _DonorPageState createState() => _DonorPageState();
}

class _DonorPageState extends State<DonorPage> {
  final _bloodTypeController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // To send a new donation request
  Future<void> _sendDonationRequest() async {
    try {
      final requestData = {
        'donorName': 'John Doe',  // You can replace this with the logged-in donor's name
        'bloodType': _bloodTypeController.text,
        'requestStatus': 'Pending',
        'requestDate': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'explanation': '',
      };

      await _firestore.collection('donation_requests').add(requestData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ارسال تبرع الدم بنجاح!')),
      );
    } catch (e) {
      print('Error sending request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل ارسال الطلب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلب التبرع بالدم'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _bloodTypeController,
              decoration: const InputDecoration(
                labelText: 'فصيلة الدم',
                hintText: 'ادخل فصيلة دمك (e.g., O+, A-)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendDonationRequest,
              child: const Text('ارسال طلب التبرع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
