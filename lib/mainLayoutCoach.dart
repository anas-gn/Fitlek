import 'package:flutter/material.dart';
import 'components/ENG/coachHeader.dart';
import 'components/ENG/coachNavbar.dart';
import 'screens/ENG/coachDashboard.dart';
import 'screens/ENG/coachCalendar.dart';
import 'screens/ENG/coachConversations.dart';
import 'screens/ENG/coachClients.dart';
import 'screens/ENG/coachProfile.dart';
import 'screens/ENG/login.dart';
import 'services/apiService.dart';

class MainLayoutCoach extends StatefulWidget {
  const MainLayoutCoach({super.key});

  @override
  State<MainLayoutCoach> createState() => _MainLayoutCoachState();
}

class _MainLayoutCoachState extends State<MainLayoutCoach> {
  int _currentIndex = 0;
  bool _loading = true;

  int? _coachID;
  String _token = '';
  String _firstName = '';
  String _lastName = '';
  String? _avatarUrl;
  String? _email;

  bool get _showHeader => _currentIndex != 4;

  @override
  void initState() {
    super.initState();
    _loadSession();
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
      _lastName = userData['lastName']?.toString() ?? '';
      _avatarUrl = userData['avatarUrl']?.toString();
      _email = userData['email']?.toString();
      _loading = false;
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
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFC6F135))),
      );
    }

    final screens = [
      const CoachDashboard(),
      const CoachCalendar(),
      const CoachConversations(),
      const CoachClients(),
      CoachProfile(
        coachID: _coachID!,
        firstName: _firstName,
        lastName: _lastName,
        avatarUrl: _avatarUrl,
        email: _email,
        token: _token,
        onLogout: _handleLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (_showHeader)
            CoachHeader(
              coachName: '$_firstName $_lastName'.trim(),
              avatarUrl: _avatarUrl ?? '',
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