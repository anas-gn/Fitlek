import 'dart:math' as math;
import '../../services/live_updates.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../constants/urls.dart';
import '../../models/anas/coach.dart';
import '../../screens/ENG/userLocationSettings.dart';
import '../../theme/fitlek_theme_extension.dart';

class ExploreCoachMap extends StatefulWidget {
  final List<CoachModel> coaches;
  final String token;
  final ValueChanged<CoachModel> onOpen;
  final Future<void> Function() onRefresh;
  final http.Client? httpClient;
  final TileProvider? tileProvider;
  final double topInset;
  const ExploreCoachMap(
      {super.key,
      required this.coaches,
      required this.token,
      required this.onOpen,
      required this.onRefresh,
      this.httpClient,
      this.tileProvider,
      this.topInset = 0});
  @override
  State<ExploreCoachMap> createState() => _ExploreCoachMapState();
}

class _ExploreCoachMapState extends State<ExploreCoachMap> with LiveUpdates<ExploreCoachMap> {
  @override
  Set<String> get liveDomains => {'locations','coaches','profile','edit','bans'};
  @override
  Future<void> refreshLiveData() async => _load(recenter:false);
  final _controller = MapController();
  Map<int, LatLng> _points = {};
  LatLng? _client;
  int? _selected;
  bool _loading = true;
  String? _error;
  bool _ready = false;
  bool _expandedPins = false;
  bool _tilesFailed = false;
  Timer? _timer;
  late final http.Client _http;
  List<CoachModel> get _mapped =>
      widget.coaches.where((c) => _points.containsKey(c.id)).toList();
  CoachModel? get _coach {
    for (final coach in _mapped) {
      if (coach.id == _selected) return coach;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _http = widget.httpClient ?? http.Client();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    if (widget.httpClient == null) _http.close();
    super.dispose();
  }

  Future<void> _load({bool recenter = true}) async {
    try {
      final headers = {'Authorization': 'Bearer ${widget.token}'};
      final responses = await Future.wait([
        _http.get(Uri.parse('$baseUrl/coaches/map'), headers: headers),
        _http.get(Uri.parse('$baseUrl/locations/me'), headers: headers),
      ]).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (responses[0].statusCode != 200) throw Exception('Map unavailable');
      final points = <int, LatLng>{};
      for (final row in jsonDecode(responses[0].body) as List) {
        final lat = num.tryParse('${row['mapLatitude']}');
        final lng = num.tryParse('${row['mapLongitude']}');
        final id = int.tryParse('${row['id']}');
        if (id != null &&
            lat != null &&
            lng != null &&
            lat.abs() <= 90 &&
            lng.abs() <= 180) {
          points[id] = LatLng(lat.toDouble(), lng.toDouble());
        }
      }
      LatLng? client;
      if (responses[1].statusCode == 200) {
        final saved = jsonDecode(responses[1].body);
        final lat = num.tryParse('${saved['latitude']}'),
            lng = num.tryParse('${saved['longitude']}');
        if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180)
          client = LatLng(lat.toDouble(), lng.toDouble());
      }
      setState(() {
        _points = points;
        _client = client;
        _loading = false;
        _error = null;
      });
      if (_ready && recenter) _nearMe();
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Could not load the map. Please try again.';
        });
    }
  }

  Future<void> _refresh() async {
    await widget.onRefresh();
    if (mounted) await _load();
  }

  void _nearMe() {
    if (!_ready) return;
    if (_client != null) {
      _controller.move(_client!, 12);
      return;
    }
    _fitCoaches();
  }

  void _fitCoaches() {
    final points = _mapped.map((c) => _points[c.id]!).toList();
    if (!_ready || points.isEmpty) return;
    if (points.toSet().length == 1) {
      _controller.move(points.first, 12);
      return;
    }
    _controller.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(55),
        maxZoom: 14));
  }

  Future<void> _setLocation() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const UserLocationSettings()));
    if (mounted) await _refresh();
  }

  Future<void> _select(List<CoachModel> coaches, bool compact) async {
    CoachModel? selected = coaches.first;
    if (coaches.length > 1) {
      selected = await showModalBottomSheet<CoachModel>(
          context: context,
          isScrollControlled: true,
          builder: (context) => SafeArea(
                child: ListView(shrinkWrap: true, children: [
                  const ListTile(title: Text('Coaches in this area')),
                  for (final coach in coaches)
                    ListTile(
                        title: Text(coach.fullName),
                        subtitle: Text(coach.locationLabel),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, coach)),
                ]),
              ));
    }
    if (!mounted || selected == null) return;
    setState(() => _selected = selected!.id);
    if (compact)
      await showModalBottomSheet(
          context: context, builder: (_) => SafeArea(child: _card(selected!)));
  }

  Widget _card(CoachModel coach) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          _avatar(coach),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Flexible(
                      child: Text(coach.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                  if (coach.isApproved)
                    const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.verified,
                            size: 15, color: Color(0xFF38BDF8)))
                ]),
                Text(coach.displaySpecialties,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.fitlek.textMuted, fontSize: 12)),
                Text(coach.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                FilledButton(
                    onPressed: () => widget.onOpen(coach),
                    child: const Text('View & Book')),
              ])),
        ]),
      );

  void _zoomBy(double change) {
    if (!_ready) return;
    final camera = _controller.camera;
    _controller.move(camera.center, (camera.zoom + change).clamp(3.0, 18.0));
  }

  Widget _mapButton(String label, IconData icon, VoidCallback onTap) =>
      IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon, size: 23, color: const Color(0xFF064B43)),
        style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF064B43),
            minimumSize: const Size(48, 48)),
      );
  Widget _avatar(CoachModel coach) {
    var url = coach.avatarUrl?.trim() ?? '';
    if (url.isNotEmpty && !url.startsWith('http')) {
      final root = baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      url = '$root${url.startsWith('/') ? '' : '/'}$url';
    }
    return CircleAvatar(
        backgroundColor: const Color(0xFF064B43),
        foregroundImage: url.isEmpty ? null : NetworkImage(url),
        onForegroundImageError: url.isEmpty ? null : (_, __) {},
        child: const Icon(Icons.person_rounded, color: Colors.white));
  }

  Offset _pinOffset(CoachModel coach) {
    if (!_expandedPins) return Offset.zero;
    final same =
        _mapped.where((c) => _points[c.id] == _points[coach.id]).toList();
    if (same.length < 2) return Offset.zero;
    final angle =
        2 * math.pi * same.indexWhere((c) => c.id == coach.id) / same.length;
    return Offset(math.cos(angle) * 34, math.sin(angle) * 34);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        TextButton(onPressed: _load, child: const Text('Retry')),
      ]));
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxHeight < 300;
      final groups = <String, List<CoachModel>>{};
      for (final coach in _mapped) {
        final point = _points[coach.id]!;
        groups
            .putIfAbsent(
                '${point.latitude},${point.longitude}${_expandedPins ? ':${coach.id}' : ''}',
                () => [])
            .add(coach);
      }
      return Column(children: [
        Expanded(
            child: Stack(children: [
          FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _client ??
                    (_mapped.isEmpty
                        ? const LatLng(32, -6)
                        : _points[_mapped.first.id]!),
                initialZoom: _client != null || _mapped.isNotEmpty ? 12 : 5,
                onPositionChanged: (camera, _) {
                  final expanded = camera.zoom >= 14;
                  if (expanded != _expandedPins)
                    setState(() => _expandedPins = expanded);
                },
                minZoom: 3,
                maxZoom: 18,
                onMapReady: () {
                  _ready = true;
                  _nearMe();
                },
              ),
              children: [
                TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    tileProvider: widget.tileProvider,
                    userAgentPackageName: 'com.sirvya.app',
                    errorTileCallback: (_, __, ___) {
                      if (mounted && !_tilesFailed)
                        setState(() => _tilesFailed = true);
                    }),
                MarkerLayer(markers: [
                  if (_client != null)
                    Marker(
                        point: _client!,
                        width: 28,
                        height: 28,
                        child: Container(
                            decoration: BoxDecoration(
                                color: const Color(0xFF2878F0),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 4)),
                            child: const Tooltip(
                                message: 'Your location',
                                child: SizedBox.expand()))),
                  for (final group in groups.values)
                    Marker(
                        point: _points[group.first.id]!,
                        width: _expandedPins ? 140 : 48,
                        height: _expandedPins ? 140 : 48,
                        child: Center(
                          child: Transform.translate(
                              offset: _pinOffset(group.first),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: Semantics(
                                  label: group.length > 1
                                      ? '${group.length} coaches in this area'
                                      : group.first.fullName,
                                  button: true,
                                  child: GestureDetector(
                                    onTap: () => _select(group, compact),
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: group.any(
                                                      (c) => c.id == _selected)
                                                  ? const Color(0xFF064B43)
                                                  : const Color(0xFF55E6D0),
                                              width: 3),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 8,
                                                offset: Offset(0, 3))
                                          ]),
                                      child: group.length > 1
                                          ? Center(
                                              child: Text('${group.length}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Color(0xFF064B43))))
                                          : _avatar(group.first),
                                    ),
                                  ),
                                ),
                              )),
                        )),
                ]),
              ]),
          Positioned(
              bottom: 2,
              left: 6,
              child: GestureDetector(
                onTap: () => launchUrl(
                    Uri.parse('https://www.openstreetmap.org/copyright')),
                child: Container(
                    color: Colors.white.withValues(alpha: 0.9),
                    padding: const EdgeInsets.all(3),
                    child: const Text('© OpenStreetMap contributors',
                        style:
                            TextStyle(color: Color(0xFF064B43), fontSize: 9))),
              )),
          Positioned(
              bottom: 26,
              left: 10,
              right: 66,
              child: IgnorePointer(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                    color: context.fitlek.card,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                    _tilesFailed
                        ? 'Map tiles unavailable. Check your connection.'
                        : _mapped.isEmpty
                            ? 'No coaches with a saved location match your filters.'
                            : '${_mapped.length} coaches · Approximate locations',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11)),
              ))),
          Positioned(
            right: 10,
            top: math.max(
                8, math.min(widget.topInset + 8, constraints.maxHeight - 156)),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _mapButton(
                    _client == null ? 'Set your location' : 'Near me',
                    Icons.my_location,
                    _client == null ? _setLocation : _nearMe),
                _mapButton('Show all coaches', Icons.zoom_out_map, _fitCoaches),
                _mapButton('Refresh map', Icons.refresh, _refresh),
              ]),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 64,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _mapButton('Zoom out', Icons.remove_rounded, () => _zoomBy(-1)),
                _mapButton('Zoom in', Icons.add_rounded, () => _zoomBy(1)),
              ]),
            ),
          ),
        ])),
        if (!compact && _coach != null) _card(_coach!),
      ]);
    });
  }
}
