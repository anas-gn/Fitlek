import 'package:fitlek1/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
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
        _error = AppLocalizations.of(context).coachInviteClientsLoadError;
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
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).coachInviteClientsCopied)));
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
          title: AppLocalizations.of(context).coachInviteClientsShareTitle,
          text: AppLocalizations.of(context)
              .coachInviteClientsShareText(_link, _code),
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size));
    } catch (_) {
      if (mounted)
        await _copy(AppLocalizations.of(context)
            .coachInviteClientsShareFallback(_link, _code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme, f = context.fitlek;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).coachInviteClientsTitle)),
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
                                onPressed: _load,
                                child: Text(AppLocalizations.of(context).coachInviteClientsRetry))
                          ],
                          Text(AppLocalizations.of(context).coachInviteClientsHeading,
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                              AppLocalizations.of(context).coachInviteClientsIntro,
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
                                Text(AppLocalizations.of(context).coachInviteClientsYourCode),
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
                                          label: Text(AppLocalizations.of(context).coachInviteClientsCopyCode)),
                                      OutlinedButton.icon(
                                          onPressed: _link.isEmpty
                                              ? null
                                              : () => _copy(_link),
                                          icon: const Icon(Icons.link_rounded,
                                              size: 18),
                                          label: Text(AppLocalizations.of(context).coachInviteClientsCopyLink)),
                                      Builder(
                                          builder: (ctx) => FilledButton.icon(
                                              onPressed: _link.isEmpty
                                                  ? null
                                                  : () => _share(ctx),
                                              icon: const Icon(
                                                  Icons.share_rounded,
                                                  size: 18),
                                              label: Text(AppLocalizations.of(context).coachInviteClientsShare))),
                                    ]),
                              ])),
                          const SizedBox(height: 20),
                          Row(children: [
                            Expanded(
                                child: _stat('$_clients', AppLocalizations.of(context).coachInviteClientsClientsJoined)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _stat('$_coaches', AppLocalizations.of(context).coachInviteClientsCoachesJoined))
                          ]),
                          const SizedBox(height: 10),
                          _stat(AppLocalizations.of(context).coachInviteClientsPoints(_points),
                              AppLocalizations.of(context).coachInviteClientsRewardBalance),
                          const SizedBox(height: 20),
                          Text(AppLocalizations.of(context).coachInviteClientsHowRewards,
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                              AppLocalizations.of(context).coachInviteClientsRewardRules,
                              style: TextStyle(
                                  color: f.textSecondary, height: 1.6)),
                          const SizedBox(height: 24),
                          Text(AppLocalizations.of(context).coachInviteClientsPeopleInvited,
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          Wrap(
                              spacing: 8,
                              children: ['All', 'Clients', 'Coaches']
                                  .map((value) => ChoiceChip(
                                      label: Text(_filterLabel(value)),
                                      selected: _filter == value,
                                      onSelected: (_) =>
                                          setState(() => _filter = value)))
                                  .toList()),
                          const SizedBox(height: 12),
                          if (_history.where(_matches).isEmpty)
                            Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                    AppLocalizations.of(context).coachInviteClientsEmpty,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: f.textMuted))),
                          ..._history.where(_matches).map((r) => _person(r)),
                        ],
                      ))),
            ),
    );
  }

  String _filterLabel(String v) {
    final l = AppLocalizations.of(context);
    return v == 'Clients'
        ? l.coachInviteClientsFilterClients
        : v == 'Coaches'
            ? l.coachInviteClientsFilterCoaches
            : l.coachInviteClientsFilterAll;
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
    final l = AppLocalizations.of(context);
    final isCoach = r['role'] == 'coach';
    final role = isCoach ? l.coachInviteClientsRoleCoach : l.coachInviteClientsRoleClient;
    final status = r['status'] == 'pending'
        ? l.coachInviteClientsStatusPending
        : r['status'] == 'accepted'
            ? l.coachInviteClientsStatusConnected
            : r['status'] == 'refused'
                ? l.coachInviteClientsStatusDeclined
                : l.coachInviteClientsStatusRegistered;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                  backgroundColor: f.card2,
                  child: Icon(
                      isCoach
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
                    Text(l.coachInviteClientsRoleStatus(role, status),
                        style: TextStyle(color: f.textSecondary, fontSize: 12)),
                    if (date != null)
                      Text(DateFormat.yMd(Localizations.localeOf(context).toString()).format(date),
                          style: TextStyle(color: f.textMuted, fontSize: 11))
                  ])),
              const SizedBox(width: 8),
              Text(l.coachInviteClientsPointsAwarded(int.tryParse('${r['pointsAwarded']}') ?? 0),
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.w700)),
            ])));
  }
}
