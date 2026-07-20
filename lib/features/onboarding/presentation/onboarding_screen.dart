import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:status_maker/core/theme/app_colors.dart';
import 'package:status_maker/core/constants/app_dimensions.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/home/presentation/main_layout.dart';
import 'package:status_maker/core/utils/page_transitions.dart';
import 'package:status_maker/core/utils/responsive.dart';

/// A polished, animated 3-step introduction that explains what the app does,
/// then asks the user to pick a language (saved to preferences) before entering.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _floatController;
  int _page = 0;

  static const int _stepCount = 3;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<_OnbStep> get _steps => [
        _OnbStep(
          title: S.t('onb1_title'),
          desc: S.t('onb1_desc'),
          accent: AppColors.accent,
          gradient: AppColors.accentGradient,
          builder: _illustrationTemplates,
        ),
        _OnbStep(
          title: S.t('onb2_title'),
          desc: S.t('onb2_desc'),
          accent: AppColors.accent,
          gradient: AppColors.accentGradient,
          builder: _illustrationPersonalize,
        ),
        _OnbStep(
          title: S.t('onb3_title'),
          desc: S.t('onb3_desc'),
          accent: AppColors.accent,
          gradient: AppColors.accentGradient,
          builder: _illustrationShare,
        ),
      ];

  void _onPrimaryPressed() {
    if (_page < _stepCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToApp();
    }
  }

  void _goToApp() {
    Navigator.of(context).pushReplacement(
      FadeSlidePageRoute(page: const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final isLast = _page == _stepCount - 1;
    final accent = steps[_page].accent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: brand + skip
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 12.w, 0),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: accent, size: 20.w),
                  SizedBox(width: 8.w),
                  Text(
                    S.t('app_name'),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _goToApp,
                    child: Text(
                      S.t('skip'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _stepCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return AnimatedBuilder(
                    animation: Listenable.merge([_pageController, _floatController]),
                    builder: (context, _) {
                      // Parallax: scale/fade based on how centred this page is.
                      double page = _stepCount > 0 ? index.toDouble() : 0;
                      if (_pageController.hasClients &&
                          _pageController.position.haveDimensions) {
                        page = _pageController.page ?? index.toDouble();
                      }
                      final delta = (page - index).abs().clamp(0.0, 1.0);
                      final scale = 1 - delta * 0.14;
                      final bob = math.sin(_floatController.value * math.pi * 2);

                      return Opacity(
                        opacity: (1 - delta).clamp(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Transform.translate(
                                offset: Offset(0, bob * 8.h),
                                child: Transform.scale(
                                  scale: scale,
                                  child: SizedBox(
                                    height: 320.h,
                                    child: Center(child: step.builder(bob)),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Transform.translate(
                                offset: Offset(0, (1 - (1 - delta)) * 24.h),
                                child: Column(
                                  children: [
                                    Text(
                                      step.title,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(fontSize: 28.sp, height: 1.15),
                                    ),
                                    SizedBox(height: 14.h),
                                    Text(
                                      step.desc,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.5,
                                            fontSize: 15.sp,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stepCount, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: active ? 26.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: active ? accent : AppColors.border,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                );
              }),
            ),
            SizedBox(height: 24.h),

            // Primary action
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _onPrimaryPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? S.t('get_started') : S.t('next'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        isLast ? Icons.check_rounded : Icons.arrow_forward,
                        size: 18.w,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // ---- Illustrations ---------------------------------------------------------

  /// Step 1 — a fanned stack of template cards.
  Widget _illustrationTemplates(double bob) {
    Widget card(List<Color> g, double angle, double dx, double dy) {
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 150.w,
            height: 210.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: g,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(0.7, Colors.white.withValues(alpha: 0.9)),
                SizedBox(height: 8.h),
                _bar(0.5, Colors.white.withValues(alpha: 0.7)),
                SizedBox(height: 8.h),
                _bar(0.85, Colors.white.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        card(const [AppColors.accentLight, AppColors.accent], -0.20, -46.w, 14.h + bob * 6.h),
        card(const [AppColors.accent, AppColors.accentLight], 0.20, 46.w, 14.h - bob * 6.h),
        card(AppColors.accentGradient, 0, 0, -bob * 4.h),
      ],
    );
  }

  /// Step 2 — a phone with the editor and floating edit chips.
  Widget _illustrationPersonalize(double bob) {
    return SizedBox(
      width: 260.w,
      height: 320.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Phone frame
          Container(
            width: 190.w,
            height: 300.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: AppColors.border, width: 6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 22.r,
                  offset: Offset(0, 12.h),
                ),
              ],
            ),
            padding: EdgeInsets.all(10.w),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.accentGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Center(
                      child: Icon(Icons.person,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 60.w),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                _bar(0.8, AppColors.border),
                SizedBox(height: 6.h),
                _bar(0.55, AppColors.border),
              ],
            ),
          ),
          // Floating chips
          Positioned(
            top: 10.h + bob * 6.h,
            left: 0,
            child: _chip(Icons.text_fields, 'Text', AppColors.accent),
          ),
          Positioned(
            bottom: 24.h - bob * 6.h,
            left: 6.w,
            child: _chip(Icons.palette_outlined, 'Color', AppColors.accent),
          ),
          Positioned(
            top: 60.h - bob * 5.h,
            right: 0,
            child: _chip(Icons.format_size, 'Aa', AppColors.accent),
          ),
        ],
      ),
    );
  }

  /// Step 3 — a saved status with floating share bubbles.
  Widget _illustrationShare(double bob) {
    return SizedBox(
      width: 260.w,
      height: 320.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 180.w,
            height: 250.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 26.r,
                  offset: Offset(0, 14.h),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 84.w,
                height: 84.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded,
                    color: AppColors.accent, size: 48.w),
              ),
            ),
          ),
          Positioned(
            top: 4.h + bob * 7.h,
            right: 8.w,
            child: _bubble(Icons.download_rounded, AppColors.accent),
          ),
          Positioned(
            bottom: 30.h - bob * 7.h,
            right: 24.w,
            child: _bubble(Icons.chat_rounded, AppColors.accent),
          ),
          Positioned(
            bottom: 12.h + bob * 5.h,
            left: 10.w,
            child: _bubble(Icons.ios_share, AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _bar(double widthFactor, Color color) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 8.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16.w),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(IconData icon, Color color) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 24.w),
    );
  }
}

/// One onboarding step's content.
class _OnbStep {
  final String title;
  final String desc;
  final Color accent;
  final List<Color> gradient;
  final Widget Function(double bob) builder;

  const _OnbStep({
    required this.title,
    required this.desc,
    required this.accent,
    required this.gradient,
    required this.builder,
  });
}
