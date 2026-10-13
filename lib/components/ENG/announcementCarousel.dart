import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/urls.dart';
import '../../theme/fitlek_theme_extension.dart';

class AnnouncementCarousel extends StatefulWidget {
  final int clientID;
  final String token;
  final VoidCallback onExplore;
  final bool Function(String)? onDestination;
  final http.Client? client;
  const AnnouncementCarousel(
      {super.key,
      required this.clientID,
      required this.token,
      required this.onExplore,
      this.onDestination,
      this.client});
  @override
  State<AnnouncementCarousel> createState() => AnnouncementCarouselState();
}

class AnnouncementCarouselState extends State<AnnouncementCarousel> {
  final _controller = PageController(viewportFraction: 0.94);
  List<Map<String, dynamic>> _items = [];
  final Set<String> _dismissed = {};
  int _index = 0;
  bool _fetching = false;
  String get _dismissalKey => 'dismissed_announcements_${widget.clientID}';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissed.addAll(prefs.getStringList(_dismissalKey) ?? []);
      final url = Uri.parse('$baseUrl/actualites?limit=20');
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final res = await (widget.client?.get(url, headers: headers) ??
              http.get(url, headers: headers))
          .timeout(const Duration(seconds: 10));
      if (!mounted || res.statusCode != 200) return;
      final data = jsonDecode(res.body) as List;
      final items = data
          .whereType<Map<String, dynamic>>()
          .where((item) =>
              item['id'] != null &&
              (item['title']?.toString().trim().isNotEmpty ?? false) &&
              !_dismissed.contains(item['id'].toString()))
          .take(3)
          .toList();
      if (_controller.hasClients) _controller.jumpToPage(0);
      setState(() {
        _items = items;
        _index = 0;
      });
    } catch (_) {
      // Keep the last loaded announcements during a temporary connection failure.
    } finally {
      _fetching = false;
    }
  }

  Future<void> _dismiss() async {
    _dismissed.addAll(_items.map((item) => item['id'].toString()));
    setState(() {
      _items = [];
      _index = 0;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dismissalKey, _dismissed.toList());
    } catch (_) {/* Dismissal still applies for this session. */}
  }

  String _imageUrl(dynamic value) {
    final url = value?.toString().trim() ?? '';
    if (url.isEmpty) return '';
    return Uri.parse(baseUrl.replaceFirst(RegExp(r'/api/?$'), '/'))
        .resolve(url)
        .toString();
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final link = item['link']?.toString().trim() ?? '';
    if (link == '/coaches' || link == '/explore') {
      widget.onExplore();
      return;
    }
    if (widget.onDestination?.call(link) ?? false) return;
    final uri = Uri.tryParse(link);
    if (uri != null &&
        (['https', 'http'].contains(uri.scheme) && uri.host.isNotEmpty ||
            ['mailto', 'tel', 'sms'].contains(uri.scheme) &&
                uri.path.isNotEmpty)) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {/* Show announcement details if the link cannot open. */}
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.fitlek.card,
      builder: (ctx) => SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title'].toString(),
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(item['content']?.toString() ?? '',
                style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close')),
          ],
        )),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Icon(Icons.campaign_outlined,
                  color: Theme.of(context).colorScheme.onSurface, size: 22),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('What’s new at Sirvya',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800))),
              IconButton(
                  onPressed: _dismiss,
                  tooltip: 'Dismiss announcements',
                  icon: const Icon(Icons.close_rounded, size: 20)),
            ])),
        SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (_, index) {
                final item = _items[index];
                final image = _imageUrl(item['imageUrl']);
                final content = item['content']?.toString().trim() ?? '';
                final link = item['link']?.toString().trim() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          color: const Color(0xFF0C2420),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: primary.withValues(alpha: 0.35))),
                      child: Stack(fit: StackFit.expand, children: [
                        if (image.isNotEmpty)
                          Image.network(image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink()),
                        DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                          const Color(0xFF061B17).withValues(alpha: 0.97),
                          const Color(0xFF061B17).withValues(alpha: 0.78),
                          Colors.transparent
                        ], stops: const [
                          0,
                          0.58,
                          1
                        ]))),
                        Padding(
                            padding: const EdgeInsets.all(14),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                    widthFactor: 0.78,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('SIRVYA UPDATE',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: primary,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1)),
                                          const SizedBox(height: 5),
                                          Expanded(
                                              child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      item['title'].toString(),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          height: 1.1)))),
                                          if (content.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(content,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12)),
                                          ],
                                          const SizedBox(height: 7),
                                          SizedBox(
                                              height: 34,
                                              child: FilledButton(
                                                  style: FilledButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFF2F1E7),
                                                      foregroundColor:
                                                          const Color(
                                                              0xFF064B43),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12)),
                                                  onPressed: () => _open(item),
                                                  child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Flexible(
                                                            child: Text(
                                                                (item['buttonLabel']
                                                                            ?.toString()
                                                                            .trim()
                                                                            .isNotEmpty ??
                                                                        false)
                                                                    ? item['buttonLabel']
                                                                        .toString()
                                                                        .trim()
                                                                    : link == '/coaches' ||
                                                                            link ==
                                                                                '/explore'
                                                                        ? 'Explore coaches'
                                                                        : link
                                                                                .isNotEmpty
                                                                            ? 'Learn more'
                                                                            : 'Read more',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700))),
                                                        const SizedBox(
                                                            width: 8),
                                                        const Icon(
                                                            Icons
                                                                .arrow_forward_rounded,
                                                            size: 16),
                                                      ]))),
                                        ])))),
                      ])),
                );
              },
            )),
        const SizedBox(height: 8),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                _items.length,
                (index) => GestureDetector(
                      onTap: () => _controller.animateToPage(index,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: _index == index ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: _index == index
                                      ? primary
                                      : context.fitlek.textMuted,
                                  borderRadius: BorderRadius.circular(8)))),
                    ))),
      ]),
    );
  }
}
