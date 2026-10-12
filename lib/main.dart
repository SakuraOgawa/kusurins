import 'package:kusurins/firebase_options.dart';
import 'package:kusurins/screens/register_screen.dart';
import 'package:kusurins/screens/login_screen.dart';
import 'package:kusurins/screens/user_home_screen.dart';
import 'package:kusurins/screens/admin_home_screen.dart';
import 'package:kusurins/screens/verifi_email.dart';
import 'package:kusurins/utils/notification_service.dart';
import 'package:kusurins/utils/shared_prefs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SharedPrefs.setPrefsInstance(); // ← 一回でOK
  print(Firebase.app().options.projectId);
  print(Firebase.app().options.apiKey);
  print(Firebase.app().options.appId);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '服薬管理アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: '/register',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/verifyEmail': (_) => const VerifyEmailScreen(),
        '/register': (_) => const RegisterScreen(),

        // ★ 必須引数 userName を“生成時に”渡す（const は付けない）
        '/userHome': (_) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            return const LoginScreen();
          }
          return UserHomeScreen(uid: user.uid);
        },

        '/adminHome': (_) => const AdminHomeScreen(),
      },
    );
  }
}
