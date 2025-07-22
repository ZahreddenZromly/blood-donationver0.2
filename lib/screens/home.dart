import 'package:blood_donation/screens/survey.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(context),
    );
  }

  Widget content(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                children: [
                  Image.asset("assets/blood.png", height: 160),
                  const SizedBox(height: 10),
                  const Text(
                    "مرحبا بك",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 120),

          // Action Buttons
          LoginButton("تبرع الدم", () {
            Navigator.of(context).pushNamed('/eligibility_screen');
          }),
          const SizedBox(height: 40),

          LoginButton("طلب دم", () {
            Navigator.of(context).pushNamed('/survey');
          }),
          const SizedBox(height: 40),
/*
          LoginButton("Check Donation Status", () {
            Navigator.of(context).pushNamed('/donation_status');
          }),
          const SizedBox(height: 30),

 */

          /*
          // Learn More
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Row(
              children: [
                const Text(
                  "Learn More",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/survey');
                  },
                  child: const Text(
                    "Skip Now",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

           */

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
