import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../services/auth_service.dart';
import '../services/permission_service.dart';
import '../services/session_manager.dart';
import 'signup_next_step_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // Check authentication status and navigate accordingly
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Initialize auth service
    await AuthService.init();

    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Check if permission screen should be shown
      final shouldShowPermission = await PermissionService.shouldShowPermissionScreen();
      
      if (shouldShowPermission) {



        Navigator.of(context).pushReplacementNamed('/permissions');
      } else {
        // Skip permission screen and go directly to welcome/home
        if (AuthService.isLoggedIn() && SessionManager.isSessionValid()) {
          // Check if user has a company
          final currentUser = AuthService.currentUser;
          final hasCompany = currentUser?.company != null || 
                            (currentUser?.allowedCompanies != null && 
                             currentUser!.allowedCompanies!.isNotEmpty);
          
          if (hasCompany) {
            // User has a company, navigate to home
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            // User has no company, navigate to signup next step
            if (currentUser != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => SignupNextStepScreen(
                    userData: {
                      'id': currentUser.id,
                      'first_name': currentUser.firstName,
                      'last_name': currentUser.lastName,
                      'email': currentUser.email,
                      'mobile': currentUser.mobile,
                    },
                  ),
                ),
              );
            } else {
              // Fallback to welcome if user data is not available
              Navigator.of(context).pushReplacementNamed('/welcome');
            }
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/welcome');
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:  BoxDecoration(
         color: AppColors.surfaceColor
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 220,
                      tablet: 240,
                      desktop: 300,
                    ),
                    height: ResponsiveUtils.responsiveFontSize(
                      context,
                      mobile: 120,
                      tablet: 150,
                      desktop: 180,
                    ),

                    child: Image.asset(
                      'assets/images/pmc.png',
                      fit: BoxFit.contain,

                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
