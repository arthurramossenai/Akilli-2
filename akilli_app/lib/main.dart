import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/main_tabs_screen.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final supabaseService = SupabaseService();
  await supabaseService.initLoggedUser();

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
      home: SupabaseService().usuarioLogado != null
          ? const MainTabsScreen()
          : const AuthScreen(),
    );
  }
}
