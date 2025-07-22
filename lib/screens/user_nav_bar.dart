import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import '../login_system/auth_service.dart';
import 'home.dart';
import 'news_screen.dart';
import 'notification_screen.dart';

class UserNavBar extends StatefulWidget {
  const UserNavBar({super.key});

  @override
  State<UserNavBar> createState() => _UserNavBarState();
}

class _UserNavBarState extends State<UserNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Home(),
    const NotificationScreen(),
    const NewsScreen(),
    Container(), // Placeholder for logout
  ];

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الخروج'),
        content: const Text('هل انت متأكد من الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('الغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // 🔐 Sign out via AuthService
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.SignOut();

              // Redirect to login screen
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onTabChange(int index) {
    if (index == 3) {
      _showLogoutDialog();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              gap: 8,
              activeColor: Colors.white,
              color: Colors.grey[800],
              tabBackgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              selectedIndex: _selectedIndex,
              onTabChange: _onTabChange,
              tabs: const [
                GButton(icon: Icons.home, text: 'الرئيسية'),
                GButton(icon: Icons.notifications, text: 'الاشعارات'),
                GButton(icon: Icons.newspaper, text: 'الاخبار'),
                GButton(icon: Icons.logout, text: 'تسجيل الخروج'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
