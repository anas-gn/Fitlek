// Rebuild iOS branding without cropping or stretching the existing artwork.
// Run from the Flutter project root: dart run scripts/generate_ios_branding.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  // Keep the original S symbol proportionate, with 15% clear space on each side.
  final mark = img.decodePng(File('assets/branding/icon_app_dark.png').readAsBytesSync())!;
  final canvas = img.Image(width: 1024, height: 1024, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  final ratio = 716 / math.max(mark.width, mark.height);
  final fitted = img.copyResize(mark, width: (mark.width * ratio).round(),
      height: (mark.height * ratio).round(), interpolation: img.Interpolation.cubic);
  img.compositeImage(canvas, fitted, dstX: (1024 - fitted.width) ~/ 2,
      dstY: (1024 - fitted.height) ~/ 2);
  File('assets/branding/icon_ios.png').writeAsBytesSync(img.encodePng(canvas));
  const folder = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final catalog = jsonDecode(File('$folder/Contents.json').readAsStringSync()) as Map;
  for (final entry in catalog['images'] as List) {
    final size = double.parse((entry['size'] as String).split('x').first);
    final scale = double.parse((entry['scale'] as String).replaceAll('x', ''));
    final pixels = (size * scale).round();
    final icon = img.copyResize(canvas, width: pixels, height: pixels,
        interpolation: img.Interpolation.cubic);
    File('$folder/${entry['filename']}').writeAsBytesSync(img.encodePng(icon));
  }
  final wordmark = img.decodePng(File('assets/branding/logo_light.png').readAsBytesSync())!;
  const launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
  for (final scale in [1, 2, 3]) {
    final logo = img.copyResize(wordmark, width: 240 * scale,
        interpolation: img.Interpolation.cubic);
    final suffix = scale == 1 ? '' : '@${scale}x';
    File('$launch/LaunchImage$suffix.png').writeAsBytesSync(img.encodePng(logo));
  }
  print('Generated iOS icons with 15% clear margins and proportionate launch wordmarks.');
}