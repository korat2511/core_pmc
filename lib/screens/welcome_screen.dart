import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/responsive_utils.dart';
import '../core/theme/app_typography.dart';
import '../widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Logo
              SizedBox(
                width: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 200,
                  tablet: 220,
                  desktop: 280,
                ),
                height: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 110,
                  tablet: 130,
                  desktop: 160,
                ),
                child: Image.asset(
                  'assets/images/pmc_transparent_1.png',
                  fit: BoxFit.contain,
                ),
              ),
              
              SizedBox(height: screenHeight * 0.04),
              
              // Welcome Text
              Text(
                'Welcome to PMC',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: screenHeight * 0.01),
              
              // Subtitle
              Text(
                'Project Management Made Simple',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: ResponsiveUtils.responsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(flex: 3),
              
              // Login Button
              CustomButton(
                text: 'Login',
                onPressed: () {
                  Navigator.of(context).pushNamed('/login');
                },
                backgroundColor: AppColors.primaryColor,
                textColor: Colors.white,
                height: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 50,
                  tablet: 55,
                  desktop: 60,
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // Signup Button
              CustomButton(
                text: 'Sign Up',
                onPressed: () {
                  Navigator.of(context).pushNamed('/signup');
                },
                buttonType: ButtonType.outline,
                backgroundColor: Colors.transparent,
                textColor: AppColors.primaryColor,
                height: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 50,
                  tablet: 55,
                  desktop: 60,
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // Signup as Company Button
              CustomButton(
                text: 'Sign Up as a Company',
                onPressed: () {
                  Navigator.of(context).pushNamed('/company-signup');
                },
                buttonType: ButtonType.outline,
                backgroundColor: Colors.transparent,
                textColor: AppColors.secondaryColor,
                height: ResponsiveUtils.responsiveFontSize(
                  context,
                  mobile: 50,
                  tablet: 55,
                  desktop: 60,
                ),
              ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

