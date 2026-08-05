// The remix gate: Post stays disabled while a status opened from someone
// else's public post is still byte-for-byte theirs. This pins down
// StatusDesign.contentSignature, which is what the gate compares — including
// the cases a plain isDirty flag gets wrong.
//
// openAsRemix() mirrors what StatusPersonalizerScreen.initState does, so these
// tests fail if either side of that pairing drifts.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_maker/features/editor/controller/editor_controller.dart';
import 'package:status_maker/features/editor/data/status_design.dart';

const canvas = Size(360, 640);

StatusDesign aPublishedStatus() => StatusDesign(
      background: const BackgroundState(gradientColors: [
        Color(0xFF3C2A5E),
        Color(0xFF8A5570),
      ]),
      texts: [
        TextObject(
          id: 't1',
          text: 'Good Morning',
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 28,
          position: const Offset(0.5, 0.35),
          zIndex: 0,
        ),
        TextObject(
          id: 't2',
          text: 'Have a nice day',
          fontFamily: 'Poppins',
          color: Colors.white70,
          fontSize: 16,
          position: const Offset(0.5, 0.55),
          zIndex: 1,
        ),
      ],
      images: const [],
      elements: [
        ElementObject(
          id: 'e1',
          shape: ElementShape.heart,
          color: Colors.white,
          position: const Offset(0.8, 0.2),
          zIndex: 2,
        ),
      ],
      frame: StatusFrame.musicPlayer,
      frameColor: Colors.white,
      canvasSize: canvas,
    );

/// What the screen does in initState, and what it does per rebuild.
(EditorController, String) openAsRemix() {
  final c = EditorController();
  aPublishedStatus().applyTo(c);
  c.clearSelection();
  c.clearHistory();
  return (c, sigOf(c));
}

String sigOf(EditorController c) =>
    StatusDesign.fromController(c, canvasSize: canvas).contentSignature;

void main() {
  test('untouched remix keeps the same signature -> Post blocked', () {
    final (c, baseline) = openAsRemix();
    expect(sigOf(c), baseline);
    expect(c.isDirty.value, isFalse);
  });

  test('merely SELECTING an object does not count as a change', () {
    final (c, baseline) = openAsRemix();
    c.select('t1'); // _bringToFront bumps zIndex and flips isDirty
    c.select('e1');
    expect(c.isDirty.value, isTrue,
        reason: 'isDirty alone would wrongly enable Post here');
    expect(sigOf(c), baseline,
        reason: 'signature ignores z, so a tap is not a customization');
  });

  test('a real edit changes the signature -> Post enabled', () {
    final (c, baseline) = openAsRemix();
    c.updateTextContent('t1', 'Good Evening');
    expect(sigOf(c), isNot(baseline));
  });

  test('every kind of edit is caught', () {
    for (final edit in <(String, void Function(EditorController))>[
      ('text content', (c) => c.updateTextContent('t2', 'x')),
      ('frame', (c) => c.setFrame(StatusFrame.polaroid)),
      ('frame colour', (c) => c.setFrame(StatusFrame.musicPlayer, color: Colors.red)),
      ('frame width', (c) => c.setFrame(StatusFrame.musicPlayer, width: 2.4)),
      ('background', (c) => c.setBackground(const BackgroundState(color: Colors.black))),
      ('delete an element', (c) => c.deleteElement('e1')),
      ('add an element', (c) => c.addElement(ElementShape.star)),
      ('add text', (c) => c.addText('new')),
      ('move text', (c) => c.updateTextTransform('t1', position: const Offset(0.5, 0.6))),
    ]) {
      final (c, baseline) = openAsRemix();
      edit.$2(c);
      expect(sigOf(c), isNot(baseline), reason: 'undetected edit: ${edit.$1}');
    }
  });

  test('undoing back to the original re-blocks Post', () {
    final (c, baseline) = openAsRemix();
    c.updateTextContent('t1', 'Something else');
    expect(sigOf(c), isNot(baseline));
    c.undo();
    expect(sigOf(c), baseline,
        reason: 'gate is recomputed, not latched on the first edit');
  });

  test('a nudge that lands back within a tenth of a pixel is not an edit', () {
    final (c, baseline) = openAsRemix();
    c.updateTextTransform('t1', position: const Offset(0.5, 0.35 + 0.000001));
    expect(sigOf(c), baseline);
  });

  test('signature survives a round trip through JSON', () {
    final (c, baseline) = openAsRemix();
    final reloaded = StatusDesign.fromJson(
        StatusDesign.fromController(c, canvasSize: canvas).toJson());
    expect(reloaded.contentSignature, baseline);
  });

  test('canvas size is not part of the signature', () {
    final (c, baseline) = openAsRemix();
    expect(
      StatusDesign.fromController(c, canvasSize: const Size(412, 732))
          .contentSignature,
      baseline,
    );
  });
}
