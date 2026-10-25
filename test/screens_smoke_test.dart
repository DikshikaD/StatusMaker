// Pumps each screen on its own — English/Hindi x light/dark — with no backend,
// i.e. the offline / empty / failed-load state every screen must survive.
// Fails on any framework error other than RenderFlex overflow (see
// app_flow_test.dart for why overflow is ignored under the Ahem test font).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_theme.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/category/presentation/category_screen.dart';
import 'package:status_maker/features/community/presentation/community_submission_screen.dart';
import 'package:status_maker/features/create/presentation/create_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/favorites/presentation/favorites_screen.dart';
import 'package:status_maker/features/notifications/presentation/notifications_screen.dart';
import 'package:status_maker/features/settings/presentation/settings_screen.dart';

final Map<String, Widget Function()> screens = {
  'Create': () => const CreateScreen(),
  'Category': () => const CategoryScreen(categoryName: 'Good Morning'),
  'Explore': () => const ExploreScreen(),
  'Favorites': () => const FavoritesScreen(),
  'Notifications': () => const NotificationsScreen(),
  'Settings': () => const SettingsScreen(),
  'Community': () => const CommunitySubmissionScreen(),
  'Editor (blank)': () => const StatusPersonalizerScreen(
      templateName: 'Test', category: 'Good Morning'),
};

final List<Object> _errors = [];

Future<void> pumpScreen(
    WidgetTester t, Widget screen, String lang, ThemeMode mode) async {
  _errors.clear();
  final previous = FlutterError.onError;
  FlutterError.onError = (d) {
    if (!d.exceptionAsString().contains('overflowed')) {
      _errors.add('${d.exception}\n${d.stack}');
    }
  };
  addTearDown(() => FlutterError.onError = previous);
  SharedPreferences.setMockInitialValues({'lang': lang});
  await S.init();
  S.lang.value = lang;
  t.view.physicalSize = const Size(390, 844) * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: mode,
    builder: (context, child) {
      ScreenUtil.init(context);
      return child!;
    },
    home: screen,
  ));
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> drain(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 30));
}

void main() {
  for (final e in screens.entries) {
    for (final lang in const ['en', 'hi']) {
      for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('${e.key} [$lang, ${mode.name}] renders offline', (t) async {
          await pumpScreen(t, e.value(), lang, mode);
          expect(find.byType(Scaffold), findsWidgets);
          expect(_errors, isEmpty);
          await drain(t);
          expect(_errors, isEmpty);
        });
      }
    }
  }
}
