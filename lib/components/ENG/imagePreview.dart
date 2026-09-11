import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const ImagePreview({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Hero(
            tag: tag,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}
