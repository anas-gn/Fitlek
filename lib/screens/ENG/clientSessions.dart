import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:fitlek1/models/anas/reservation.dart';
import 'clientSessionDetail.dart';

const _lime = Color(0xFFC6F135);
const _dark = Color(0xFF0A0A0A);
const _card = Color(0xFF141414);
const _cardBorder = Color(0xFF232323);
const _baseUrl = 'http://localhost:3000/api';

class _FitlekLogoPainter extends CustomPainter {
  final Color strokeColor;
  final Color circleColor;

  const _FitlekLogoPainter({required this.strokeColor, required this.circleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 132;
    final scaleY = size.height / 120;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    canvas.drawCircle(const Offset(65.6104, 17.25), 17.25, Paint()..color = circleColor);

    final path = Path()
      ..moveTo(5.8103, 21.85)
      ..cubicTo(19.2827, 35.9, 45.0007, 47.25, 64.4603, 47.7336)
      ..moveTo(125.41, 21.85)
      ..cubicTo(112.388, 36.0329, 83.709, 48.212, 64.4603, 47.7336)
      ..moveTo(64.4603, 47.7336)
      ..lineTo(64.4603, 106.95)
      ..cubicTo(87.8436, 95.8333, 128.4, 73.37, 103.56, 72.45)
      ..cubicTo(78.7203, 71.53, 36.477, 72.0666, 18.4603, 72.45);

    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FitlekLogoPainter oldDelegate) => false;
}

class _FitlekLogo extends StatelessWidget {
  final double height;
  const _FitlekLogo({this.height = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: height * 132 / 120,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _lime.withOpacity(0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
      ),
    );
  }
}

class _LogoWatermark extends StatelessWidget {
  final double size;
  const _LogoWatermark({this.size = 340});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.035,
        child: SizedBox(
          width: size,
          height: size * 120 / 132,
          child: CustomPaint(
            painter: _FitlekLogoPainter(strokeColor: Colors.white, circleColor: _lime),
          ),
        ),
      ),
    );
  }
}

class SessionsScreen extends StatefulWidget {
  final String token;
  final int clientID;

  const SessionsScreen({
    super.key,
    required this.clientID,
    required this.token,
  });

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<ReservationModel> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$_baseUrl/reservations').replace(
        queryParameters: {
          'role': 'client',
          'userID': widget.clientID.toString(),
          'limit': '100',
        },
      );

      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        final sessions = data.map((j) => ReservationModel.fromJson(j)).toList();

        sessions.sort((a, b) {
          if (a.isUpcoming && !b.isUpcoming) return -1;
          if (!a.isUpcoming && b.isUpcoming) return 1;
          return b.sessionStart.compareTo(a.sessionStart);
        });

        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur serveur (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de joindre le serveur.';
          _loading = false;
        });
      }
    }
  }

  List<ReservationModel> get _upcoming => _sessions.where((s) => s.isUpcoming).toList();

  List<ReservationModel> get _past => _sessions.where((s) => !s.isUpcoming).toList();

  int get _completedCount =>
      _sessions.where((s) => s.isConfirmed && s.sessionStart.isBefore(DateTime.now())).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: -90,
              bottom: -20,
              child: _LogoWatermark(size: 380),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 4),
                _buildTabBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _FitlekLogo(height: 36),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'FIT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _lime,
                      letterSpacing: 2.5,
                    ),
                  ),
                  TextSpan(
                    text: 'LEK',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text('Mes séances', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
        const Spacer(),
        if (!_loading && _error == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _lime.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _lime.withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.bolt_rounded, color: _lime, size: 14),
              const SizedBox(width: 6),
              Text('$_completedCount complétées',
                  style: const TextStyle(color: _lime, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        if (!_loading) ...[
          const SizedBox(width: 10),
          
        ],
      ],
    ),
  );
}

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(color: _lime, borderRadius: BorderRadius.circular(8)),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          tabs: [
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.upcoming_rounded, size: 13),
                const SizedBox(width: 6),
                Text('À VENIR (${_upcoming.length})'),
              ]),
            ),
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.history_rounded, size: 13),
                const SizedBox(width: 6),
                Text('PASSÉES (${_past.length})'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white12, size: 52),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetchSessions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _lime.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _lime.withOpacity(0.4)),
              ),
              child: const Text('Réessayer',
                  style: TextStyle(color: _lime, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ]),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildSessionList(_upcoming, emptyMsg: 'Aucune séance à venir.'),
        _buildSessionList(_past, emptyMsg: 'Aucune séance passée.'),
      ],
    );
  }

  Widget _buildSessionList(List<ReservationModel> sessions, {required String emptyMsg}) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_month_outlined, color: Colors.white12, size: 48),
          const SizedBox(height: 12),
          Text(emptyMsg, style: const TextStyle(color: Colors.white24, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Tire vers le bas pour actualiser', style: TextStyle(color: Colors.white12, fontSize: 11)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      color: _lime,
      backgroundColor: _card,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        itemCount: sessions.length,
        itemBuilder: (_, i) => _SessionCard(
          session: sessions[i],
          token: widget.token,
          clientID: widget.clientID,
          onUpdated: (updated) => setState(() {
            final idx = _sessions.indexWhere((s) => s.id == updated.id);
            if (idx != -1) _sessions[idx] = updated;
          }),
          onCancelled: (id) => setState(() {
            _sessions.removeWhere((s) => s.id == id);
          }),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ReservationModel session;
  final String token;
  final int clientID;
  final void Function(ReservationModel updated) onUpdated;
  final void Function(int id) onCancelled;

  const _SessionCard({
    required this.session,
    required this.token,
    required this.clientID,
    required this.onUpdated,
    required this.onCancelled,
  });

  Color get _statusColor {
    switch (session.status) {
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return _lime;
      case 'cancelled':
        return const Color(0xFFFF5252);
      default:
        return Colors.white38;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case 'pending':
        return 'EN ATTENTE';
      case 'confirmed':
        return 'CONFIRMÉE';
      case 'cancelled':
        return 'ANNULÉE';
      default:
        return '';
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _cancel(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Annuler la séance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text("Confirmes-tu l'annulation de cette réservation ?",
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NON', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OUI, ANNULER', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/reservations/${session.id}/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'cancelledBy': 'coach', 'cancellationReason': 'Annulé par le client'}),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        onCancelled(session.id);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('Réservation annulée', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF1A1A1A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool hasReview = session.reviewRating != null;
    final bool needsReview = session.needsReview;
    final bool canCancel = session.isPending && session.sessionStart.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: _lime.withOpacity(0.05),
          highlightColor: _lime.withOpacity(0.03),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => SessionDetailScreen(
                  session: session,
                  clientID: clientID,
                  token: token,
                ),
                transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ).then((updated) {
              if (updated != null) {
                onUpdated(updated as ReservationModel);
              }
            });
          },
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _statusColor.withOpacity(0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF1A1A1A),
                    backgroundImage: session.coachImageUrl.isNotEmpty ? NetworkImage(session.coachImageUrl) : null,
                    child: session.coachImageUrl.isEmpty
                        ? Text(
                            session.coachName.isNotEmpty ? session.coachName[0].toUpperCase() : '?',
                            style: const TextStyle(color: _lime, fontWeight: FontWeight.w900),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(session.coachName,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(session.coachSpeciality, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor.withOpacity(0.35)),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(
                          color: _statusColor, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
              ]),
            ),
            Divider(height: 1, color: Colors.white.withOpacity(0.05)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(children: [
                _meta(Icons.calendar_today_rounded, _formatDate(session.sessionStart)),
                const SizedBox(width: 12),
                _meta(Icons.access_time_rounded,
                    '${_formatTime(session.sessionStart)} — ${_formatTime(session.sessionEnd)}'),
                const Spacer(),
                if (hasReview)
                  Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < session.reviewRating! ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: _lime,
                                size: 13,
                              )))
                else if (needsReview)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _lime.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _lime.withOpacity(0.3)),
                    ),
                    child: const Text('NOTER',
                        style:
                            TextStyle(color: _lime, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  )
                else if (session.price > 0)
                  Text('${session.price.toInt()} MAD',
                      style: const TextStyle(color: _lime, fontWeight: FontWeight.w800, fontSize: 12)),
              ]),
            ),
            if (canCancel) ...[
              Divider(height: 1, color: Colors.white.withOpacity(0.05)),
              GestureDetector(
                onTap: () => _cancel(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.cancel_outlined, color: Color(0xFFFF5252), size: 13),
                    SizedBox(width: 6),
                    Text('Annuler la réservation',
                        style: TextStyle(
                            color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(children: [
        Icon(icon, color: Colors.white24, size: 11),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w500)),
      ]);
}