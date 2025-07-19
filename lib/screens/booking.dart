import 'package:blood_donation/screens/phone_list_screen.dart';
import 'package:flutter/material.dart';

import 'MapScreen.dart';
import 'location_notify.dart'; // Update the path based on your project

class Booking extends StatefulWidget {
  const Booking({Key? key}) : super(key: key);

  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(),
    );
  }

  Widget content() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Image.asset("assets/blood-donation.png"),
              ),
              const SizedBox(height: 25),
              const Text(
                "       Blood Bank\nLocation Near You",
                style: TextStyle(fontSize: 25),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _openLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      height: 100,
                      width: 160,
                      child: const Icon(Icons.gps_fixed, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 25),
                  GestureDetector(
                    onTap: _openMap, // This now opens the internal MapScreen
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      height: 100,
                      width: 160,
                      child: const Icon(Icons.map, size: 50, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _openPhoneList,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: 100,
                  width: 160,
                  child: const Icon(Icons.phone, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                "Can I Give Blood?",
                style: TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
              const SizedBox(height: 10),
              const Text(
                "Share On Social Media",
                style: TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
            ],
          ),
        ),
        Positioned(
          top: 30,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  void _openPhoneList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PhoneListScreen()),
    );
  }

  void _openMap() {
    // This opens the internal MapScreen now
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  void _openLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationAndNotifyPage()),
    );
  }
}
