import re,json,sys
p='lib/screens/ENG/coachClients.dart'
s=open(p,encoding='utf-8',newline='').read().replace('\r\n','\n')
def R(a,b,cnt=1):
    global s
    assert s.count(a)>=1,a
    s=s.replace(a,b)
s=s.replace("import 'package:flutter/material.dart';","import 'package:flutter/material.dart';\nimport 'package:intl/intl.dart';\nimport 'package:fitlek1/l10n/app_localizations.dart';",1)
R("""          content: Text(
            accept
                ? 'Invitation accepted: +20 points. The client is now available in Chats.'
                : 'Invitation declined.',
          ),""","""          content: Text(
            accept
                ? AppLocalizations.of(context).coachClientsInviteAccepted
                : AppLocalizations.of(context).coachClientsInviteDeclined,
          ),""")
R("result['message']?.toString() ?? 'Unable to update invitation.'","result['message']?.toString() ??\n            AppLocalizations.of(context).coachClientsInviteUpdateFailed")
R("Text('YOUR CLIENTS',","Text(AppLocalizations.of(context).coachClientsYourClients,")
R("Text('My Clients',","Text(AppLocalizations.of(context).coachClientsTitle,")
R("""                    ? 'Loading…'
                    : count == 0
                        ? 'Bookings and invitations bring your clients here'
                        : '$count client${count == 1 ? '' : 's'} • Sessions and conversations',""","""                    ? AppLocalizations.of(context).coachClientsLoading
                    : count == 0
                        ? AppLocalizations.of(context).coachClientsEmptySubtitle
                        : AppLocalizations.of(context).coachClientsCountSubtitle(count),""")
R("Text('Invite',","Text(AppLocalizations.of(context).coachClientsInvite,")
R("_statBox('${_clients.length}', 'Total',","_statBox('${_clients.length}', AppLocalizations.of(context).coachClientsStatTotal,")
R("'Pending', f.warning","AppLocalizations.of(context).coachClientsStatPending, f.warning")
R("'Upcoming', cs.primary","AppLocalizations.of(context).coachClientsStatUpcoming, cs.primary")
R("hintText: 'Search clients...'","hintText: AppLocalizations.of(context).coachClientsSearchHint")
R("child: Text(filter,","child: Text(_filterLabel(filter),")
R("tooltip: 'Sort',","tooltip: AppLocalizations.of(context).coachClientsSort,")
R("'Name A–Z'","AppLocalizations.of(context).coachClientsSortAz")
R("'Name Z–A'","AppLocalizations.of(context).coachClientsSortZa")
R("'Newest connected'","AppLocalizations.of(context).coachClientsSortNewest")
R("""              'CLIENT INVITATIONS',""","""              AppLocalizations.of(context).coachClientsInvitations,""")
R("'$_pendingInvitationCount pending',","AppLocalizations.of(context).coachClientsPendingCount(_pendingInvitationCount),")
R("name.isEmpty ? 'Client' : name","name.isEmpty ? AppLocalizations.of(context).coachClientsClientFallback : name")
R("""                            ? 'Pending'
                            : isAccepted
                                ? 'Accepted · +${invitation['pointsEarned'] ?? 20} pts'
                                : 'Declined',""","""                            ? AppLocalizations.of(context).coachClientsStatusPending
                            : isAccepted
                                ? AppLocalizations.of(context).coachClientsStatusAccepted(
                                    '${invitation['pointsEarned'] ?? 20}')
                                : AppLocalizations.of(context).coachClientsStatusDeclined,""")
R("const Text('Decline')","Text(AppLocalizations.of(context).coachClientsDecline)")
R("const Text('Accept')","Text(AppLocalizations.of(context).coachClientsAccept)")
R("""    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';""","""    final l10n = AppLocalizations.of(context);
    if (difference.inMinutes < 1) return l10n.coachClientsJustNow;
    if (difference.inHours < 1) return l10n.coachClientsMinutesAgo(difference.inMinutes);
    if (difference.inDays < 1) return l10n.coachClientsHoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.coachClientsDaysAgo(difference.inDays);
    return DateFormat.yMd(Localizations.localeOf(context).toString()).format(date);""")
R("'Your coaching clients will appear here'","AppLocalizations.of(context).coachClientsEmptyTitle")
R("'Clients appear when they book with you or when you accept their invitation.'","AppLocalizations.of(context).coachClientsEmptyBody")
R("""    if (date == null) return 'Upcoming session';
    return 'Next: ${date.day}/${date.month} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';""","""    final l10n = AppLocalizations.of(context);
    if (date == null) return l10n.coachClientsUpcomingSession;
    final loc = Localizations.localeOf(context).toString();
    return l10n.coachClientsNextSession(
        DateFormat.Md(loc).format(date), DateFormat.Hm(loc).format(date));""")
R("""'${_count(c, 'sessionCount')} sessions • ${_count(c, 'upcomingCount')} upcoming • ${_count(c, 'pendingCount')} pending',""","""AppLocalizations.of(context).coachClientsSessionSummary(
                      _count(c, 'sessionCount'),
                      _count(c, 'upcomingCount'),
                      _count(c, 'pendingCount')),""")
R("Text('Unable to load clients',","Text(AppLocalizations.of(context).coachClientsLoadError,")
R("Text('Retry',","Text(AppLocalizations.of(context).coachClientsRetry,")
R("""                  ? 'No clients match your search.'
                  : 'No clients match this filter.',""","""                  ? AppLocalizations.of(context).coachClientsNoMatchSearch
                  : AppLocalizations.of(context).coachClientsNoMatchFilter,""")
R("  Widget _buildSortButton() {","""  String _filterLabel(String filter) {
    final l10n = AppLocalizations.of(context);
    switch (filter) {
      case 'Upcoming':
        return l10n.coachClientsStatUpcoming;
      case 'Pending':
        return l10n.coachClientsStatPending;
      default:
        return l10n.coachClientsFilterAll;
    }
  }

  Widget _buildSortButton() {""")
open(p,'w',encoding='utf-8',newline='').write(s.replace('\n','\r\n'))

en={
"coachClientsInviteAccepted":"Invitation accepted: +20 points. The client is now available in Chats.",
"coachClientsInviteDeclined":"Invitation declined.",
"coachClientsInviteUpdateFailed":"Unable to update invitation.",
"coachClientsYourClients":"YOUR CLIENTS",
"coachClientsTitle":"My Clients",
"coachClientsLoading":"Loading…",
"coachClientsEmptySubtitle":"Bookings and invitations bring your clients here",
"coachClientsCountSubtitle":"{count, plural, =1{1 client • Sessions and conversations} other{{count} clients • Sessions and conversations}}",
"coachClientsInvite":"Invite",
"coachClientsStatTotal":"Total",
"coachClientsStatPending":"Pending",
"coachClientsStatUpcoming":"Upcoming",
"coachClientsFilterAll":"All",
"coachClientsSearchHint":"Search clients...",
"coachClientsSort":"Sort",
"coachClientsSortAz":"Name A–Z",
"coachClientsSortZa":"Name Z–A",
"coachClientsSortNewest":"Newest connected",
"coachClientsInvitations":"CLIENT INVITATIONS",
"coachClientsPendingCount":"{count} pending",
"coachClientsClientFallback":"Client",
"coachClientsStatusPending":"Pending",
"coachClientsStatusAccepted":"Accepted · +{points} pts",
"coachClientsStatusDeclined":"Declined",
"coachClientsDecline":"Decline",
"coachClientsAccept":"Accept",
"coachClientsJustNow":"Just now",
"coachClientsMinutesAgo":"{count}m ago",
"coachClientsHoursAgo":"{count}h ago",
"coachClientsDaysAgo":"{count}d ago",
"coachClientsEmptyTitle":"Your coaching clients will appear here",
"coachClientsEmptyBody":"Clients appear when they book with you or when you accept their invitation.",
"coachClientsUpcomingSession":"Upcoming session",
"coachClientsNextSession":"Next: {date} at {time}",
"coachClientsSessionSummary":"{sessions, plural, =1{1 session} other{{sessions} sessions}} • {upcoming} upcoming • {pending} pending",
"coachClientsLoadError":"Unable to load clients",
"coachClientsRetry":"Retry",
"coachClientsNoMatchSearch":"No clients match your search.",
"coachClientsNoMatchFilter":"No clients match this filter.",
}
fr={
"coachClientsInviteAccepted":"Invitation acceptée : +20 points. Le client est maintenant disponible dans les discussions.",
"coachClientsInviteDeclined":"Invitation refusée.",
"coachClientsInviteUpdateFailed":"Impossible de mettre à jour l’invitation.",
"coachClientsYourClients":"VOS CLIENTS",
"coachClientsTitle":"Mes clients",
"coachClientsLoading":"Chargement…",
"coachClientsEmptySubtitle":"Les réservations et les invitations amènent vos clients ici",
"coachClientsCountSubtitle":"{count, plural, =1{1 client • Séances et conversations} other{{count} clients • Séances et conversations}}",
"coachClientsInvite":"Inviter",
"coachClientsStatTotal":"Total",
"coachClientsStatPending":"En attente",
"coachClientsStatUpcoming":"À venir",
"coachClientsFilterAll":"Tous",
"coachClientsSearchHint":"Rechercher des clients...",
"coachClientsSort":"Trier",
"coachClientsSortAz":"Nom A–Z",
"coachClientsSortZa":"Nom Z–A",
"coachClientsSortNewest":"Dernières connexions",
"coachClientsInvitations":"INVITATIONS DE CLIENTS",
"coachClientsPendingCount":"{count, plural, =1{1 en attente} other{{count} en attente}}",
"coachClientsClientFallback":"Client",
"coachClientsStatusPending":"En attente",
"coachClientsStatusAccepted":"Acceptée · +{points} pts",
"coachClientsStatusDeclined":"Refusée",
"coachClientsDecline":"Refuser",
"coachClientsAccept":"Accepter",
"coachClientsJustNow":"À l’instant",
"coachClientsMinutesAgo":"il y a {count} min",
"coachClientsHoursAgo":"il y a {count} h",
"coachClientsDaysAgo":"il y a {count} j",
"coachClientsEmptyTitle":"Vos clients de coaching apparaîtront ici",
"coachClientsEmptyBody":"Les clients apparaissent lorsqu’ils réservent avec vous ou lorsque vous acceptez leur invitation.",
"coachClientsUpcomingSession":"Séance à venir",
"coachClientsNextSession":"Prochaine : {date} à {time}",
"coachClientsSessionSummary":"{sessions, plural, =1{1 séance} other{{sessions} séances}} • {upcoming} à venir • {pending} en attente",
"coachClientsLoadError":"Impossible de charger les clients",
"coachClientsRetry":"Réessayer",
"coachClientsNoMatchSearch":"Aucun client ne correspond à votre recherche.",
"coachClientsNoMatchFilter":"Aucun client ne correspond à ce filtre.",
}
# metadata (en)
def ph(**k): return {"placeholders":{n:{"type":t} for n,t in k.items()}}
meta={"coachClientsCountSubtitle":ph(count="int"),"coachClientsPendingCount":ph(count="int"),
"coachClientsStatusAccepted":ph(points="String"),"coachClientsMinutesAgo":ph(count="int"),
"coachClientsHoursAgo":ph(count="int"),"coachClientsDaysAgo":ph(count="int"),
"coachClientsNextSession":ph(date="String",time="String"),
"coachClientsSessionSummary":ph(sessions="int",upcoming="int",pending="int")}
json.dump(en,open('lib/l10n/parts/g1c_tmp/clients.en.json','w',encoding='utf-8'),ensure_ascii=False,indent=1)
json.dump(fr,open('lib/l10n/parts/g1c_tmp/clients.fr.json','w',encoding='utf-8'),ensure_ascii=False,indent=1)
json.dump(meta,open('lib/l10n/parts/g1c_tmp/clients.meta.json','w',encoding='utf-8'),ensure_ascii=False,indent=1)
