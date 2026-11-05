import 'package:flutter/material.dart';
import '../services/meal_scan_service.dart';
import '../services/meal_share_service.dart';
import 'meal_share_card.dart';
import 'meal_visuals.dart';

/// Shows the meal sharing modal sheet with live interactive preview and story/post formats.
Future<void> showMealShareModal(BuildContext context, ScannedMeal meal) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: mealInk,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => MealShareSheet(meal: meal),
  );
}

class MealShareSheet extends StatefulWidget {
  final ScannedMeal meal;

  const MealShareSheet({super.key, required this.meal});

  @override
  State<MealShareSheet> createState() => _MealShareSheetState();
}

class _MealShareSheetState extends State<MealShareSheet> {
  final GlobalKey _boundaryKey = GlobalKey();
  MealShareFormat _format = MealShareFormat.story;
  bool _sharing = false;

  ScannedMeal get meal => widget.meal;

  Future<void> _handleShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    try {
      await MealShareService.shareMeal(
        context: context,
        boundaryKey: _boundaryKey,
        meal: meal,
        format: _format,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStory = _format == MealShareFormat.story;
    final cardAspectRatio = isStory ? (360 / 640) : (360 / 450);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Grab bar handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: mealMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 2. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Your Meal',
                          style: TextStyle(
                            color: mealCream,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Post on Instagram, WhatsApp, or Facebook',
                          style: TextStyle(
                            color: mealMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mealSurface.withValues(alpha: 0.6),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: mealMuted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Format Switcher Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: mealSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: mealLime.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFormatTab(
                        title: 'Story (9:16)',
                        icon: Icons.stay_current_portrait_rounded,
                        selected: isStory,
                        onTap: () => setState(
                            () => _format = MealShareFormat.story),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildFormatTab(
                        title: 'Post Card',
                        icon: Icons.crop_square_rounded,
                        selected: !isStory,
                        onTap: () =>
                            setState(() => _format = MealShareFormat.post),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Live Interactive Preview with RepaintBoundary
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: isStory ? 360 : 300,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: cardAspectRatio,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: MealShareCard(
                          meal: meal,
                          format: _format,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 5. Primary Share Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _sharing ? null : _handleShare,
                  style: FilledButton.styleFrom(
                    backgroundColor: mealLime,
                    foregroundColor: const Color(0xFF031914),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _sharing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF031914),
                          ),
                        )
                      : const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_rounded, size: 19),
                              SizedBox(width: 8),
                              Text(
                                'Share Story / Post',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // 6. Secondary Options Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          MealShareService.copyCaption(context, meal),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mealCream,
                        side: BorderSide(
                          color: mealCream.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Copy Caption & Link',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatTab({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? mealLime : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? const Color(0xFF031914) : mealMuted,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  color: selected ? const Color(0xFF031914) : mealMuted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
