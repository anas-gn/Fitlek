import 'package:flutter/material.dart';
import '../services/meal_scan_service.dart';
import 'meal_visuals.dart';
import 'sirvya_logo.dart';

/// Presentation format for sharing a meal.
enum MealShareFormat {
  /// Vertical 9:16 layout optimized for Instagram Stories, WhatsApp Status, and Facebook Stories.
  story,

  /// Portrait 4:5 layout optimized for feed posts, messages, and social timelines.
  post,
}

/// Visual presentation style for the meal share graphic.
enum MealShareStyle {
  /// Sirvya photo overlay: full-bleed native meal photo with brand logo and stats HUD overlaid directly on top.
  sirvyaOverlay,

  /// Structured dark card layout with photo and stats in dedicated sections.
  classicCard;

  /// Backwards compatibility alias
  static const MealShareStyle stravaOverlay = sirvyaOverlay;
}

/// A visually striking marketing share card for meals scanned or logged in SIRVYA.
class MealShareCard extends StatelessWidget {
  final ScannedMeal meal;
  final MealShareFormat format;
  final MealShareStyle style;
  final bool showIngredients;

  const MealShareCard({
    super.key,
    required this.meal,
    this.format = MealShareFormat.story,
    this.style = MealShareStyle.sirvyaOverlay,
    this.showIngredients = false,
  });

  bool get isStory => format == MealShareFormat.story;
  bool get isSirvyaOverlay =>
      style == MealShareStyle.sirvyaOverlay ||
      style == MealShareStyle.stravaOverlay;

  @override
  Widget build(BuildContext context) {
    final calories = meal.total('calories').round();
    final protein = meal.total('protein').round();
    final carbs = meal.total('carbs').round();
    final fat = meal.total('fat').round();

    // 360 x 640 is standard 9:16 story ratio; 360 x 450 is standard 4:5 feed post ratio
    final double cardWidth = 360;
    final double cardHeight = isStory ? 640 : 450;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: isSirvyaOverlay
            ? _buildSirvyaLayout(calories, protein, carbs, fat)
            : _buildClassicCardLayout(calories, protein, carbs, fat),
      ),
    );
  }

  // ===========================================================================
  // 1. SIRVYA PHOTO OVERLAY STYLE (Full-Bleed Native Photo + Pure White HUD)
  // ===========================================================================
  Widget _buildSirvyaLayout(
      int calories, int protein, int carbs, int fat) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-bleed Native Photo Background (food photo extends edge-to-edge)
        _buildPhotoBackground(),

        // 2. Top Vignette Gradient (pure neutral black fade for logo contrast)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: isStory ? 140 : 100,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.6, 1.0],
                colors: [
                  Color(0xB3000000), // 70% black at top
                  Color(0x40000000), // 25% black
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Bottom Vignette Gradient (pure neutral black fade directly behind text)
        // No green tint, letting the native photo remain visible underneath!
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: isStory ? 320 : 230,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.45, 0.8, 1.0],
                colors: [
                  Color(0xCC000000), // 80% black at very bottom
                  Color(0x99000000), // 60% black behind stats
                  Color(0x33000000), // 20% black
                  Colors.transparent, // transparent so native food photo is visible
                ],
              ),
            ),
          ),
        ),

        // 4. Content Elements Layered Directly on Top of the Native Image
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: isStory ? 22 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean Centered Logo using logo_dark.png
              _buildCleanTopLogo(),

              const Spacer(),

              // Bottom Stats & Meal Details in pure white directly on top of image
              _buildSirvyaBottomHUD(calories, protein, carbs, fat),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoBackground() {
    final bool hasValidPhoto =
        (meal.photoBytes != null && meal.photoBytes!.isNotEmpty) ||
            (meal.photoPath.isNotEmpty &&
                !meal.photoPath.startsWith('/missing'));

    if (hasValidPhoto) {
      return MealPhoto(
        path: meal.photoPath,
        bytes: meal.photoBytes,
        fit: BoxFit.cover,
      );
    }

    // High-end fallback if no photo is available
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF041914),
            Color(0xFF07261F),
            Color(0xFF0C382E),
            Color(0xFF041813),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 80,
          color: mealLime.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  /// Clean centered SIRVYA logo using `assets/branding/logo_dark.png`,
  /// without any outline box or "AI MEAL SCAN" badge.
  Widget _buildCleanTopLogo() {
    final double logoHeight = isStory ? 28 : 22;
    return Center(
      child: Image.asset(
        'assets/branding/logo_dark.png',
        height: logoHeight,
        fit: BoxFit.contain,
        semanticLabel: 'SIRVYA',
        errorBuilder: (context, error, stackTrace) => const SirvyaLogo(
          variant: SirvyaLogoVariant.wordmark,
          height: 24,
        ),
      ),
    );
  }

  Widget _buildSirvyaBottomHUD(
      int calories, int protein, int carbs, int fat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Meal Title in Pure White with soft shadow
        Text(
          meal.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isStory ? 23 : 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            height: 1.15,
            shadows: const [
              Shadow(
                color: Colors.black,
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
        ),

        // Optional Ingredients Pills (only if toggled on)
        if (showIngredients && meal.ingredients.isNotEmpty) ...[
          SizedBox(height: isStory ? 10 : 6),
          _buildIngredientsChips(),
        ],

        SizedBox(height: isStory ? 18 : 12),

        // 4-Column Stats Row - All in Pure White
        Row(
          children: [
            // 1. Calories (Pure White)
            Expanded(
              child: _buildStatColumn(
                icon: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 21,
                ),
                label: 'Calories',
                value: '$calories',
                subUnit: 'kcal',
              ),
            ),
            _buildVerticalDivider(),
            // 2. Protein (Pure White)
            Expanded(
              child: _buildStatColumn(
                icon: const MuscleBicepIcon(size: 20, color: Colors.white),
                label: 'Protein',
                value: '${protein}g',
              ),
            ),
            _buildVerticalDivider(),
            // 3. Carbs (Pure White)
            Expanded(
              child: _buildStatColumn(
                icon: const WheatGrainIcon(size: 20, color: Colors.white),
                label: 'Carbs',
                value: '${carbs}g',
              ),
            ),
            _buildVerticalDivider(),
            // 4. Fat (Pure White)
            Expanded(
              child: _buildStatColumn(
                icon: const Icon(
                  Icons.water_drop_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                label: 'Fat',
                value: '${fat}g',
              ),
            ),
          ],
        ),

        SizedBox(height: isStory ? 24 : 14),
      ],
    );
  }

  Widget _buildStatColumn({
    required Widget icon,
    required String label,
    required String value,
    String? subUnit,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 22,
          child: Center(child: icon),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: isStory ? 10.5 : 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            shadows: const [
              Shadow(color: Colors.black87, blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isStory ? 22 : 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
        if (subUnit != null) ...[
          const SizedBox(height: 2),
          Text(
            subUnit,
            style: TextStyle(
              color: Colors.white,
              fontSize: isStory ? 11 : 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ] else
          SizedBox(height: isStory ? 15 : 12),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withValues(alpha: 0.25),
    );
  }

  Widget _buildIngredientsChips() {
    final items = meal.ingredients.take(4).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: items.map((i) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 0.8,
            ),
          ),
          child: Text(
            '${i.name} (${i.grams.round()}g)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // 2. CLASSIC CARD STYLE
  // ===========================================================================
  Widget _buildClassicCardLayout(
      int calories, int protein, int carbs, int fat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF031914),
            Color(0xFF07261F),
            Color(0xFF0C382E),
            Color(0xFF041813),
          ],
        ),
        border: Border.all(
          color: mealLime.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: isStory ? 20 : 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCleanTopLogo(),
            SizedBox(height: isStory ? 14 : 10),
            _buildClassicPhoto(),
            SizedBox(height: isStory ? 12 : 8),
            _buildClassicTitle(),
            SizedBox(height: isStory ? 12 : 8),
            _buildClassicNutrition(calories, protein, carbs, fat),
            if (showIngredients && meal.ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildIngredientsChips(),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicPhoto() {
    final double photoHeight = isStory ? 160 : 110;
    return Container(
      height: photoHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mealCream.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MealPhoto(
              path: meal.photoPath,
              bytes: meal.photoBytes,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicTitle() {
    return Text(
      meal.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: mealCream,
        fontSize: isStory ? 19 : 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.15,
      ),
    );
  }

  Widget _buildClassicNutrition(
      int calories, int protein, int carbs, int fat) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isStory ? 12 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2F27).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mealLime.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  icon: const Icon(Icons.local_fire_department_rounded,
                      color: Colors.white, size: 20),
                  label: 'Calories',
                  value: '$calories',
                  subUnit: 'kcal',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatColumn(
                  icon: const MuscleBicepIcon(size: 19, color: Colors.white),
                  label: 'Protein',
                  value: '${protein}g',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatColumn(
                  icon: const WheatGrainIcon(size: 19, color: Colors.white),
                  label: 'Carbs',
                  value: '${carbs}g',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatColumn(
                  icon: const Icon(Icons.water_drop_outlined,
                      color: Colors.white, size: 19),
                  label: 'Fat',
                  value: '${fat}g',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vector outline of a flexed bicep / muscle for Protein metrics.
class MuscleBicepIcon extends StatelessWidget {
  final double size;
  final Color color;

  const MuscleBicepIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MuscleBicepPainter(color: color),
    );
  }
}

class _MuscleBicepPainter extends CustomPainter {
  final Color color;

  const _MuscleBicepPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.72, h * 0.85);
    path.quadraticBezierTo(w * 0.35, h * 0.82, w * 0.22, h * 0.65);
    path.quadraticBezierTo(w * 0.15, h * 0.45, w * 0.28, h * 0.22);
    path.quadraticBezierTo(w * 0.38, h * 0.15, w * 0.48, h * 0.20);
    path.quadraticBezierTo(w * 0.46, h * 0.32, w * 0.42, h * 0.40);
    path.quadraticBezierTo(w * 0.52, h * 0.34, w * 0.64, h * 0.46);
    path.quadraticBezierTo(w * 0.76, h * 0.60, w * 0.72, h * 0.85);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MuscleBicepPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Vector outline of wheat / grain for Carbs metrics.
class WheatGrainIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WheatGrainIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WheatGrainPainter(color: color),
    );
  }
}

class _WheatGrainPainter extends CustomPainter {
  final Color color;

  const _WheatGrainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final stalk = Path();
    stalk.moveTo(w * 0.38, h * 0.90);
    stalk.quadraticBezierTo(w * 0.48, h * 0.55, w * 0.54, h * 0.15);
    canvas.drawPath(stalk, paint);

    void drawGrain(double cx, double cy, double rx, double ry, double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        Radius.circular(rx),
      );
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }

    drawGrain(w * 0.54, h * 0.20, w * 0.10, h * 0.13, 0.2);
    drawGrain(w * 0.40, h * 0.34, w * 0.11, h * 0.14, -0.6);
    drawGrain(w * 0.68, h * 0.38, w * 0.11, h * 0.14, 0.7);
    drawGrain(w * 0.35, h * 0.54, w * 0.12, h * 0.15, -0.65);
    drawGrain(w * 0.63, h * 0.58, w * 0.12, h * 0.15, 0.75);
    drawGrain(w * 0.32, h * 0.74, w * 0.11, h * 0.14, -0.7);
  }

  @override
  bool shouldRepaint(covariant _WheatGrainPainter oldDelegate) =>
      oldDelegate.color != color;
}
