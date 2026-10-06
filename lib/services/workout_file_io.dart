import 'dart:io';
import 'dart:typed_data';

Future<void> writeWorkoutFile(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}
