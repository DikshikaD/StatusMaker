import 'dart:async';

import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/onboarding/presentation/language_dialog.dart';
import 'package:status_maker/features/onboarding/presentation/onboarding_screen.dart';

/// Clean, simple branded splash — built only from the app's primary colour.
/// After a short animated intro it presents the language picker, then opens
/// the onboarding in the chosen language.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _fade;
  late final Animation<double> _textFade;
  bool _navigated = false;
  Timer? _promptTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.95, curve: Curves.easeOut),
    );

    _controller.forward();
    _promptTimer =
        Timer(const Duration(milliseconds: 1900), _promptLanguage);
  }

  void _promptLanguage() {
    if (!mounted || _navigated) return;
    _navigated = true;
    showLanguagePicker(
      context,
      onContinue: () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          FadeSlidePageRoute(page: const OnboardingScreen()),
        );
      },
    );
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _logoScale,
                child: _logoMark(),
              ),
            ),
            SizedBox(height: 26.h),
            FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  Text(
                    S.t('app_name'),
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    S.t('splash_tagline'),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            FadeTransition(
              opacity: _textFade,
              child: SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2.r,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoMark() {
    return Container(
      width: 104.w,
      height: 104.w,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.accentGradient,
        ),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 30.r,
            offset: Offset(0, 12.h),
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: 48.w),
    );
  }
}
