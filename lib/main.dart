import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/company_signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/site_album_screen.dart';
import 'screens/create_site_screen.dart';
import 'screens/task_details_screen.dart';
import 'screens/invite_team_screen.dart';
import 'screens/company_details_screen.dart';
import 'models/task_model.dart';
import 'services/session_manager.dart';
import 'providers/theme_provider.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
            title: 'PMC',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/company-signup': (context) => const CompanySignupScreen(),
              '/home': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments
                        as Map<String, dynamic>?;
                return HomeScreen(arguments: args);
              },
              '/profile': (context) => const UserProfileScreen(),
              '/permissions': (context) => const PermissionScreen(),
              '/site-albums': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
                return SiteAlbumScreen(
                  siteId: args['siteId'],
                  siteName: args['siteName'],
                );
              },
              '/create-site': (context) => const CreateSiteScreen(),
              '/task-details': (context) => TaskDetailsScreen(
                task: ModalRoute.of(context)!.settings.arguments as TaskModel,
              ),
              '/invite-team': (context) => const InviteTeamScreen(),
              '/company-details': (context) => const CompanyDetailsScreen(),
            },
          );
        },
      ),
    );
  }
}
