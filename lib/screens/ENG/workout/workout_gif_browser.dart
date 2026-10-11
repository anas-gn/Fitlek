import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:web/web.dart' as web;
import 'workout_ui.dart';

const supportsBrowserGif = true;
Widget browserGif(
        {required String location,
        required bool playing,
        required BoxFit fit,
        String? semanticLabel}) =>
    _BrowserGif(
        location: location,
        playing: playing,
        fit: fit,
        semanticLabel: semanticLabel);

// The provider CDN permits image embedding but does not supply CORS headers.
// Render directly; never proxy the GIF. A display-only canvas captures its
// first frame for thumbnails/reduced motion. It is never read or exported.
class _BrowserGif extends StatefulWidget {
  final String location;
  final bool playing;
  final BoxFit fit;
  final String? semanticLabel;
  const _BrowserGif(
      {required this.location,
      required this.playing,
      required this.fit,
      this.semanticLabel});
  @override
  State<_BrowserGif> createState() => _BrowserGifState();
}

class _BrowserGifState extends State<_BrowserGif> {
  web.HTMLImageElement? _image;
  web.HTMLCanvasElement? _canvas;
  JSFunction? _onLoad, _onError;
  bool _ready = false, _error = false;
  void _created(Object element) {
    final container = element as web.HTMLDivElement;
    container.setAttribute('data-workout-gif', '');
    container.style
      ..width = '100%'
      ..height = '100%'
      ..display = 'flex'
      ..alignItems = 'center'
      ..justifyContent = 'center'
      ..pointerEvents = 'none';
    final image = web.HTMLImageElement()..alt = widget.semanticLabel ?? '';
    final canvas = web.HTMLCanvasElement();
    for (final style in [image.style, canvas.style]) {
      style
        ..width = '100%'
        ..height = '100%'
        ..objectFit = widget.fit == BoxFit.cover ? 'cover' : 'contain';
    }
    image.style.display = 'none';
    canvas.style.display = 'none';
    _image = image;
    _canvas = canvas;
    container.appendChild(canvas);
    container.appendChild(image);
    _onLoad = ((web.Event event) {
      if (!mounted || !identical(image, _image) || image.naturalWidth == 0) {
        return;
      }
      canvas.width = image.naturalWidth;
      canvas.height = image.naturalHeight;
      (canvas.getContext('2d') as web.CanvasRenderingContext2D)
          .drawImage(image, 0, 0);
      setState(() {
        _ready = true;
        _error = false;
      });
      _apply();
    }).toJS;
    _onError = ((web.Event event) {
      if (mounted && image.hasAttribute('src')) setState(() => _error = true);
    }).toJS;
    image.addEventListener('load', _onLoad);
    image.addEventListener('error', _onError);
    image.src = widget.location;
  }

  void _apply() {
    final image = _image, canvas = _canvas;
    if (image == null || canvas == null) return;
    image.alt = widget.semanticLabel ?? '';
    if (!_ready) return;
    if (widget.playing) {
      if (!image.hasAttribute('src')) image.src = widget.location;
      image.style.display =
          image.complete && image.naturalWidth > 0 ? 'block' : 'none';
      canvas.style.display = image.style.display == 'block' ? 'none' : 'block';
    } else {
      image.style.display = 'none';
      canvas.style.display = 'block';
      image.removeAttribute('src');
    }
  }

  @override
  void didUpdateWidget(covariant _BrowserGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location) {
      _ready = false;
      _error = false;
      _image?.style.display = 'none';
      _canvas?.style.display = 'none';
      _image?.src = widget.location;
    } else {
      _apply();
    }
  }

  @override
  void dispose() {
    _image?.removeEventListener('load', _onLoad);
    _image?.removeEventListener('error', _onError);
    _image?.removeAttribute('src');
    _canvas?.width = 0;
    _canvas?.height = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Semantics(
            label: widget.semanticLabel,
            image: true,
            child: HtmlElementView.fromTagName(
                tagName: 'div',
                onElementCreated: _created,
                hitTestBehavior: PlatformViewHitTestBehavior.transparent)),
        if (_error)
          Center(
              child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _error = false;
                      _ready = false;
                    });
                    _image?.src = widget.location;
                  },
                  icon: const Icon(Icons.refresh),
                  label: const WorkoutLabel('Reload demonstration')))
        else if (!_ready)
          const Center(
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))),
      ]);
}
