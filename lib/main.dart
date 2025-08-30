import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/site_album_screen.dart';
import 'screens/create_site_screen.dart';
import 'screens/task_details_screen.dart';
import 'models/task_model.dart';
import 'services/session_manager.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize session manager
  SessionManager.instance;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Core PMC',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              return Theme(
                data: themeProvider.themeMode == ThemeMode.dark 
                    ? AppTheme.darkTheme 
                    : AppTheme.lightTheme,
                child: child!,
              );
            },
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const UserProfileScreen(),
              '/permissions': (context) => const PermissionScreen(),
              '/site-albums': (context) {
                final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                return SiteAlbumScreen(
                  siteId: args['siteId'],
                  siteName: args['siteName'],
                );
              },
              '/create-site': (context) => const CreateSiteScreen(),
              '/task-details': (context) => TaskDetailsScreen(
                task: ModalRoute.of(context)!.settings.arguments as TaskModel,
              ),
            },
          );
        },
      ),
    );
  }
}
