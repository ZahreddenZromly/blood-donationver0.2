import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationAndNotifyPage extends StatefulWidget {
  const LocationAndNotifyPage({Key? key}) : super(key: key);

  @override
  State<LocationAndNotifyPage> createState() => _LocationAndNotifyPageState();
}

class _LocationAndNotifyPageState extends State<LocationAndNotifyPage> {
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print("Location error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل الحصول علي الموقع.")),
      );
    }
  }

  Future<void> _sendNotificationsToMatchingUsers() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("انت ليس مسجل ")),
        );
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final bloodType = userDoc.data()?['bloodType'];
      final userName = userDoc.data()?['name'] ?? 'Someone';
      final city = userDoc.data()?['city'] ?? 'your location';

      if (bloodType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فصيلة الدم ليسة معدة")),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("الموقع غير متاح")),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Get all users with matching blood type
      final matchingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('bloodType', isEqualTo: bloodType)
          .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
          .get();

      // Create notification for each matching user
      for (var userDoc in matchingUsers.docs) {
        final userId = userDoc.id;

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId, // The recipient's user ID
          'senderId': currentUser.uid, // Your user ID
          'senderName': userName,
          'senderLocation': {
            'lat': _currentPosition!.latitude,
            'lng': _currentPosition!.longitude,
          },
          'title': 'Urgent Blood Needed',
          'message': '$userName in $city needs blood type $bloodType',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'blood_request_location',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("تم ارسال اشعار $bloodType")),
      );
    } catch (e) {
      print("Error sending notifications: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("فشل الارسال")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("موقعك الحالي"),
        backgroundColor: Colors.redAccent,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 80.0,
                      height: 80.0,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.notifications_active),
              label: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text("ارسال اشعار الي نفس فصيلة الدم"),
              onPressed: _isLoading ? null : _sendNotificationsToMatchingUsers,
            ),
          ),
        ],
      ),
    );
  }
}