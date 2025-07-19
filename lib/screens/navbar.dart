import 'package:blood_donation/screens/admin_screens/user_usage_page.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'admin_screens/AdminDonationRequestsScreen.dart';
import 'admin_screens/admin_dashboard.dart';
import 'admin_screens/admin_news_post_screen.dart';
import 'admin_screens/admin_page.dart';


class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  // This will handle navigation to respective pages
  static final List<Widget> _widgetOptions = <Widget>[

    const AdminMainDashboardPage(),  // Dashboard page (SuperAdminDashboard)
    const UserUsagePage(),
    const AdminDonationRequestsScreen(),
    const AdminPage(),
    const AdminNewsPostScreen(),
       // Users page (Active/Inactive users)

    // Add more pages here if necessary
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: GNav(
                rippleColor: Colors.grey[300]!,
                hoverColor: Colors.grey[100]!,
                gap: 8,
                activeColor: Colors.black,
                iconSize: 35,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.grey[100]!,
                color: Colors.black,
                tabs: const [
                  GButton(
                    icon: Icons.dashboard,
                    text: 'Dashboard',
                  ),
                  GButton(
                    icon: Icons.people,
                    text: 'Users',
                  ),
                  GButton(
                    icon: Icons.schedule_outlined,
                    text: 'Requests',
                  ),
                  GButton(
                    icon: Icons.admin_panel_settings,
                    text: 'Settings',
                  ),
                  GButton(
                    icon: Icons.newspaper,
                    text: 'News',
                  ),
                ],
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),

    );
  }
}
