import 'package:drawly/drawly_app.dart';
import 'package:drawly/features/auth/auth_page.dart';
import 'package:drawly/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DrawlyApp(home: AuthPage()));
}
