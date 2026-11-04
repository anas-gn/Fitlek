import 'package:flutter/material.dart';
import '../services/account_security.dart';
import '../theme/fitlek_theme_extension.dart';

class AccountPasswordSheet extends StatefulWidget {
  final String token;
  final Future<void> Function(String current, String password)? save;
  const AccountPasswordSheet({super.key, required this.token, this.save});
  @override
  State<AccountPasswordSheet> createState() => _AccountPasswordSheetState();
}

class _AccountPasswordSheetState extends State<AccountPasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _hidden = [true, true, true];
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.save != null) {
        await widget.save!(_current.text, _password.text);
      } else {
        await AccountSecurity.changePassword(
            token: widget.token,
            currentPassword: _current.text,
            newPassword: _password.text);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is PasswordUpdateException
            ? error.message
            : 'Unable to reach the server. Please try again.';
      });
    }
  }

  Widget _field(String label, TextEditingController controller, int index) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          enabled: !_saving,
          obscureText: _hidden[index],
          autocorrect: false,
          enableSuggestions: false,
          textInputAction:
              index == 2 ? TextInputAction.done : TextInputAction.next,
          autofillHints: [
            index == 0 ? AutofillHints.password : AutofillHints.newPassword
          ],
          onFieldSubmitted: index == 2 ? (_) => _submit() : null,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Enter $label'.toLowerCase();
            if (index == 1 && value.length < 8)
              return 'Use at least 8 characters.';
            if (index == 2 && value != _password.text)
              return 'Passwords do not match.';
            return null;
          },
          decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                  tooltip: _hidden[index] ? 'Show password' : 'Hide password',
                  onPressed: _saving
                      ? null
                      : () => setState(() => _hidden[index] = !_hidden[index]),
                  icon: Icon(
                      _hidden[index]
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20))),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
                key: _form,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                          child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: f.border,
                                  borderRadius: BorderRadius.circular(4)))),
                      const SizedBox(height: 20),
                      Row(children: [
                        Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16)),
                            child:
                                Icon(Icons.shield_outlined, color: cs.primary)),
                        const Spacer(),
                        IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close_rounded)),
                      ]),
                      const SizedBox(height: 16),
                      Text('Secure your account',
                          style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text(
                          'Choose a password with at least 8 characters that you don’t use elsewhere.',
                          style: TextStyle(
                              color: f.textSecondary,
                              height: 1.5,
                              fontSize: 14)),
                      const SizedBox(height: 24),
                      _field('Current password', _current, 0),
                      _field('New password', _password, 1),
                      _field('Confirm password', _confirmation, 2),
                      if (_error != null) ...[
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: cs.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [
                              Icon(Icons.error_outline,
                                  color: cs.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: cs.error, height: 1.4)))
                            ])),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                              onPressed: _saving ? null : _submit,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.check_rounded, size: 20),
                              label: Text(_saving
                                  ? 'Updating password…'
                                  : 'Update password'))),
                    ])),
          ),
        ),
      ),
    );
  }
}
