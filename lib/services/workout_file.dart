import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'workout_file_stub.dart' if (dart.library.io) 'workout_file_io.dart'
    as platform;

Future<bool> saveWorkoutJson(String filename, Map<String, dynamic> data) async {
  final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
  final mobile = !kIsWeb &&
      {TargetPlatform.android, TargetPlatform.iOS}
          .contains(defaultTargetPlatform);
  final path = await FilePicker.platform.saveFile(
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: kIsWeb || mobile ? bytes : null);
  if (kIsWeb) {
    return true; // The web picker initiates a download and returns no path.
  }
  if (path == null) return false;
  if (!mobile) await platform.writeWorkoutFile(path, bytes);
  return true;
}
