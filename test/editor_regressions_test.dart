// Regression tests for the editor/posting fixes:
//  • text style edits are field-level patches that apply immediately and can
//    neither lose nor be lost to a concurrent edit (font colour bug)
//  • every text layer of a template canvas can be dragged, in design space,
//    clamped to the canvas (position editing in premade templates)
//  • helpers behind idempotent posting and typed share files
//
// Text objects here use a font family Google Fonts doesn't know, so
// buildTextStyle falls back to a plain TextStyle and nothing is fetched.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/fixed_templates.dart';
import 'package:status_maker/features/editor/data/status_design.dart';
import 'package:status_maker/features/editor/widgets/editable_text_widget.dart';
import 'package:status_maker/features/editor/widgets/fixed_template_canvas.dart';
import 'package:status_maker/features/editor/widgets/status_canvas.dart';
import 'package:status_maker/features/statuses/data/status_repository.dart';
import 'package:status_maker/shared/utils/share_image.dart';

const _font = 'NoSuchTestFont';

// Plain Colors (not MaterialColor swatches) so equality is a value compare.
const _red = Color(0xFFEF5350);
const _green = Color(0xFF66BB6A);
const _blue = Color(0xFF42A5F5);
const _yellow = Color(0xFFFFD54F);

void main() {
  group('EditorController.patchText', () {
    test('applies to the live object, not a stale toolbar snapshot', () {
      final c = EditorController();
      final t = c.addText('Hello');
      c.patchText(t.id, (x) => x.copyWith(fontFamily: _font));
      // A toolbar built now holds this snapshot…
      final snapshot = c.texts.single;
      // …then a drag commits a new position before the colour tap lands.
      c.updateTextTransform(t.id, position: const Offset(10, 20));
      c.patchText(t.id, (x) => x.copyWith(color: _red));

      final now = c.texts.single;
      expect(now.color, _red);
      expect(now.position, const Offset(10, 20),
          reason: 'the colour edit must not revert the move');
      expect(snapshot.position, isNot(const Offset(10, 20)));
    });

    test('consecutive colour changes each land', () {
      final c = EditorController();
      final t = c.addText('Hi');
      for (final color in [_red, _green, _blue, Colors.white]) {
        c.patchText(t.id, (x) => x.copyWith(color: color));
        expect(c.texts.single.color, color);
      }
      c.patchText(t.id, (x) => x.copyWith(fontSize: 50));
      expect(c.texts.single.color, Colors.white,
          reason: 'changing size keeps the chosen colour');
    });

    test('a no-op patch is not an edit', () {
      final c = EditorController();
      final t = c.addText('Hi');
      c.clearHistory();
      var notified = 0;
      c.addListener(() => notified++);
      c.patchText(t.id, (x) => x.copyWith(color: x.color));
      expect(notified, 0);
      expect(c.isDirty.value, isFalse);
      expect(c.canUndo, isFalse);
    });
  });

  testWidgets('canvas shows a new font colour on the very next frame',
      (tester) async {
    final c = EditorController();
    final t = c.addText('Hello');
    c.patchText(t.id, (x) => x.copyWith(fontFamily: _font));
    c.clearSelection();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 640,
            child: AnimatedBuilder(
              animation: c,
              builder: (_, __) =>
                  StatusCanvas(controller: c, repaintKey: GlobalKey()),
            ),
          ),
        ),
      ),
    ));

    RenderParagraph paragraph() => tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byType(EditableTextWidget),
            matching: find.byType(RichText),
          ),
        );

    expect(paragraph().text.style?.color, Colors.white);
    for (final color in [_red, _yellow, Colors.black]) {
      c.patchText(t.id, (x) => x.copyWith(color: color));
      await tester.pump(); // exactly one frame, no other interaction
      expect(paragraph().text.style?.color, color);
    }
  });

  group('FixedTemplateCanvas text dragging', () {
    StatusDesign design() => StatusDesign(
          background: const BackgroundState(color: Colors.black),
          texts: [
            TextObject(
              id: 'quote',
              text: 'Good night',
              fontFamily: _font,
              position: const Offset(30, 300),
            ),
          ],
          images: const [],
          elements: const [],
        );

    Future<List<Offset>> dragBy(WidgetTester tester, Offset by) async {
      final moves = <Offset>[];
      var ended = false;
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: kFixedCanvasSize.width,
            height: kFixedCanvasSize.height,
            child: FixedTemplateCanvas(
              design: design(),
              onTextTap: (_) {},
              onTextMove: (_, p) => moves.add(p),
              onTextMoveEnd: (_) => ended = true,
            ),
          ),
        ),
      ));
      await tester.drag(find.text('Good night'), by);
      await tester.pumpAndSettle();
      expect(ended, isTrue);
      return moves;
    }

    testWidgets('moves the text in design space', (tester) async {
      final moves = await dragBy(tester, const Offset(60, 80));
      expect(moves, isNotEmpty);
      expect(moves.last.dx, greaterThan(30 + 30));
      expect(moves.last.dy, greaterThan(300 + 50));
    });

    testWidgets('keeps the text centre on the canvas', (tester) async {
      final moves = await dragBy(tester, const Offset(0, 2000));
      // The slot is ~312 wide; its centre is clamped 12 px inside the edge.
      expect(moves.last.dy, lessThan(kFixedCanvasSize.height));
    });

    testWidgets('read-only previews are not draggable', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: SizedBox(
            width: kFixedCanvasSize.width,
            height: kFixedCanvasSize.height,
            child: FixedTemplateCanvas(design: design()),
          ),
        ),
      ));
      expect(
        find.ancestor(
          of: find.text('Good night'),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });
  });

  group('posting helpers', () {
    test('newStatusId is a v4 UUID and unique', () {
      final re = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      final ids = {for (var i = 0; i < 200; i++) newStatusId()};
      expect(ids.length, 200);
      expect(ids.every(re.hasMatch), isTrue);
    });

    test('contentKey is stable for equal bytes and differs otherwise', () {
      final a = Uint8List.fromList(List.generate(1000, (i) => i % 251));
      final b = Uint8List.fromList(a);
      final c = Uint8List.fromList(a)..[500] ^= 1;
      expect(contentKey(a), contentKey(b));
      expect(contentKey(a), isNot(contentKey(c)));
    });

    test('shared files keep the stored image type', () {
      expect(shareExtensionFor('https://x/thumbnails/u/1_ab.jpg'), 'jpg');
      expect(shareExtensionFor('https://x/thumbnails/u/1_ab.png'), 'png');
      expect(shareExtensionFor('https://x/thumbnails/u/1_ab.webp'), 'webp');
      expect(shareExtensionFor('https://x/thumbnails/u/1_ab'), 'png');
    });
  });
}
