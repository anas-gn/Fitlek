import 'package:flutter/material.dart';
import '../../services/apiService.dart';
import 'clientChangeEmail.dart';

class CoachChangeEmail extends StatefulWidget {
  final String token;
  const CoachChangeEmail({super.key, required this.token});
  @override
  State<CoachChangeEmail> createState() => _CoachChangeEmailState();
}

class _CoachChangeEmailState extends State<CoachChangeEmail> {
  late Future<Map<String, dynamic>> _profile;
  @override
  void initState() {
    super.initState();
    _profile = ApiService.get('/coaches/me/profile');
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.data?['ok'] == true)
          return ClientChangeEmailScreen(
              currentEmail: '${snapshot.data?['email'] ?? ''}');
        return Scaffold(
            appBar: AppBar(title: const Text('Change email')),
            body: Center(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => setState(() =>
                            _profile = ApiService.get('/coaches/me/profile')),
                        child:
                            const Text('Could not load your email. Retry'))));
      });
}
