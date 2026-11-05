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

/// A visually striking, marketing-focused share card for meals scanned or logged in SIRVYA.
class MealShareCard extends StatelessWidget {
  final ScannedMeal meal;
  final MealShareFormat format;

  const MealShareCard({
    super.key,
    required this.meal,
    this.format = MealShareFormat.story,
  });

  bool get isStory => format == MealShareFormat.story;

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF031914),
            Color(0xFF07261F),
            Color(0xFF0C382E),
            Color(0xFF041813),
          ],
          stops: [0.0, 0.35, 0.75, 1.0],
        ),
        border: Border.all(
          color: mealLime.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: mealLime.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Ambient glowing gradient circles in corners
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mealLime.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mealProtein.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: isStory ? 16 : 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header with Sirvya Logo and AI Badge
                  _buildHeader(),

                  SizedBox(height: isStory ? 10 : 8),

                  // 2. Meal Photo with Overlay Badge
                  _buildMealPhoto(),

                  SizedBox(height: isStory ? 10 : 8),

                  // 3. Meal Title & Serving Info
                  _buildTitle(),

                  SizedBox(height: isStory ? 8 : 6),

                  // 4. Energy & Macros Dashboard
                  _buildNutritionDashboard(calories, protein, carbs, fat),

                  // 5. Ingredients preview (in story format only)
                  if (isStory && meal.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildIngredientsList(),
                  ],

                  const Spacer(),

                  // 6. Sirvya Marketing Footer
                  _buildMarketingFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Official SIRVYA Wordmark
        const SirvyaLogo(
          variant: SirvyaLogoVariant.wordmark,
          height: 20,
        ),

        // Glowing "AI MEAL SCAN" badge
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
              Icon(
                Icons.auto_awesome_rounded,
                color: mealLime,
                size: 12,
              ),
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

  Widget _buildMealPhoto() {
    final double photoHeight = isStory ? 145 : 100;

    return Container(
      height: photoHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mealCream.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
            // Bottom gradient overlay for tag readability
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            // Bottom tag inside photo
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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

  Widget _buildTitle() {
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

  Widget _buildNutritionDashboard(
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
          // Total Calories Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: mealLime.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: mealLime,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
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
                  const Text(
                    'kcal',
                    style: TextStyle(
                      color: mealLime,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 3 Macros Pills
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

          // Macro Distribution Bar
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
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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

  Widget _buildIngredientsList() {
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

  Widget _buildMarketingFooter() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isStory ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF031612).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mealLime.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Sirvya "S" Mark
          const SirvyaLogo(
            variant: SirvyaLogoVariant.mark,
            height: 24,
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
                    color: mealCream,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                  ),
                ),
                Text(
                  'Personal Coaching · sirvya.com',
                  style: TextStyle(
                    color: mealLime.withValues(alpha: 0.9),
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
