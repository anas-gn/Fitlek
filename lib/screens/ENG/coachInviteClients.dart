import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/apiService.dart';
import '../../services/live_updates.dart';
import '../../theme/fitlek_theme_extension.dart';

class CoachInviteClients extends StatefulWidget {
  const CoachInviteClients({super.key});
  @override
  State<CoachInviteClients> createState() => _CoachInviteClientsState();
}

class _CoachInviteClientsState extends State<CoachInviteClients>
    with LiveUpdates<CoachInviteClients> {
  bool _loading = true;
  String? _error;
  String _code = '', _link = '';
  int _clients = 0, _coaches = 0, _points = 0;
  List<dynamic> _history = [];
  String _filter = 'All';
  @override
  Set<String> get liveDomains =>
      {'invitations', 'invite', 'referrals', 'notifications', 'profile'};
  @override
  Future<void> refreshLiveData() => _load(silent: true);
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent)
      setState(() {
        _loading = true;
        _error = null;
      });
    final results = await Future.wait([
      ApiService.get('/coach/invite'),
      ApiService.get('/coach/invite/referrals')
    ]);
    if (!mounted) return;
    setState(() {
      if (results.any((r) => r['ok'] != true)) {
        _error = 'Unable to load invitations. Please try again.';
      } else {
        final data = results[0];
        _code = '${data['invitationCode'] ?? ''}';
        _link = _code.isEmpty
            ? ''
            : 'https://sirvya.com/invite/${Uri.encodeComponent(_code)}';
        _clients = int.tryParse('${data['clientSignups']}') ?? 0;
        _coaches = int.tryParse('${data['coachSignups']}') ?? 0;
        _points = int.tryParse('${data['earnedPoints']}') ?? 0;
        _history = List<dynamic>.from(results[1]['data'] ?? []);
        _error = null;
      }
      _loading = false;
    });
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
          title: 'Join me on SIRVYA',
          text:
              'You are invited to join me on SIRVYA. Find your coach or grow your coaching business.\n\n$_link\n\nInvitation code: $_code',
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size));
    } catch (_) {
      if (mounted)
        await _copy('Join me on SIRVYA: $_link\nInvitation code: $_code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme, f = context.fitlek;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite & grow')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (_error != null) ...[
                            Text(_error!, style: TextStyle(color: f.error)),
                            TextButton(
                                onPressed: _load, child: const Text('Retry'))
                          ],
                          Text('Grow your SIRVYA network',
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                              'One code for clients and coaches. Track the people who successfully sign up through your invitation.',
                              style: TextStyle(
                                  color: f.textSecondary, height: 1.5)),
                          const SizedBox(height: 20),
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: f.card,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: f.border)),
                              child: Column(children: [
                                if (_link.isNotEmpty)
                                  Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      child: QrImageView(
                                          data: _link,
                                          size: 170,
                                          backgroundColor: Colors.white)),
                                const SizedBox(height: 16),
                                const Text('Your invitation code'),
                                const SizedBox(height: 6),
                                SelectableText(_code,
                                    style: TextStyle(
                                        color: cs.onSurface,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2)),
                                const SizedBox(height: 16),
                                Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                          onPressed: _code.isEmpty
                                              ? null
                                              : () => _copy(_code),
                                          icon: const Icon(Icons.copy_rounded,
                                              size: 18),
                                          label: const Text('Copy code')),
                                      OutlinedButton.icon(
                                          onPressed: _link.isEmpty
                                              ? null
                                              : () => _copy(_link),
                                          icon: const Icon(Icons.link_rounded,
                                              size: 18),
                                          label: const Text('Copy link')),
                                      Builder(
                                          builder: (ctx) => FilledButton.icon(
                                              onPressed: _link.isEmpty
                                                  ? null
                                                  : () => _share(ctx),
                                              icon: const Icon(
                                                  Icons.share_rounded,
                                                  size: 18),
                                              label: const Text('Share'))),
                                    ]),
                              ])),
                          const SizedBox(height: 20),
                          Row(children: [
                            Expanded(
                                child: _stat('$_clients', 'Clients joined')),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _stat('$_coaches', 'Coaches joined'))
                          ]),
                          const SizedBox(height: 10),
                          _stat('$_points points', 'Your total reward balance'),
                          const SizedBox(height: 20),
                          Text('How rewards work',
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                              'Coach: 40 points after a new account is created.\nClient: 20 points when you accept their connection in Clients. Sharing or opening a link does not earn points.',
                              style: TextStyle(
                                  color: f.textSecondary, height: 1.6)),
                          const SizedBox(height: 24),
                          Text('People you invited',
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Wrap(
                              spacing: 8,
                              children: ['All', 'Clients', 'Coaches']
                                  .map((value) => ChoiceChip(
                                      label: Text(value),
                                      selected: _filter == value,
                                      onSelected: (_) =>
                                          setState(() => _filter = value)))
                                  .toList()),
                          const SizedBox(height: 12),
                          if (_history.where(_matches).isEmpty)
                            Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                    'No signups in this category yet. Share your link to get started.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: f.textMuted))),
                          ..._history.where(_matches).map((r) => _person(r)),
                        ],
                      ))),
            ),
    );
  }

  bool _matches(dynamic r) =>
      _filter == 'All' ||
      (_filter == 'Clients' ? r['role'] == 'client' : r['role'] == 'coach');
  Widget _stat(String value, String label) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.fitlek.card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: context.fitlek.textMuted, fontSize: 12))
      ]));
  Widget _person(dynamic r) {
    final cs = Theme.of(context).colorScheme, f = context.fitlek;
    final name = '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.trim();
    final date = DateTime.tryParse('${r['createdAt']}')?.toLocal();
    final role = r['role'] == 'coach' ? 'Coach' : 'Client';
    final status = r['status'] == 'pending'
        ? 'Connection pending'
        : r['status'] == 'accepted'
            ? 'Connected'
            : r['status'] == 'refused'
                ? 'Connection declined'
                : 'Registered';
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                  backgroundColor: f.card2,
                  child: Icon(
                      role == 'Coach'
                          ? Icons.fitness_center_rounded
                          : Icons.person_outline_rounded,
                      color: cs.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name.isEmpty ? role : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: cs.onSurface, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('$role • $status',
                        style: TextStyle(color: f.textSecondary, fontSize: 12)),
                    if (date != null)
                      Text('${date.day}/${date.month}/${date.year}',
                          style: TextStyle(color: f.textMuted, fontSize: 11))
                  ])),
              const SizedBox(width: 8),
              Text('+${r['pointsAwarded'] ?? 0} pts',
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.w700)),
            ])));
  }
}
