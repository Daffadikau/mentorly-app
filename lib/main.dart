import 'package:flutter/material.dart';
import 'common/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'common/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message received: ${message.notification?.title}');
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    print('🚀 Starting Mentorly App...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background message handler set');

    await initializeDateFormatting('id_ID', null);
    print('✅ Date formatting initialized');

    runApp(const MentorlyApp());
    print('✅ App running');
  } catch (e, stackTrace) {
    print('❌ Error in main: $e');
    print('❌ Stack trace: $stackTrace');

    // Show error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class MentorlyApp extends StatelessWidget {
  const MentorlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentorly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const SplashScreen(),
      navigatorKey: GlobalKey<NavigatorState>(),
      builder: (context, child) {
        // Initialize notification service when app starts
        NotificationService.initialize(context);
        return child!;
      },
    );
  }
}
