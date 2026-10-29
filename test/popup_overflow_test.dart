// Opens every popup (confirm, share, discard, language, post actions + report
// sheets) at small phone, landscape, tablet and 2x text scale, in EN and HI,
// and fails on any RenderFlex overflow. Uses the SDK's real Roboto — under the
// default Ahem test font every glyph is a full-width square, so overflow
// checks would be meaningless (see app_flow_test.dart).
// Pumps each screen on its own — English/Hindi x light/dark — with no backend,
// i.e. the offline / empty / failed-load state every screen must survive.
// Fails on any framework error other than RenderFlex overflow (see
// app_flow_test.dart for why overflow is ignored under the Ahem test font).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/supabase/supabase_service.dart';
import 'package:status_maker/core/theme/app_theme.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/shared/widgets/confirm_dialog.dart';
import 'package:status_maker/shared/widgets/share_target_dialog.dart';
import 'package:status_maker/features/editor/widgets/discard_changes_dialog.dart';
import 'package:status_maker/features/onboarding/presentation/language_dialog.dart';
import 'package:status_maker/features/moderation/post_actions_sheet.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/features/category/presentation/category_screen.dart';
import 'package:status_maker/features/create/presentation/create_screen.dart';
import 'package:status_maker/features/editor/presentation/status_personalizer_screen.dart';
import 'package:status_maker/features/explore/presentation/explore_screen.dart';
import 'package:status_maker/features/favorites/presentation/favorites_screen.dart';
import 'package:status_maker/features/notifications/presentation/notifications_screen.dart';
import 'package:status_maker/features/settings/presentation/settings_screen.dart';

final Map<String, Widget Function()> screens = {
  'Create': () => const CreateScreen(),
  'CANARY': () => Scaffold(body: Row(children: [Text('x'*200)])),
  'Category': () => const CategoryScreen(categoryName: 'Good Morning'),
  'Explore': () => const ExploreScreen(),
  'Favorites': () => const FavoritesScreen(),
  'Notifications': () => const NotificationsScreen(),
  'Settings': () => const SettingsScreen(),
  'Editor (blank)': () => const StatusPersonalizerScreen(
      templateName: 'Test', category: 'Good Morning'),
};


final List<String> _overflows = [];
final List<String> _other = [];

Future<void> _loadRoboto() async {
  final dir = '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';
  final l = FontLoader('Roboto');
  for (final f in ['Regular', 'Medium', 'Bold', 'Light']) {
    l.addFont(File('$dir/Roboto-$f.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadRoboto();
    SharedPreferences.setMockInitialValues({});
    await SupabaseService.ensureReady()
        .timeout(const Duration(seconds: 20), onTimeout: () => false);
  });

  final sizes = {
    'small 320x480': const Size(320, 480),
    'big 430x932': const Size(430, 932),
    'landscape 844x390': const Size(844, 390),
    'tablet 768x1024': const Size(768, 1024),
  };
  final popups = <String, Future<void> Function(BuildContext)>{
    'confirm': (c) => showConfirmDialog(c,
        title: 'Delete this status permanently from your account?',
        message: 'This will remove it from everywhere and cannot be undone. ' * 3),
    'share': (c) => showShareTargetDialog(c),
    'report': (c) async { showPostActionsSheet(c, const SavedStatus(id: 'a', userId: 'u')); },
    'discard': (c) => showDiscardChangesDialog(c),
    'language': (c) => showLanguagePicker(c, onContinue: () {}),
    'postActions': (c) => showPostActionsSheet(c, const SavedStatus(id: 'a', userId: 'u')),
  };
  for (final p in popups.entries) {
    for (final s in sizes.entries) {
      for (final scale in const [1.0, 2.0]) {
        for (final lang in const ['en', 'hi']) {
          testWidgets('popup no overflow: ${p.key} ${s.key} x$scale $lang', (t) async {
            _overflows.clear(); _other.clear();
            final prev = FlutterError.onError;
            FlutterError.onError = (d) {
              final m = d.exceptionAsString();
              (m.contains('overflowed') ? _overflows : _other).add(m.split('\n').first);
            };
            SharedPreferences.setMockInitialValues({'lang': lang});
            await S.init(); S.lang.value = lang;
            t.view.physicalSize = s.value * 2; t.view.devicePixelRatio = 2;
            addTearDown(t.view.reset);
            await t.pumpWidget(MaterialApp(
              theme: AppTheme.lightTheme.copyWith(textTheme: AppTheme.lightTheme.textTheme.apply(fontFamily: 'Roboto')),
              builder: (context, child) { ScreenUtil.init(context);
                return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!); },
              home: Builder(builder: (c) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => p.value(c), child: const Text('open'))))),
            ));
            await t.tap(find.text('open'));
            if (p.key == 'report') { await t.pump(const Duration(milliseconds: 600)); await t.tap(find.byIcon(Icons.flag_outlined)); }
            for (var i = 0; i < 15; i++) { await t.pump(const Duration(milliseconds: 100)); }
            FlutterError.onError = prev;
            expect(_other, isEmpty);
            expect(_overflows, isEmpty, reason: _overflows.join('\n'));
          });
        }
      }
    }
  }
}
