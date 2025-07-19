import 'package:blood_donation/login_system/auth_gate.dart';
import 'package:blood_donation/screens/booking.dart';
import 'package:blood_donation/screens/donations_screens/donation_confirm.dart';
import 'package:blood_donation/screens/donations_screens/donation_status_screen.dart';
import 'package:blood_donation/screens/donations_screens/eligibility_screen.dart';
import 'package:blood_donation/screens/home.dart';
import 'package:blood_donation/screens/map_page.dart';
import 'package:blood_donation/screens/news_screen.dart';
import 'package:blood_donation/screens/notification_screen.dart';
import 'package:blood_donation/screens/admin_screens/admin_main.dart';
import 'package:blood_donation/screens/user_info.dart';
import 'package:blood_donation/screens/splash.dart';
import 'package:blood_donation/screens/survey.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase/firebase_options.dart';
import 'login_system/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Initialize the local notifications plugin.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Background message handler for Firebase Messaging.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Widget _redirectBasedOnRole(User user) {
    if (user.email == 'superadmin@gmail.com') {
      return const SuperAdminDashboard();
    } else {
      return const DonationStatusScreen(); // or your user home screen
    }
  }


  // Handle background messages.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set up local notifications.
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap here.
      // For example, you could navigate to the notification screen:
      // Navigator.of(context).pushNamed('/notifications');
    },
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    setupFCM();
  }

  void setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (for iOS; Android auto-grants the permission if declared in manifest).
    await messaging.requestPermission();

    // Listen to foreground messages.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If a notification is received while the app is in the foreground, show a local notification.
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Channel',
              channelDescription: 'This channel is used for default notifications.',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/splash': (context) => const Splash(),
        '/user_info': (context) => const ProfileFormPage(),
        '/home': (context) => const Home(),
        '/notifications': (context) => const NotificationScreen(),
        '/eligibility_screen': (context) =>  DonationEligibilityScreen(),
        '/donation_confirm': (context) => const DonationConfirmationScreen(),
        '/donation_status': (context) => const DonationStatusScreen(),
        '/survey': (context) => const Survey(),
        '/booking': (context) => const Booking(),
        '/news': (context) => const NewsScreen(),
        '/super_admin_dashboard': (context) => const SuperAdminDashboard(),
        '/map': (context) => const MapPage(),
      },
    );
  }
}
