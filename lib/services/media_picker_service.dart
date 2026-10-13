import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AppMediaPicker {
  final BuildContext context;
  final ImagePicker _picker = ImagePicker();
  AppMediaPicker(this.context);
  void _showError(PlatformException error) {
    if (!context.mounted) return;
    final denied =
        error.code.contains('denied') || error.code.contains('restricted');
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(denied
            ? 'Allow camera or photo access for Sirvya in your phone Settings, then try again.'
            : 'Could not open this photo. Please try again.')));
  }

  Future<XFile?> pickImage(
      {required ImageSource source,
      double? maxWidth,
      double? maxHeight,
      int? imageQuality}) async {
    try {
      return await _picker.pickImage(
          source: source,
          maxWidth: maxWidth ?? 1600,
          maxHeight: maxHeight ?? 1600,
          imageQuality: imageQuality ?? 85,
          requestFullMetadata: false);
    } on PlatformException catch (error) {
      _showError(error);
      return null;
    }
  }

  Future<List<XFile>> pickMultiImage(
      {double? maxWidth, double? maxHeight, int? imageQuality}) async {
    try {
      return await _picker.pickMultiImage(
          maxWidth: maxWidth ?? 1600,
          maxHeight: maxHeight ?? 1600,
          imageQuality: imageQuality ?? 85,
          requestFullMetadata: false);
    } on PlatformException catch (error) {
      _showError(error);
      return [];
    }
  }
}
