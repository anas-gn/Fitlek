@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;
import 'package:fitlek1/screens/ENG/workout/workout_gif.dart';

const gifUrl = String.fromEnvironment('WORKOUT_GIF_URL');

web.Element? gifElement([web.ShadowRoot? root]) {
  final result = root == null
      ? web.document.querySelector('[data-workout-gif]')
      : root.querySelector('[data-workout-gif]');
  if (result != null) return result;
  final nodes = root == null
      ? web.document.querySelectorAll('*')
      : root.querySelectorAll('*');
  for (var i = 0; i < nodes.length; i++) {
    final shadow = (nodes.item(i) as web.Element).shadowRoot;
    if (shadow != null) {
      final nested = gifElement(shadow);
      if (nested != null) return nested;
    }
  }
  return null;
}

void main() {
  test(
      'real CDN GIF displays without CORS and supports still thumbnails, play, pause and reduced motion',
      () async {
    WidgetsFlutterBinding.ensureInitialized();
    Widget preview(
            {bool playing = false,
            bool reduced = false,
            bool visible = true}) =>
        MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(disableAnimations: reduced),
                child:
                    TickerMode(enabled: visible, child: constSized(playing))));
    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 200 && !condition(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(condition(), isTrue);
    }

    runApp(preview());
    await waitFor(() =>
        (gifElement()?.querySelector('canvas') as web.HTMLCanvasElement?)
            ?.width ==
        180);
    final container = gifElement()!;
    final image = container.querySelector('img') as web.HTMLImageElement;
    final canvas = container.querySelector('canvas') as web.HTMLCanvasElement;
    expect(canvas.height, 180);
    expect(canvas.style.display, 'block');
    expect(image.hasAttribute('src'), isFalse);
    runApp(preview(playing: true));
    await waitFor(() => image.style.display == 'block');
    expect(image.naturalWidth, 180);
    expect(canvas.style.display, 'none');
    runApp(preview());
    await WidgetsBinding.instance.endOfFrame;
    expect(image.hasAttribute('src'), isFalse);
    expect(canvas.style.display, 'block');
    runApp(preview(playing: true, reduced: true));
    await WidgetsBinding.instance.endOfFrame;
    expect(image.hasAttribute('src'), isFalse);
    runApp(preview(playing: true, visible: false));
    await WidgetsBinding.instance.endOfFrame;
    expect(image.hasAttribute('src'), isFalse);
    runApp(const SizedBox());
    await WidgetsBinding.instance.endOfFrame;
  }, skip: gifUrl.isEmpty);
}

Widget constSized(bool playing) => Center(
    child: SizedBox(
        width: 240,
        height: 240,
        child: WorkoutAnimatedImage(
            location: gifUrl,
            playing: playing,
            semanticLabel: 'Barbell bench press')));
