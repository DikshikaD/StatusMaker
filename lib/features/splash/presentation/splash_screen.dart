import 'package:flutter/material.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/features/onboarding/presentation/language_dialog.dart';
import 'package:status_maker/features/onboarding/presentation/onboarding_screen.dart';

/// Blank hand-off screen: no logo, no animation, so there is nothing to wait
/// for. White in light mode, black in dark mode — matching the native launch
/// window — then the language picker opens straight away and the onboarding
/// follows in the chosen language.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptLanguage());
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
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(backgroundColor: dark ? Colors.black : Colors.white);
  }
}
