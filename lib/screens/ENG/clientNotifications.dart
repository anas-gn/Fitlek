import 'package:flutter/material.dart';
import '../../theme/fitlek_theme_extension.dart';

class ClientNotificationsScreen extends StatelessWidget {
  const ClientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, color: f.textMuted, size: 60),
            const SizedBox(height: 16),
            Text(
              'No notifications yet.',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We will notify you when something arrives.',
              style: TextStyle(color: f.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
