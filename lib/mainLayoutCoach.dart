import 'package:flutter/material.dart';
import 'components/ENG/coachHeader.dart';
import 'components/ENG/coachNavbar.dart';
import 'screens/ENG/coachDashboard.dart';
import 'screens/ENG/coachCalendar.dart';
import 'screens/ENG/coachConversations.dart';
import 'screens/ENG/coachClients.dart';
import 'screens/ENG/coachProfile.dart';

class MainLayoutCoach extends StatefulWidget {
  const MainLayoutCoach({super.key});

  @override
  State<MainLayoutCoach> createState() => _MainLayoutCoachState();
}

class _MainLayoutCoachState extends State<MainLayoutCoach> {
  int _currentIndex = 0;

  // These will be loaded from the server via coachProfile screen,
  // but we keep lightweight defaults here to avoid a blocking load.
  String _coachName   = 'Coach';
  String _avatarUrl   = '';

  final List<Widget> _screens = const [
    CoachDashboard(),
    CoachCalendar(),
    CoachConversations(),
    CoachClients(),
    CoachProfile(),
  ];

  // Profile tab (index 4) renders its own header inside the screen itself,
  // so we hide the global header there.
  bool get _showHeader => _currentIndex != 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (_showHeader)
            CoachHeader(
              coachName: _coachName,
              avatarUrl: _avatarUrl,
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
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
