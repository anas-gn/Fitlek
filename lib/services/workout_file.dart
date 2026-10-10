import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'workout_import_reader.dart';
import 'workout_service.dart';
import 'workout_download_stub.dart'
    if (dart.library.js_interop) 'workout_download_web.dart' as browser;
import 'workout_file_stub.dart' if (dart.library.io) 'workout_file_io.dart'
    as platform;

Future<bool> saveWorkoutJson(String filename, Map<String, dynamic> data) async {
  final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
  if (bytes.length > workoutImportByteLimit) {
    throw const WorkoutApiException('import_too_large', 413);
  }
  if (kIsWeb) {
    await browser.downloadWorkoutJsonFile(filename, bytes);
    return true;
  }
  final mobile = {TargetPlatform.android, TargetPlatform.iOS}
      .contains(defaultTargetPlatform);
  final path = await FilePicker.platform.saveFile(
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: mobile ? bytes : null);
  if (path == null) return false;
  if (!mobile) await platform.writeWorkoutFile(path, bytes);
  return true;
}
