import 'package:drawly/features/auth/auth_page.dart';
import 'package:drawly_design_system/drawly_design_system.dart';
import 'package:flutter/material.dart';

class DrawlyApp extends StatelessWidget {
  const DrawlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drawly',
      theme: lightTheme,
      home: const AuthPage(),
    );
  }
}
