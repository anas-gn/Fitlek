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
  /// Strava-inspired: full-bleed meal photo with brand logo and stats HUD overlaid directly on top.
  stravaOverlay,

  /// Structured dark card layout with photo and stats in dedicated sections.
  classicCard,
}

/// A visually striking, Strava-inspired marketing share card for meals scanned or logged in SIRVYA.
class MealShareCard extends StatelessWidget {
  final ScannedMeal meal;
  final MealShareFormat format;
  final MealShareStyle style;

  const MealShareCard({
    super.key,
    required this.meal,
    this.format = MealShareFormat.story,
    this.style = MealShareStyle.stravaOverlay,
  });

  bool get isStory => format == MealShareFormat.story;
  bool get isStrava => style == MealShareStyle.stravaOverlay;

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
            color: mealLime.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: isStrava
            ? _buildStravaLayout(calories, protein, carbs, fat)
            : _buildClassicCardLayout(calories, protein, carbs, fat),
      ),
    );
  }

  // ===========================================================================
  // 1. STRAVA PHOTO OVERLAY STYLE (Full-Bleed Photo + Floating HUD)
  // ===========================================================================
  Widget _buildStravaLayout(
      int calories, int protein, int carbs, int fat) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-bleed Photo Background
        _buildPhotoBackground(),

        // 2. Top Vignette Gradient (for header contrast)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: isStory ? 170 : 120,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  Color(0xD9000000), // ~85% black
                  Color(0x66000000), // ~40% black
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 3. Bottom Vignette Gradient (for stats and info contrast)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: isStory ? 340 : 250,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: [0.0, 0.5, 0.85, 1.0],
                colors: [
                  Color(0xF2000000), // 95% black
                  Color(0xB3000000), // 70% black
                  Color(0x40000000), // 25% black
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // 4. Content Elements Layered on Top of the Image
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: isStory ? 18 : 14,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Strava Header: Sirvya Logo & Badge
              _buildStravaTopHeader(),

              const Spacer(),

              // Bottom Strava HUD: Meal Name + Macro Stats + Watermark Footer
              _buildStravaBottomHUD(calories, protein, carbs, fat),
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

  Widget _buildStravaTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Official SIRVYA Wordmark with drop shadow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: const SirvyaLogo(
            variant: SirvyaLogoVariant.wordmark,
            height: 20,
            color: Colors.white,
          ),
        ),

        // Glowing "AI MEAL SCAN" badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: mealLime.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: mealLime.withValues(alpha: 0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: mealLime,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                'AI MEAL SCAN',
                style: TextStyle(
                  color: mealLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStravaBottomHUD(
      int calories, int protein, int carbs, int fat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Meal Category & Time Pill
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: mealLime.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: mealLime.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restaurant_rounded,
                      color: mealLime, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    meal.mealType.toUpperCase(),
                    style: const TextStyle(
                      color: mealLime,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${meal.portion == 1 ? '1 plate' : '${meal.portion} plates'} · Verified Nutrition',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // Meal Title
        Text(
          meal.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isStory ? 20 : 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            height: 1.15,
            shadows: const [
              Shadow(
                color: Colors.black87,
                offset: Offset(0, 1.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Strava-style HUD Stats Box
        _buildStravaStatsBox(calories, protein, carbs, fat),

        // Top ingredients tags (in Story format only)
        if (isStory && meal.ingredients.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildStravaIngredientsList(),
        ],

        const SizedBox(height: 10),

        // Marketing Watermark Footer
        _buildMarketingFooter(isStrava: true),
      ],
    );
  }

  Widget _buildStravaStatsBox(
      int calories, int protein, int carbs, int fat) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isStory ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC051814), // Frosted dark emerald HUD
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 4 Strava Stats in a row with vertical dividers
          Row(
            children: [
              _buildStravaStatItem(
                label: 'ENERGY',
                value: '$calories',
                unit: 'kcal',
                color: mealLime,
              ),
              _buildVerticalDivider(),
              _buildStravaStatItem(
                label: 'PROTEIN',
                value: '${protein}g',
                unit: '',
                color: mealProtein,
              ),
              _buildVerticalDivider(),
              _buildStravaStatItem(
                label: 'CARBS',
                value: '${carbs}g',
                unit: '',
                color: mealCarbs,
              ),
              _buildVerticalDivider(),
              _buildStravaStatItem(
                label: 'FAT',
                value: '${fat}g',
                unit: '',
                color: mealFat,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Proportional macro bar
          _buildMacroDistributionBar(protein, carbs, fat),
        ],
      ),
    );
  }

  Widget _buildStravaStatItem({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0CCC6),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  Widget _buildStravaIngredientsList() {
    final topIngredients = meal.ingredients.take(3).toList();
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: topIngredients.map((i) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.6,
            ),
          ),
          child: Text(
            '${i.name} (${i.grams.round()}g)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.w500,
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
          vertical: isStory ? 16 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildClassicHeader(),
            SizedBox(height: isStory ? 10 : 8),
            _buildClassicPhoto(),
            SizedBox(height: isStory ? 10 : 8),
            _buildClassicTitle(),
            SizedBox(height: isStory ? 8 : 6),
            _buildClassicNutrition(calories, protein, carbs, fat),
            if (isStory && meal.ingredients.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildClassicIngredientsList(),
            ],
            const Spacer(),
            _buildMarketingFooter(isStrava: false),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SirvyaLogo(
          variant: SirvyaLogoVariant.wordmark,
          height: 20,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: mealLime.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: mealLime.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: mealLime, size: 12),
              SizedBox(width: 4),
              Text(
                'AI MEAL SCAN',
                style: TextStyle(
                  color: mealLime,
                  fontWeight: FontWeight.w800,
                  fontSize: 9.5,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassicPhoto() {
    final double photoHeight = isStory ? 145 : 100;
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
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0x99031914),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: mealLime.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_rounded,
                        color: mealLime, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      meal.mealType.toUpperCase(),
                      style: const TextStyle(
                        color: mealCream,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meal.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: mealCream,
            fontSize: isStory ? 18 : 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${meal.portion == 1 ? '1 plate' : '${meal.portion} plates'} · Verified Nutrition with Sirvya AI',
          style: const TextStyle(
            color: mealMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildClassicNutrition(
      int calories, int protein, int carbs, int fat) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isStory ? 10 : 8,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: mealLime, size: 18),
                  SizedBox(width: 7),
                  Text(
                    'ENERGY',
                    style: TextStyle(
                      color: mealMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$calories',
                    style: const TextStyle(
                      color: mealCream,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('kcal',
                      style: TextStyle(
                          color: mealLime,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMacroPill('Protein', '${protein}g', mealProtein),
              const SizedBox(width: 6),
              _buildMacroPill('Carbs', '${carbs}g', mealCarbs),
              const SizedBox(width: 6),
              _buildMacroPill('Fat', '${fat}g', mealFat),
            ],
          ),
          const SizedBox(height: 7),
          _buildMacroDistributionBar(protein, carbs, fat),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String name, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF061E18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: mealMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicIngredientsList() {
    final topIngredients = meal.ingredients.take(3).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: topIngredients.map((i) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: mealCream.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${i.name} (${i.grams.round()}g)',
            style: const TextStyle(
              color: mealMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // COMMON HELPERS
  // ===========================================================================
  Widget _buildMacroDistributionBar(int protein, int carbs, int fat) {
    final double pCal = protein * 4.0;
    final double cCal = carbs * 4.0;
    final double fCal = fat * 9.0;
    final double totalCal = pCal + cCal + fCal;

    if (totalCal <= 0) return const SizedBox.shrink();

    final int pFlex = (pCal / totalCal * 100).round().clamp(1, 100);
    final int cFlex = (cCal / totalCal * 100).round().clamp(1, 100);
    final int fFlex = (fCal / totalCal * 100).round().clamp(1, 100);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 4.5,
        child: Row(
          children: [
            Expanded(flex: pFlex, child: Container(color: mealProtein)),
            const SizedBox(width: 1),
            Expanded(flex: cFlex, child: Container(color: mealCarbs)),
            const SizedBox(width: 1),
            Expanded(flex: fFlex, child: Container(color: mealFat)),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketingFooter({required bool isStrava}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isStory ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: isStrava
            ? Colors.black.withValues(alpha: 0.55)
            : const Color(0xFF031612).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mealLime.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const SirvyaLogo(
            variant: SirvyaLogoVariant.mark,
            height: 22,
            color: mealLime,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Track meals & crush goals',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  'Personal Coaching · sirvya.com',
                  style: TextStyle(
                    color: mealLime.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
            decoration: BoxDecoration(
              color: mealLime,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'GET SIRVYA',
              style: TextStyle(
                color: Color(0xFF031914),
                fontWeight: FontWeight.w900,
                fontSize: 8.5,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
