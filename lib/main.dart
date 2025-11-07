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
import 'models/task_model.dart';
import 'services/session_manager.dart';
import 'services/force_update_manager.dart';
import 'providers/theme_provider.dart';
import 'widgets/dismiss_keyboard.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize session manager
  SessionManager.instance;




  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://dc5dc3b5a35cf344650ff54e6905fb85@o4510187629445120.ingest.us.sentry.io/4510187631869952';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      // options.replay.sessionSampleRate = 1.0;
      // options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: const MyApp())),
  );


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
            builder: (context, child) {
              return Theme(
                data: themeProvider.themeMode == ThemeMode.dark 
                    ? AppTheme.darkTheme 
                    : AppTheme.lightTheme,
                child: ForceUpdateWrapper(child: child!),
              );
            },
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/company-signup': (context) => const CompanySignupScreen(),
              '/home': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                return HomeScreen(arguments: args);
              },
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

class ForceUpdateWrapper extends StatefulWidget {
  final Widget child;

  const ForceUpdateWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<ForceUpdateWrapper> createState() => _ForceUpdateWrapperState();
}

class _ForceUpdateWrapperState extends State<ForceUpdateWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
    
    // Check for updates after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ForceUpdateManager.checkForUpdates(context);
    });
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Dismiss keyboard when app goes to background or becomes inactive
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      dismissAllFocus(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: widget.child,
    );
  }
}
