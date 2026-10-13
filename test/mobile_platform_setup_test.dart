import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_compress_common/flutter_image_compress_common.dart';
import 'package:fitlek1/services/image_upload_service.dart';
import 'package:fitlek1/services/social_auth_errors.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_image_compress');
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
      'iPhone HEIC is converted to JPEG with orientation correction and no location metadata',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    FlutterImageCompressCommon.registerWith();
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'compressWithList')
        return Uint8List.fromList([255, 216, 255, 0]);
      return true;
    });
    final output = await ImageUploadService.prepare(
        Uint8List.fromList(
            [0, 0, 0, 24, 102, 116, 121, 112, 104, 101, 105, 99]),
        'IMG_001.HEIC');
    expect(output.mimeType, 'image/jpeg');
    expect(output.filename, 'IMG_001.jpg');
    final args = calls
        .firstWhere((c) => c.method == 'compressWithList')
        .arguments as List;
    expect(args[5], true); // Correct EXIF orientation.
    expect(args[7], false); // Strip EXIF, including GPS.
    expect(output.bytes.length, lessThanOrEqualTo(ImageUploadService.maxBytes));
  });
  test('large iPhone images retry compression; empty photos fail before upload',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    FlutterImageCompressCommon.registerWith();
    int attempts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'compressWithList')
        return ++attempts == 1
            ? Uint8List(ImageUploadService.maxBytes + 1)
            : Uint8List.fromList([255, 216, 255]);
      return true;
    });
    final output = await ImageUploadService.prepare(
        Uint8List.fromList([1, 2, 3]), 'photo.heic');
    expect(attempts, 2);
    expect(output.mimeType, 'image/jpeg');
    await expectLater(ImageUploadService.prepare(Uint8List(0), 'empty.jpg'),
        throwsFormatException);
  });
  test(
      'provider configuration failures use readable messages rather than Firebase internals',
      () {
    final message = socialAuthError(
        FirebaseAuthException(code: 'operation-not-allowed'), 'Apple');
    expect(message, contains('use email and password'));
    expect(message, isNot(contains('firebase_auth')));
    expect(
        socialAuthError(
            FirebaseAuthException(code: 'popup-closed-by-user'), 'Google'),
        'cancelled');
  });
}
