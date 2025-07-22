
import 'package:flutter/material.dart';
import '../navbar.dart';  // Import the NavBar widget

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return NavBar();  // Use the NavBar widget to display the navigation bar
  }

  Widget content(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                height: 280,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 150,
                    color: Colors.white,
                  ),
                ),
              ),
              const Positioned(
                top: 40,
                left: 20,
                child: Text(
                  "واجهة المسؤول",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
/*
          // KPIs
          sectionTitle("KPIs"),
          const BloodTypeChart(),
          const SizedBox(height: 20),
          const DonationsByDayChart(),
          const SizedBox(height: 30),

          // Active Users
          sectionTitle("Active Users"),
          const ActiveUsersWidget(),
          const SizedBox(height: 30),

          // Pending Donations
          sectionTitle("Pending Donations"),
          const PendingDonationsList(),
          const SizedBox(height: 30),

          // Notifications
          sectionTitle("Send Notification"),
          const SendNotificationWidget(),

 */
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
