import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../widgets/custom_button.dart';
import 'company_signup_screen.dart';
import 'join_company_screen.dart';

class SignupNextStepScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const SignupNextStepScreen({
    super.key,
    required this.userData,
  });

  String get _userName {
    final first = (userData['first_name'] ?? '').toString().trim();
    final last = (userData['last_name'] ?? '').toString().trim();
    return [first, last].where((part) => part.isNotEmpty).join(' ').trim();
  }

  int? get _userId {
    final value = userData['id'];
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final name = _userName.isEmpty ? 'There' : _userName;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Complete Your Setup'),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi $name!',
                style: AppTypography.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account is ready. To start using Core PMC, create your company or join an existing one.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              _buildCard(
                context,
                icon: Icons.apartment,
                title: 'Create Company',
                description:
                    'Set up a new company workspace for your team and invite members.',
                buttonText: 'Create Company',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CompanySignupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildCard(
                context,
                icon: Icons.group_add,
                title: 'Join Existing Company',
                description:
                    'Already have a company code? Join your team to start collaborating.',
                buttonText: 'Join Company',
                onPressed: _userId == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JoinCompanyScreen(
                              userId: _userId!,
                            ),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false),
                  child: const Text('Skip for now, go to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback? onPressed,
  }) {
    return Container(
      padding: ResponsiveUtils.responsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primaryColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: buttonText,
            onPressed: onPressed,
            isEnabled: onPressed != null,
          ),
        ],
      ),
    );
  }
}

