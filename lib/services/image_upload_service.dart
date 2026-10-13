import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class PreparedImage {
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  const PreparedImage(this.bytes, this.filename, this.mimeType);
}

class ImageUploadService {
  static const maxBytes = 5 * 1024 * 1024;
  static String? detectMime(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) return 'image/jpeg';
    if (bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71) return 'image/png';
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP')
      return 'image/webp';
    return null;
  }

  static Future<PreparedImage> prepare(Uint8List bytes, String filename) async {
    if (bytes.isEmpty)
      throw const FormatException(
          'The selected photo is empty. Please select another photo.');
    // Native iPhone decoding handles HEIC; upload JPEG so the server never needs HEVC support.
    if (!kIsWeb &&
        [TargetPlatform.iOS, TargetPlatform.android]
            .contains(defaultTargetPlatform)) {
      for (final quality in [82, 65, 45]) {
        final output = await FlutterImageCompress.compressWithList(bytes,
            minWidth: 1600,
            minHeight: 1600,
            quality: quality,
            format: CompressFormat.jpeg,
            keepExif: false,
            autoCorrectionAngle: true);
        if (output.isEmpty)
          throw const FormatException(
              'Could not read this photo. Please select another photo.');
        if (output.length <= maxBytes)
          return PreparedImage(
              output,
              '${filename.replaceFirst(RegExp(r'\.[^.]+$'), '')}.jpg',
              'image/jpeg');
      }
      throw const FormatException(
          'This photo is too large. Please select a smaller photo.');
    }
    final mime = detectMime(bytes);
    if (mime == null)
      throw const FormatException('Please select a JPEG, PNG or WebP photo.');
    if (bytes.length > maxBytes)
      throw const FormatException('Please select a photo smaller than 5 MB.');
    return PreparedImage(bytes, filename, mime);
  }
}
