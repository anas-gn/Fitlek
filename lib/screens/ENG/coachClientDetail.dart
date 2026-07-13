import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import '../../models/coachConversation.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'coachChat.dart';

/// Coach-facing details for a client genuinely linked to the authenticated
/// coach. All data comes from the secure `/coach/clients/:id` endpoint, which
/// verifies the coachclients relationship on the backend. Reservation stats and
/// recent sessions are scoped to this coach + client only.
class CoachClientDetail extends StatefulWidget {
  final String clientId;

  // Lightweight values from the list item, shown while the details load.
  final String initialName;
  final String? initialAvatar;
  final bool initialPremium;

  const CoachClientDetail({
    super.key,
    required this.clientId,
    required this.initialName,
    this.initialAvatar,
    this.initialPremium = false,
  });

  @override
  State<CoachClientDetail> createState() => _CoachClientDetailState();
}

class _CoachClientDetailState extends State<CoachClientDetail> {
  bool _loading = true;
  bool _hasError = false;
  bool _messaging = false;
  bool _unlinking = false;
  Map<String, dynamic>? _client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    final res = await ApiService.get('/coach/clients/${widget.clientId}');
    if (!mounted) return;
    setState(() {
      if (res['ok'] == true) {
        _client = res;
      } else {
        _hasError = true;
      }
      _loading = false;
    });
  }

  bool get _isPremium {
    final v = _client?['isPremium'] ?? widget.initialPremium;
    return v == 1 || v == true;
  }

  String get _fullName {
    if (_client == null) return widget.initialName;
    return '${_client!['firstName'] ?? ''} ${_client!['lastName'] ?? ''}'.trim();
  }

  String? get _avatar {
    final a = _client?['avatarUrl'] ?? widget.initialAvatar;
    return (a != null && a.toString().isNotEmpty) ? a.toString() : null;
  }

  String get _initials {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    final res = (a + b).toUpperCase();
    return res.isEmpty ? '?' : res;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final d = DateTime.tryParse(raw.toString());
    if (d == null) return raw.toString();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    final parts = s.split(':');
    if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    return s;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: TextStyle(color: isError ? cs.onError : cs.onPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
      backgroundColor: isError ? context.fitlek.error : cs.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _openConversation() async {
    if (_messaging) return;
    setState(() => _messaging = true);
    try {
      final res = await ApiService.post('/coach/clients/${widget.clientId}/conversation', {});
      if (!mounted) return;
      if (res['ok'] != true) {
        _showSnack(res['message']?.toString() ?? 'Unable to open the conversation', isError: true);
        return;
      }
      final conversationId = res['conversationID']?.toString();
      if (conversationId == null) {
        _showSnack('Unable to open the conversation', isError: true);
        return;
      }
      final conversation = CoachConversation(
        id: conversationId,
        clientId: widget.clientId,
        clientName: _fullName,
        clientPhotoUrl: _avatar ?? '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CoachChat(conversation: conversation)),
      );
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _messaging = false);
    }
  }

  Future<void> _confirmUnlink() async {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: f.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: f.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.person_remove_rounded, color: f.error, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Remove client', style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Remove $_fullName from your clients? This only unlinks them from your list; their account and past sessions are not deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(color: f.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(color: f.card2, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('Cancel', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(color: f.error, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text('Remove', style: TextStyle(color: cs.onError, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirmed != true || _unlinking) return;
    setState(() => _unlinking = true);
    final res = await ApiService.delete('/coach/clients/${widget.clientId}');
    if (!mounted) return;
    setState(() => _unlinking = false);
    if (res['ok'] == true) {
      _showSnack('Client removed ✓');
      Navigator.of(context).pop(true); // signal the list to refresh
    } else {
      _showSnack(res['message']?.toString() ?? 'Unable to remove the client', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: cs.onSurface),
        title: Text('Client', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: cs.primary))
            : _hasError
                ? _buildError()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: _buildContent(),
                    ),
                  ),
      ),
    );
  }

  Widget _buildError() {
    final f = context.fitlek;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, color: f.textMuted, size: 48),
        const SizedBox(height: 12),
        Text('Unable to load client', style: TextStyle(color: f.textMuted, fontSize: 15)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _load,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(14)),
            child: Text('Retry', style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    final c = _client!;
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final email = (c['email'] ?? '').toString();
    final gender = (c['gender'] ?? '').toString();
    final height = c['height'];
    final reservations = (c['reservations'] as Map?) ?? const {};
    final recentSessions = (c['recentSessions'] as List?) ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ── Identity ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: f.border)),
          child: Column(children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _isPremium ? cs.primary.withValues(alpha: 0.5) : f.border, width: 2),
              ),
              child: ClipOval(
                child: _avatar != null
                    ? Image.network(_avatar!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(cs, f))
                    : _avatarFallback(cs, f),
              ),
            ),
            const SizedBox(height: 14),
            Text(_fullName,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: f.textMuted, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(_isPremium ? 'Premium' : 'Standard', _isPremium ? Icons.star_rounded : Icons.person_outline_rounded,
                    _isPremium ? cs.primary : f.textSecondary),
                if (gender.isNotEmpty) _chip(gender, Icons.wc_rounded, f.info),
                if (height != null) _chip('$height cm', Icons.height_rounded, f.violet),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Coaching relationship ──
        _sectionTitle('Coaching relationship'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: f.border)),
          child: Column(children: [
            _detailRow(Icons.link_rounded, 'Connected since', _formatDate(c['linkedAt'])),
            if (c['createdAt'] != null) _detailRow(Icons.calendar_today_rounded, 'Client since', _formatDate(c['createdAt'])),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: _statBox('${reservations['total'] ?? 0}', 'Sessions', cs.onSurface)),
              const SizedBox(width: 10),
              Expanded(child: _statBox('${reservations['confirmed'] ?? 0}', 'Confirmed', f.success)),
              const SizedBox(width: 10),
              Expanded(child: _statBox('${reservations['pending'] ?? 0}', 'Pending', f.warning)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Recent sessions ──
        _sectionTitle('Recent sessions'),
        const SizedBox(height: 10),
        if (recentSessions.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: f.border)),
            child: Center(child: Text('No sessions yet', style: TextStyle(color: f.textMuted, fontSize: 13))),
          )
        else
          Container(
            decoration: BoxDecoration(color: f.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: f.border)),
            child: Column(
              children: List.generate(recentSessions.length, (i) {
                final s = recentSessions[i] as Map<String, dynamic>;
                return _sessionRow(s, isLast: i == recentSessions.length - 1);
              }),
            ),
          ),
        const SizedBox(height: 24),

        // ── Actions ──
        _primaryButton(
          icon: Icons.chat_bubble_rounded,
          label: 'Message client',
          loading: _messaging,
          onTap: _openConversation,
        ),
        const SizedBox(height: 12),
        _dangerButton(
          icon: Icons.person_remove_rounded,
          label: 'Remove from my clients',
          loading: _unlinking,
          onTap: _confirmUnlink,
        ),
      ],
    );
  }

  Widget _avatarFallback(ColorScheme cs, FitlekColors f) =>
      Center(child: Text(_initials, style: TextStyle(color: cs.primary, fontSize: 26, fontWeight: FontWeight.w800)));

  Widget _sectionTitle(String text) => Text(text,
      style: TextStyle(color: context.fitlek.textMuted, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6));

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: f.textMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: f.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    final f = context.fitlek;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: f.card2, borderRadius: BorderRadius.circular(14), border: Border.all(color: f.border)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: f.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _sessionRow(Map<String, dynamic> s, {required bool isLast}) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final status = (s['status'] ?? '').toString();
    Color statusColor;
    switch (status) {
      case 'confirmed':
        statusColor = f.success;
        break;
      case 'pending':
        statusColor = f.warning;
        break;
      case 'cancelled':
        statusColor = f.error;
        break;
      default:
        statusColor = f.textMuted;
    }
    final label = status.isEmpty ? '' : '${status[0].toUpperCase()}${status.substring(1)}';
    final location = (s['location'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: f.border)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
          child: Icon(Icons.event_rounded, color: statusColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_formatDate(s['reservedDate'])}  •  ${_formatTime(s['reservedTime'])}',
                style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: f.textMuted, fontSize: 11.5)),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _primaryButton({required IconData icon, required String label, required bool loading, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: loading ? cs.primary.withValues(alpha: 0.6) : cs.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: loading ? null : [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: loading
              ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, size: 19, color: cs.onPrimary),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(color: cs.onPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                ]),
        ),
      ),
    );
  }

  Widget _dangerButton({required IconData icon, required String label, required bool loading, required VoidCallback onTap}) {
    final f = context.fitlek;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: f.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.error.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: loading
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation<Color>(f.error)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icon, size: 18, color: f.error),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(color: f.error, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
        ),
      ),
    );
  }
}
