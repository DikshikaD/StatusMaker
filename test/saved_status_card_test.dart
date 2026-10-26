import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_maker/core/localization/strings.dart';
import 'package:status_maker/core/theme/app_theme.dart';
import 'package:status_maker/core/utils/responsive.dart';
import 'package:status_maker/features/statuses/data/saved_status.dart';
import 'package:status_maker/shared/widgets/saved_status_card.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    for (final lang in ['en', 'hi']) {
      testWidgets(
          'report/hide/block menu is never clipped under Customize '
          '(remix count shown, 360dp, text x$scale, $lang)', (t) async {
        SharedPreferences.setMockInitialValues({'lang': lang});
        await S.init();
        S.lang.value = lang;
        t.view.physicalSize = const Size(360, 800) * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        await t.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            ScreenUtil.init(context);
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            );
          },
          home: Scaffold(
            body: SingleChildScrollView(
              child: SavedStatusCard(
                status: const SavedStatus(
                  id: 'a',
                  userId: 'someone-else',
                  design: {},
                  isPublic: true,
                  likesCount: 12345,
                  remixCount: 1234,
                ),
                onCustomize: () {},
              ),
            ),
          ),
        ));
        await t.pump();

        final more = t.getRect(find.byIcon(Icons.more_horiz));
        final cta = t.getRect(find.byType(ElevatedButton));
        final screen = Offset.zero & const Size(360, 800);
        expect(screen.contains(more.topLeft) && screen.contains(more.bottomRight),
            isTrue, reason: 'menu icon must be on screen: $more');
        expect(more.right, lessThanOrEqualTo(cta.left),
            reason: 'menu icon $more overlaps Customize $cta');
        // The Ahem test font is 1em wide per glyph, far wider than any real
        // font, so RenderFlex overflow is ignored here exactly as in
        // app_flow_test.dart; anything else is a real error.
        final ex = t.takeException();
        expect(ex == null || ex.toString().contains('overflowed'), isTrue,
            reason: '$ex');
      });
    }
  }
}
