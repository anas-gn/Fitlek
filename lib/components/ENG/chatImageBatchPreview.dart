import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<String?> previewChatImages(BuildContext context, List<XFile> files) =>
    showDialog<String>(
        context: context, builder: (_) => _BatchPreview(files: files));

class _BatchPreview extends StatefulWidget {
  final List<XFile> files;
  const _BatchPreview({required this.files});
  @override
  State<_BatchPreview> createState() => _BatchPreviewState();
}

class _BatchPreviewState extends State<_BatchPreview> {
  final caption = TextEditingController();
  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final files = widget.files;
    return AlertDialog(
        title: Text('Send ${files.length} photos'),
        content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  height: 220,
                  child: GridView.builder(
                      itemCount: files.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6),
                      itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(files[i].path, fit: BoxFit.cover)
                              : Image.file(File(files[i].path),
                                  fit: BoxFit.cover)))),
              TextField(
                  controller: caption,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                      hintText: 'Caption for the first photo (optional)'))
            ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, caption.text.trim()),
              child: Text('Send ${files.length} photos'))
        ]);
  }
}
