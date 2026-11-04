import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Category artwork selected in the admin and bundled for offline use.
class CategoryIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const CategoryIcon({super.key, required this.name, this.size = 24, this.color});

  static const ids = {'28674', '62507', '287251', '256487', '134094', '43736', '58256', '146702', '194845', '390355', '486339', '256526', '72668', '119268', '521869', '453249', '414960', '168726', '76841', '61052', '54794', '128097', '414963', '414962', '444087', '71882', '425109', '334287', '62317', '58821', '189870', '472666', '524631', '19832', '170188', '68406', '40273', '528710'};
  static const legacy = {
    'fitness_center': '28674', 'accessibility_new': '287251',
    'sports_gymnastics': '62507', 'sports_mma': '486339',
    'sports_martial_arts': '486339', 'self_improvement': '194845',
    'restaurant': '43736', 'nutrition': '43736',
    'directions_run': '390355', 'directions_walk': '146702',
    'monitor_weight': '58256', 'straighten': '146702',
  };
  static String? assetFor(String name) {
    final id = name.startsWith('svgrepo:') ? name.substring(8) : legacy[name];
    return ids.contains(id) ? 'assets/category_icons/$id.svg' : null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(name);
    final tint = color ?? Theme.of(context).colorScheme.onSurface;
    final fallback = Icon(Icons.fitness_center_outlined, size: size, color: tint);
    if (asset == null) return fallback;
    return SvgPicture.asset(asset, width: size, height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      excludeFromSemantics: true,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
      errorBuilder: (_, __, ___) => fallback);
  }
}
