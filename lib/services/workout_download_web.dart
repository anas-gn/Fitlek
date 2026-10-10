import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<void> downloadWorkoutJsonFile(String filename, Uint8List bytes) async {
  final blob = web.Blob(
      <JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/json'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // Allow the browser to open the asynchronous download before releasing it.
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}
