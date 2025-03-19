import 'package:drawly/drawly_app.dart';
import 'package:drawly/features/auth/auth_page.dart';
import 'package:flutter/material.dart';

class App {
  static bool isDebugMode = true;
}

void main() {
  runApp(const DrawlyApp(home: AuthPage()));
}
