import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const AkiliApp());
}

class AkiliApp extends StatelessWidget {
  const AkiliApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akili App',
      debugShowCheckedModeBanner: false,
      theme: akilliTheme,
      home: const LoginScreen(),
    );
  }
}
