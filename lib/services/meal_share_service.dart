import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../components/meal_share_card.dart';
import 'meal_scan_service.dart';

class MealShareService {
  /// Generates attractive marketing caption for social media and messaging apps.
  static String generateMarketingCaption(ScannedMeal meal) {
    final cal = meal.total('calories').round();
    final p = meal.total('protein').round();
    final c = meal.total('carbs').round();
    final f = meal.total('fat').round();

    return '🥗 Just tracked my meal with SIRVYA AI!\n'
        '🍽️ ${meal.name}\n'
        '🔥 $cal kcal · 🥩 ${p}g Protein · 🍚 ${c}g Carbs · 🥑 ${f}g Fat\n\n'
        'Scan meals, track your macros & reach your fitness goals with elite coaches on SIRVYA! 💪✨\n'
        '📲 Download SIRVYA: https://sirvya.com\n'
        '#SIRVYA #Fitness #Nutrition #MealScan #HealthyEating #Coach';
  }

  /// Captures a widget wrapped in a [RepaintBoundary] as high-resolution PNG bytes.
  static Future<Uint8List?> captureWidget(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[MealShareService] Error capturing widget to image: $e');
      return null;
    }
  }

  /// Shares the meal story or post image along with the marketing caption to
  /// Instagram, WhatsApp, Facebook, TikTok, or other sharing targets.
  static Future<bool> shareMeal({
    required BuildContext context,
    required GlobalKey boundaryKey,
    required ScannedMeal meal,
    required MealShareFormat format,
    MealShareStyle style = MealShareStyle.stravaOverlay,
  }) async {
    final caption = generateMarketingCaption(meal);

    try {
      final bytes = await captureWidget(boundaryKey);

      if (bytes != null && !kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final filename =
            'sirvya_meal_${format.name}_${style.name}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);

        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: caption,
            subject: 'Tracked with SIRVYA: ${meal.name}',
          ),
        );
        return result.status == ShareResultStatus.success;
      } else {
        // Fallback to text sharing when image cannot be written or on web
        final result = await SharePlus.instance.share(
          ShareParams(
            text: caption,
            subject: 'Tracked with SIRVYA: ${meal.name}',
          ),
        );
        return result.status == ShareResultStatus.success;
      }
    } catch (e) {
      debugPrint('[MealShareService] Error sharing meal: $e');
      // If native sharing fails, offer to copy text
      if (context.mounted) {
        await Clipboard.setData(ClipboardData(text: caption));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Meal summary copied to clipboard! You can paste it into WhatsApp or Instagram.',
            ),
          ),
        );
      }
      return false;
    }
  }

  /// Copies the meal summary & Sirvya marketing link to the device clipboard.
  static Future<void> copyCaption(BuildContext context, ScannedMeal meal) async {
    final caption = generateMarketingCaption(meal);
    await Clipboard.setData(ClipboardData(text: caption));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal caption & SIRVYA link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

