import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/apiService.dart';
import 'package:fitlek1/l10n/app_localizations.dart';

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
      setState(() => _error = AppLocalizations.of(context).clientChangeEmailInvalidEmail);
      return;
    }
    if (!resend && _step > 0 && _code.text.length != 6) {
      setState(() => _error = AppLocalizations.of(context).clientChangeEmailInvalidCode);
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
          () => _error = result['message'] ?? AppLocalizations.of(context).clientChangeEmailVerifyFailed);
      return;
    }
    if (resend) {
      _code.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).clientChangeEmailCodeSent)));
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
      appBar: AppBar(title: Text(AppLocalizations.of(context).clientChangeEmailTitle)),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text(AppLocalizations.of(context).clientChangeEmailStepOf(_step + 1, 3),
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 16),
          Text(
              _step == 0
                  ? AppLocalizations.of(context).clientChangeEmailHeadingNew
                  : _step == 1
                      ? AppLocalizations.of(context).clientChangeEmailHeadingVerifyCurrent
                      : AppLocalizations.of(context).clientChangeEmailHeadingVerifyNew,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(_step == 0
              ? AppLocalizations.of(context).clientChangeEmailIntroStart(widget.currentEmail)
              : AppLocalizations.of(context).clientChangeEmailIntroCode(target)),
          const SizedBox(height: 24),
          if (_step == 0)
            TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration:
                    InputDecoration(labelText: AppLocalizations.of(context).clientChangeEmailNewEmailLabel))
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
                    InputDecoration(labelText: AppLocalizations.of(context).clientChangeEmailCodeLabel)),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error))
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _busy ? null : () => _submit(),
              child: Text(_busy
                  ? AppLocalizations.of(context).clientChangeEmailPleaseWait
                  : _step == 0
                      ? AppLocalizations.of(context).clientChangeEmailSendCodeButton
                      : _step == 1
                          ? AppLocalizations.of(context).clientChangeEmailVerifySendButton
                          : AppLocalizations.of(context).clientChangeEmailConfirmButton)),
          if (_step > 0)
            TextButton(
                onPressed: _busy ? null : () => _submit(resend: true),
                child: Text(AppLocalizations.of(context).clientChangeEmailResend)),
          if (_step > 0)
            TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _step = 0;
                          _code.clear();
                          _error = null;
                        }),
                child: Text(AppLocalizations.of(context).clientChangeEmailStartAgain)),
        ]),
      ))),
    );
  }
}
