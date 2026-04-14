import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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
