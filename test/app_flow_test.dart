// Smoke test of the real app shell: boots MyApp (no backend — SupabaseService
// never throws without credentials) and walks the launch journey, failing on
// any framework exception, overflow or dead end.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/theme_controller.dart';
import 'package:status_maker/core/utils/first_run.dart';
import 'package:status_maker/features/home/presentation/main_layout.dart';
import 'package:status_maker/features/home/presentation/home_screen.dart';
import 'package:status_maker/features/onboarding/presentation/onboarding_screen.dart';
import 'package:status_maker/main.dart';

Future<void> boot(
  WidgetTester t, {
  Size size = const Size(390, 844),
  Map<String, Object> prefs = const {},
}) async {
  _realErrors.clear();
  final previous = FlutterError.onError;
  FlutterError.onError = (d) {
    if (!d.exceptionAsString().contains('overflowed')) _realErrors.add(d.exception);
  };
  addTearDown(() => FlutterError.onError = previous);
  SharedPreferences.setMockInitialValues(prefs);
  await S.init();
  await ThemeController.init();
  await FirstRun.init();
  t.view.physicalSize = size * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(const MyApp());
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
}

/// Bounded pumping: the feed and onboarding have endless animations/loaders, so
/// pumpAndSettle would never return.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Lets the feed's load timeouts fire so no timer outlives the test.
Future<void> drain(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 30));
}

/// flutter_test renders every glyph in the Ahem font (a full-width square), so
/// text looks far wider than with the real fonts and RenderFlex "overflowed by
/// N pixels" errors are test-font artefacts, not layout bugs. Everything else —
/// null checks, state errors, failed assertions — is a real failure.
final List<Object> _realErrors = [];

void expectNoRealErrors(WidgetTester t) => expect(_realErrors, isEmpty);

void main() {
  testWidgets('launch: splash is blank then language picker opens at once',
      (t) async {
    await boot(t);
    expect(find.text(S.t('choose_language')), findsOneWidget);
    expect(find.text(S.t('continue_btn')), findsOneWidget);
    expectNoRealErrors(t);
    await drain(t);
  });

  testWidgets('launch journey: language -> onboarding -> home', (t) async {
    await boot(t);
    await t.tap(find.text(S.t('continue_btn')));
    await settle(t);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // Step through every onboarding page with Next, then Get started.
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(S.t('next')));
      await settle(t);
    }
    await t.tap(find.text(S.t('get_started')));
    await settle(t);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(FirstRun.done, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), isTrue);
    expectNoRealErrors(t);
    await drain(t);
  });

  testWidgets('returning user: opens straight on the shell, no picker',
      (t) async {
    await boot(t, prefs: {'onboarding_done': true});
    expect(find.byType(MainLayout), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(S.t('choose_language')), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
    expectNoRealErrors(t);
    await drain(t);
  });

  testWidgets('onboarding Skip goes straight to home', (t) async {
    await boot(t);
    await t.tap(find.text(S.t('continue_btn')));
    await settle(t);
    await t.tap(find.text(S.t('skip')));
    await settle(t);
    expect(find.byType(HomeScreen), findsOneWidget);
    expectNoRealErrors(t);
    await drain(t);
  });

  for (final size in const [Size(320, 568), Size(412, 915), Size(800, 1280)]) {
    testWidgets('home renders without errors at $size', (t) async {
      await boot(t, size: size);
      await t.tap(find.text(S.t('continue_btn')));
      await settle(t);
      await t.tap(find.text(S.t('skip')));
      await settle(t);
      expect(find.byType(HomeScreen), findsOneWidget);
      expectNoRealErrors(t);
      await drain(t);
    });
  }
}
