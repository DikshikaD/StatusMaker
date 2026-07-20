import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/features/editor/utils/text_style_builder.dart';
import 'package:status_maker/features/splash/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the user's saved language before the first frame builds.
  await S.init();
  // Start downloading the template fonts early so they're cached before the
  // user reaches the designs (keeps every template's font consistent).
  for (final f in kEditorFonts) {
    GoogleFonts.getFont(f);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app whenever the language changes.
    return ValueListenableBuilder<String>(
      valueListenable: S.lang,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'Status Maker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            // Initialise responsive sizing before any screen builds, and
            // rebuild on size / orientation changes.
            ScreenUtil.init(context);
            return child ?? const SizedBox.shrink();
          },
          locale: Locale(lang),
          supportedLocales: const [Locale('en'), Locale('hi')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
