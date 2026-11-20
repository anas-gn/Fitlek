import 'package:fitlek1/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'coachProfile.dart' show ApiConfig;
import '../../theme/fitlek_theme_extension.dart';

class CoachChangePassword extends StatefulWidget {
  final String token;
  const CoachChangePassword({super.key, required this.token});

  @override
  State<CoachChangePassword> createState() => _CoachChangePasswordState();
}

class _CoachChangePasswordState extends State<CoachChangePassword> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cur = _currentCtrl.text;
    final newP = _newCtrl.text;
    final conf = _confirmCtrl.text;
    if (cur.isEmpty || newP.isEmpty || conf.isEmpty) {
      setState(() => _errorMsg = AppLocalizations.of(context).coachChangePasswordAllRequired);
      return;
    }
    if (newP != conf) {
      setState(() => _errorMsg = AppLocalizations.of(context).coachChangePasswordMismatch);
      return;
    }
    if (newP.length < 8) {
      setState(() => _errorMsg = AppLocalizations.of(context).coachChangePasswordTooShort);
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/account/password'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'currentPassword': cur, 'newPassword': newP}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context, true); // return true to indicate success
      } else {
        setState(
            () => _errorMsg = body['error'] ?? AppLocalizations.of(context).coachChangePasswordFailed);
      }
    } catch (e) {
      setState(() => _errorMsg = AppLocalizations.of(context).coachChangePasswordServerError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggleObscure,
  }) {
    final f = context.fitlek;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: f.card2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: f.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: f.textMuted),
          icon: Icon(Icons.lock_outline_rounded, color: f.textMuted, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: f.textMuted,
                size: 18),
            onPressed: toggleObscure,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return Scaffold(
      backgroundColor: f.card,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context).coachChangePasswordTitle,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).coachChangePasswordSubtitle,
                style: TextStyle(color: f.textMuted, fontSize: 14)),
            SizedBox(height: 24),
            _buildField(
              controller: _currentCtrl,
              hint: AppLocalizations.of(context).coachChangePasswordCurrent,
              obscure: _obscureCurrent,
              toggleObscure: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            _buildField(
              controller: _newCtrl,
              hint: AppLocalizations.of(context).coachChangePasswordNew,
              obscure: _obscureNew,
              toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
            ),
            _buildField(
              controller: _confirmCtrl,
              hint: AppLocalizations.of(context).coachChangePasswordConfirm,
              obscure: _obscureConfirm,
              toggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            if (_errorMsg != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: f.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: f.error, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: TextStyle(color: f.error, fontSize: 13))),
                  ],
                ),
              ),
            ],
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: cs.onPrimary, strokeWidth: 2))
                    : Text(AppLocalizations.of(context).coachChangePasswordUpdate,
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
