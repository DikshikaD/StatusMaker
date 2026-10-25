import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'package:status_maker/core/theme/theme_controller.dart';
import 'package:status_maker/core/utils/app_navigation.dart';
import 'package:status_maker/core/utils/first_run.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/notifications/push_service.dart';
import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/home/presentation/main_layout.dart';
import 'package:status_maker/features/splash/presentation/splash_screen.dart';
import 'package:status_maker/studio/shaders/studio_shaders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the user's saved language and theme before the first frame builds.
  // These are tiny, fast SharedPreferences reads.
  await S.init();
  await ThemeController.init();
  await FirstRun.init();
  runApp(const MyApp());

  // Connect to the backend and ensure a (anonymous) session — deliberately
  // NOT awaited. With no network, the SDK's session recovery can sit in a
  // token-refresh retry loop for as long as the connection is down, which
  // used to hold the first frame hostage. Every repository call waits on
  // ensureReady() itself (bounded by StatusRepository.readTimeout), so
  // nothing needs this to have finished before the UI appears. No-ops safely
  // until real credentials are added to SupabaseConfig.
  SupabaseService.init();

  // Register this device for push AFTER the first frame: it can show the
  // Android 13 permission dialog and talk to the network, neither of which
  // should sit in front of the splash screen. Never throws — see PushService.
  PushService.init();

  // Warm the template fonts AFTER the first frame is on screen, so font
  // fetching/decoding never blocks startup. google_fonts caches the result,
  // so by the time the user reaches the editor the fonts are ready.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final f in kEditorFonts) {
      GoogleFonts.getFont(f);
    }
    // Same idea for the studio's fragment shaders: compile them once in the
    // background now, so the first generated background the user opens is
    // already the finished picture rather than its fallback gradient.
    StudioShaders.warmUp();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app whenever the language OR the theme changes.
    return ValueListenableBuilder<String>(
      valueListenable: S.lang,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, themeMode, _) {
            return MaterialApp(
              title: 'Status Maker',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              builder: (context, child) {
                // Initialise responsive sizing before any screen builds, and
                // rebuild on size / orientation changes.
                ScreenUtil.init(context);
                return child ?? const SizedBox.shrink();
              },
              navigatorKey: PushService.navigatorKey,
              scaffoldMessengerKey: PushService.scaffoldMessengerKey,
              locale: Locale(lang),
              supportedLocales: const [Locale('en'), Locale('hi')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Returning users go straight to the shell; the language
              // picker + onboarding are a first-run step only.
              // Not `home:` — it asserts against onGenerateInitialRoutes. This
              // still gives MaterialApp a Navigator; the app pushes no names.
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => const SplashScreen(),
              ),
              // Only consulted once, at startup. The shell route carries the
              // same name onboarding gives it, so AppNav can pop back to it.
              onGenerateInitialRoutes: (_) => [
                if (FirstRun.done)
                  MaterialPageRoute<void>(
                    settings:
                        const RouteSettings(name: AppNav.shellRouteName),
                    builder: (_) => const MainLayout(),
                  )
                else
                  MaterialPageRoute<void>(
                    builder: (_) => const SplashScreen(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
