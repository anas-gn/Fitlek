import 'dart:convert';
import '../../services/live_updates.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/models/anas/review.dart';
import '../../theme/fitlek_theme_extension.dart';

class ClientCoachReviewsScreen extends StatefulWidget {
  final bool coachView;
  final int coachID;
  final String coachName;
  final int clientID;
  final String token;
  final List<ReviewItem>? initialReviews;
  final double? initialAvgRating;
  final int? initialTotalReviews;

  const ClientCoachReviewsScreen({
    super.key,
    this.coachView = false,
    required this.coachID,
    required this.coachName,
    required this.clientID,
    required this.token,
    this.initialReviews,
    this.initialAvgRating,
    this.initialTotalReviews,
  });

  @override
  State<ClientCoachReviewsScreen> createState() =>
      _ClientCoachReviewsScreenState();
}

class _ClientCoachReviewsScreenState extends State<ClientCoachReviewsScreen>
    with LiveUpdates<ClientCoachReviewsScreen> {
  @override
  Set<String> get liveDomains => {'reviews', 'notifications'};
  @override
  Future<void> refreshLiveData() => _fetchReviews();
  late List<ReviewItem> _reviews;
  late double _avgRating;
  late int _totalReviews;
  bool _loading = false;
  String? _error;
  int? _selectedStarFilter; // null means 'All'

  @override
  void initState() {
    super.initState();
    _reviews =
        widget.initialReviews != null ? List.from(widget.initialReviews!) : [];
    _avgRating = widget.initialAvgRating ?? 0.0;
    _totalReviews = widget.initialTotalReviews ?? _reviews.length;

    if (_reviews.isEmpty) {
      _fetchReviews();
    }
  }

  Future<void> _fetchReviews() async {
    if (!mounted || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/reviews/coach/${widget.coachID}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (!mounted) return;
        final list = (data['reviews'] as List)
            .map((e) => ReviewItem.fromJson(e))
            .toList();
        setState(() {
          _reviews = list;
          _avgRating = (data['avg'] as num?)?.toDouble() ?? 0.0;
          _totalReviews = (data['total'] as int?) ?? list.length;
          _loading = false;
        });
      } else {
        if (mounted)
          setState(() {
            _loading = false;
            _error = 'Could not load feedback. Pull down to retry.';
          });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not load feedback. Pull down to retry.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;

    // Calculate rating counts for distribution (1 to 5)
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in _reviews) {
      final rating = r.rating.clamp(1, 5);
      counts[rating] = (counts[rating] ?? 0) + 1;
    }

    final filteredReviews = _selectedStarFilter == null
        ? _reviews
        : _reviews.where((r) => r.rating == _selectedStarFilter).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.coachView ? 'My feedback' : 'Reviews & Ratings',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            if (widget.coachName.isNotEmpty)
              Text(
                widget.coachName,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontSize: 12),
              ),
          ],
        ),
      ),
      body: _loading && _reviews.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary))
          : RefreshIndicator(
              onRefresh: _fetchReviews,
              color: Theme.of(context).colorScheme.primary,
              child: ListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child:
                            Text(_error!, style: TextStyle(color: cs.error))),
                  // Rating breakdown
                  _buildRatingSummaryCard(counts, cs, f),
                  SizedBox(height: 20),

                  // Filter chips
                  _buildFilterChips(counts),
                  SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedStarFilter == null
                            ? 'All Reviews (${_reviews.length})'
                            : '$_selectedStarFilter Star Reviews (${filteredReviews.length})',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_selectedStarFilter != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _selectedStarFilter = null),
                          child: Text(
                            'Clear filter',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // Review list
                  if (filteredReviews.isEmpty)
                    _buildEmptyFilterState()
                  else
                    ...filteredReviews.map((r) => _buildReviewCard(r, f, cs)),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingSummaryCard(
      Map<int, int> counts, ColorScheme cs, FitlekColors f) {
    final total = _reviews.isEmpty ? 1 : _reviews.length;

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Big average score
          SizedBox(
            width: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _avgRating.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final isFull = (i + 1) <= _avgRating.round();
                    return Icon(
                      isFull ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Color(0xFFFBBF24),
                      size: 16,
                    );
                  }),
                ),
                SizedBox(height: 6),
                Text(
                  '$_totalReviews reviews',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Vertical divider
          Container(
            width: 1,
            height: 90,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          SizedBox(width: 16),
          // Right: Google Maps Style Bars (5 to 1)
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((stars) {
                final count = counts[stars] ?? 0;
                final ratio = _reviews.isEmpty ? 0.0 : count / total;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        child: Text(
                          '$stars',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24), size: 12),
                      SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFBBF24)),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(Map<int, int> counts) {
    final filters = [
      {'label': 'All (${_reviews.length})', 'value': null},
      {'label': '5 ★ (${counts[5] ?? 0})', 'value': 5},
      {'label': '4 ★ (${counts[4] ?? 0})', 'value': 4},
      {'label': '3 ★ (${counts[3] ?? 0})', 'value': 3},
      {'label': '2 ★ (${counts[2] ?? 0})', 'value': 2},
      {'label': '1 ★ (${counts[1] ?? 0})', 'value': 1},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStarFilter == f['value'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStarFilter = f['value'] as int?;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : context.fitlek.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  f['label'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      padding: EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
              size: 48),
          SizedBox(height: 12),
          Text(
            _selectedStarFilter != null
                ? 'No reviews with $_selectedStarFilter stars yet'
                : widget.coachView
                    ? 'Your client feedback will appear here'
                    : 'No reviews found',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewItem review, FitlekColors f, ColorScheme cs) {
    final isMyReview = !widget.coachView && review.clientID == widget.clientID;
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][review.createdAt.month - 1];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyReview
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isMyReview
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15)
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.clientName.isNotEmpty
                        ? review.clientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isMyReview
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isMyReview
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isMyReview) ...[
                          SizedBox(width: 7),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'My review',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      '$month ${review.createdAt.year}',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Color(0xFFFBBF24),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              review.comment!.trim(),
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
