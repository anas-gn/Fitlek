import 'dart:async';
import 'package:flutter/material.dart';
import 'components/ENG/coachHeader.dart';
import 'components/ENG/coachNavbar.dart';
import 'screens/ENG/coachDashboard.dart';
import 'screens/ENG/coachCalendar.dart';
import 'screens/ENG/coachConversations.dart';
import 'screens/ENG/coachClients.dart';
import 'screens/ENG/coachProfile.dart';
import 'screens/ENG/coachNotifications.dart';
import 'screens/ENG/coachChat.dart';
import 'models/coachConversation.dart';
import 'screens/ENG/login.dart';
import 'services/apiService.dart';
class MainLayoutCoach extends StatefulWidget {
  const MainLayoutCoach({super.key});

  @override
  State<MainLayoutCoach> createState() => _MainLayoutCoachState();
}

class _MainLayoutCoachState extends State<MainLayoutCoach> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _loading = true;

  int? _coachID;
  String _token = '';
  String _firstName = '';
  String _lastName = '';
  String? _avatarUrl;
  String? _email;

  int _unreadCount = 0;
  int _chatRevision = 0;
  int _dashboardRevision = 0;
  Timer? _pollTimer;

  bool get _showHeader => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSession();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
    }
  }

  Future<void> _loadSession() async {
    final userData = await ApiService.getUserData();
    final token = await ApiService.getToken();

    if (!mounted) return;

    if (userData == null || token == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    setState(() {
      _coachID = userData['id'] is int ? userData['id'] as int : int.tryParse(userData['id'].toString());
      _token = token;
      _firstName = userData['firstName']?.toString() ?? '';
      _loading = false;
    });

    // Fetch the full authenticated coach profile (real name + avatar) from the
    // existing backend endpoint so the header shows real, backend-driven data.
    _loadCoachProfile();

    // Notification unread count: one centralized fetch + controlled polling
    // (no realtime/socket infrastructure exists in this project).
    _loadUnreadCount();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) => _loadUnreadCount());
  }

  Future<void> _loadUnreadCount() async {
    final res = await ApiService.get('/coach/notifications/unread-count');
    if (!mounted || res['ok'] != true) return;
    final count = res['count'];
    setState(() => _unreadCount = count is int ? count : int.tryParse('$count') ?? 0);
  }

  Future<void> _openNotifications() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CoachNotifications()),
    );
    if (!mounted) return;
    await _loadUnreadCount();
    if (result != null) _handleNotificationTap(result);
  }

  void _handleNotificationTap(Map<String, dynamic> n) {
    switch (n['type']) {
      case 'new_message':
        final convId = n['relatedEntityID'];
        if (convId == null) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CoachChat(
            conversation: CoachConversation(
              id: convId.toString(),
              clientId: '',
              clientName: (n['actorName'] ?? 'Client').toString(),
              clientPhotoUrl: (n['actorAvatar'] ?? '').toString(),
              lastMessage: '',
              lastMessageTime: DateTime.now(),
              unreadCount: 0,
            ),
          ),
        )).then((_) => _loadUnreadCount());
        break;
      case 'new_reservation':
      case 'upcoming_session':
        setState(() => _currentIndex = 1); // Coach Calendar tab
        break;
      case 'new_invitation':
      case 'new_client':
        setState(() => _currentIndex = 3); // My Clients / invitations
        break;
    }
  }

  Future<void> _loadCoachProfile() async {
    final res = await ApiService.get('/coach/profile');
    if (!mounted || res['ok'] != true) return;
    setState(() {
      _firstName = res['firstName']?.toString() ?? _firstName;
      _lastName = res['lastName']?.toString() ?? _lastName;
      _avatarUrl = (res['avatarUrl']?.toString().isNotEmpty ?? false)
          ? res['avatarUrl'].toString()
          : _avatarUrl;
      _email = res['email']?.toString() ?? _email;
    });
  }

  Future<void> _handleLogout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _coachID == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    final screens = [
      CoachDashboard(
        key: ValueKey(_dashboardRevision),
        onViewCalendar: () => setState(() => _currentIndex = 1),
        onViewNotifications: _openNotifications,
        onViewInvitations: () => setState(() => _currentIndex = 3),
      ),
      const CoachCalendar(),
      CoachConversations(key: ValueKey(_chatRevision)),
      CoachClients(
        onInvitationAccepted: () {
          if (!mounted) return;
          setState(() => _chatRevision++);
        },
        onInvitationsChanged: () {
          if (!mounted) return;
          setState(() => _dashboardRevision++);
        },
      ),
      CoachProfile(
        coachID: _coachID!,
        firstName: _firstName,
        lastName: _lastName,
        avatarUrl: _avatarUrl,
        email: _email,
        token: _token,
        onLogout: _handleLogout,
        onProfileUpdated: _loadCoachProfile,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (_showHeader)
            CoachHeader(
              coachName: '$_firstName $_lastName'.trim(),
              firstName: _firstName,
              avatarUrl: _avatarUrl ?? '',
              unreadCount: _unreadCount,
              onNotificationTap: _openNotifications,
              onAvatarTap: () => setState(() => _currentIndex = 4),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ]),
      ),
      bottomNavigationBar: CoachNavbar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}