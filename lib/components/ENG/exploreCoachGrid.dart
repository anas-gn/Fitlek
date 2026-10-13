import 'package:flutter/material.dart';
import '../../models/anas/coach.dart';
import '../../constants/urls.dart';
import '../../theme/fitlek_theme_extension.dart';

class ExploreCoachGrid extends StatelessWidget {
  final List<CoachModel> coaches;
  final Set<int> favorites;
  final Map<int, double> ratings;
  final Map<int, int> reviewCounts;
  final ValueChanged<CoachModel> onOpen;
  final ValueChanged<int> onFavorite;
  const ExploreCoachGrid(
      {super.key,
      required this.coaches,
      required this.favorites,
      required this.ratings,
      required this.reviewCounts,
      required this.onOpen,
      required this.onFavorite});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth - 40;
        final columns = width < 320
            ? 1
            : width < 660
                ? 2
                : width < 960
                    ? 3
                    : 4;
        return GridView.builder(
            key: const PageStorageKey('explore-coach-grid'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 320 +
                    (MediaQuery.textScalerOf(context).scale(14) - 14)
                            .clamp(0, 40) *
                        5),
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              final coach = coaches[index];
              final f = context.fitlek;
              final image = coach.avatarUrl?.trim() ?? '';
              final url = image.isEmpty
                  ? ''
                  : Uri.parse(baseUrl.replaceFirst(RegExp(r'/api/?$'), '/'))
                      .resolve(image)
                      .toString();
              final reviews = reviewCounts[coach.id] ?? 0;
              Widget placeholder() => ColoredBox(
                  color: f.card2,
                  child: Center(
                      child: Icon(Icons.person_rounded,
                          size: 48, color: f.textMuted)));
              return Material(
                key: ValueKey(coach.id),
                color: f.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: f.border)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                    onTap: () => onOpen(coach),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Stack(fit: StackFit.expand, children: [
                            url.isEmpty
                                ? placeholder()
                                : Image.network(url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        placeholder()),
                            Positioned(
                                top: 6,
                                right: 6,
                                child: IconButton.filledTonal(
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF3F1E8),
                                      foregroundColor: const Color(0xFF123E35),
                                      fixedSize: const Size(40, 40),
                                      side: const BorderSide(
                                          color: Color(0x26000000)),
                                    ),
                                    tooltip: favorites.contains(coach.id)
                                        ? 'Remove from favorites'
                                        : 'Add to favorites',
                                    onPressed: () => onFavorite(coach.id),
                                    icon: Icon(
                                        favorites.contains(coach.id)
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: favorites.contains(coach.id)
                                            ? Colors.redAccent
                                            : const Color(0xFF123E35)))),
                            if (coach.isPremium)
                              Positioned(
                                  top: 12,
                                  left: 10,
                                  child: Icon(Icons.workspace_premium_rounded,
                                      color: f.premium, size: 22)),
                          ])),
                          Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Text(coach.fullName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14))),
                                      if (coach.isApproved)
                                        const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(Icons.verified_rounded,
                                                color: Color(0xFF38BDF8),
                                                size: 14))
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(coach.displaySpecialties,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: f.textMuted, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Icon(Icons.star_rounded,
                                          size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 3),
                                      Expanded(
                                          child: Text(
                                              reviews > 0
                                                  ? '${(ratings[coach.id] ?? 0).toStringAsFixed(1)} ($reviews)'
                                                  : 'New',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12)))
                                    ]),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 13, color: f.textMuted),
                                      const SizedBox(width: 3),
                                      Expanded(
                                          child: Text(
                                              coach.locationLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: f.textMuted,
                                                  fontSize: 12)))
                                    ]),
                                    const SizedBox(height: 8),
                                    Text(
                                        coach.minPrice != null
                                            ? 'From ${coach.minPrice!.toInt()} MAD'
                                            : 'Price on request',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () => onOpen(coach),
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFF3F1E8),
                                          foregroundColor:
                                              const Color(0xFF064B43),
                                          minimumSize: const Size(0, 38),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(11)),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                                child: Text('View & Book',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w800))),
                                            SizedBox(width: 6),
                                            Icon(Icons.arrow_forward_rounded,
                                                size: 15),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ])),
                        ])),
              );
            });
      });
}
