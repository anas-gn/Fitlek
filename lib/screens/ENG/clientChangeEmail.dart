import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/apiService.dart';

class ClientChangeEmailScreen extends StatefulWidget {
  final String currentEmail;
  const ClientChangeEmailScreen({super.key, required this.currentEmail});
  @override
  State<ClientChangeEmailScreen> createState() =>
      _ClientChangeEmailScreenState();
}

class _ClientChangeEmailScreenState extends State<ClientChangeEmailScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  int _step = 0;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit({bool resend = false}) async {
    if (_busy) return;
    final email = _email.text.trim().toLowerCase();
    if (_step == 0 && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid new email address.');
      return;
    }
    if (!resend && _step > 0 && _code.text.length != 6) {
      setState(() => _error = 'Enter the six-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final action = resend
        ? 'resend'
        : _step == 0
            ? 'start'
            : _step == 1
                ? 'verify-old'
                : 'confirm';
    final result = await ApiService.post('/auth/account/email-change/$action',
        _step == 0 ? {'newEmail': email} : {'otp': _code.text});
    if (!mounted) return;
    setState(() => _busy = false);
    if (result['ok'] != true) {
      setState(
          () => _error = result['message'] ?? 'Could not verify your email.');
      return;
    }
    if (resend) {
      _code.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('A new code was sent.')));
    } else if (_step == 2) {
      Navigator.pop(context, result['email']);
    } else {
      setState(() {
        _step++;
        _code.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _step == 1 ? widget.currentEmail : _email.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Change email')),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text('STEP ${_step + 1} OF 3',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 16),
          Text(
              _step == 0
                  ? 'Your new email address'
                  : _step == 1
                      ? 'Verify your current email'
                      : 'Verify your new email',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(_step == 0
              ? 'We will send a code to ${widget.currentEmail}, then to your new email. Your email changes only after both are verified.'
              : 'Enter the six-digit code sent to $target. The code expires in 10 minutes.'),
          const SizedBox(height: 24),
          if (_step == 0)
            TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration:
                    const InputDecoration(labelText: 'New email address'))
          else
            TextField(
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)
                ],
                decoration:
                    const InputDecoration(labelText: 'Verification code')),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error))
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _busy ? null : () => _submit(),
              child: Text(_busy
                  ? 'Please wait…'
                  : _step == 0
                      ? 'Send code to current email'
                      : _step == 1
                          ? 'Verify & send new email code'
                          : 'Verify & change email')),
          if (_step > 0)
            TextButton(
                onPressed: _busy ? null : () => _submit(resend: true),
                child: const Text('Resend code (after 60 seconds)')),
          if (_step > 0)
            TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _step = 0;
                          _code.clear();
                          _error = null;
                        }),
                child: const Text('Start again')),
        ]),
      ))),
    );
  }
}
