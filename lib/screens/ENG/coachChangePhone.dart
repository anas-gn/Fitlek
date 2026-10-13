import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'coachProfile.dart' show ApiConfig;
import '../../theme/fitlek_theme_extension.dart';

class CoachChangePhone extends StatefulWidget {
  final String token;
  final String currentPhone;
  const CoachChangePhone(
      {super.key, required this.token, this.currentPhone = ''});

  @override
  State<CoachChangePhone> createState() => _CoachChangePhoneState();
}

class _CoachChangePhoneState extends State<CoachChangePhone> {
  final _countryCodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _parseCurrentPhone();
  }

  void _parseCurrentPhone() {
    String phone = widget.currentPhone.trim();
    if (phone.isEmpty) {
      _countryCodeCtrl.text = '+212';
      return;
    }

    // Simple heuristic: if it starts with '+', extract the first 4 chars as country code (e.g., +212)
    // Adjust logic if needed for longer/shorter country codes.
    if (phone.startsWith('+')) {
      int spaceIdx = phone.indexOf(' ');
      if (spaceIdx != -1) {
        _countryCodeCtrl.text = phone.substring(0, spaceIdx);
        _phoneCtrl.text = phone.substring(spaceIdx + 1).replaceAll(' ', '');
      } else if (phone.startsWith('+212')) {
        _countryCodeCtrl.text = '+212';
        _phoneCtrl.text = phone.substring(4);
      } else if (phone.length > 3) {
        // Fallback for other + codes, just split after 3 digits (e.g., +33)
        // This is a naive split for demonstration, but works well for testing.
        _countryCodeCtrl.text = phone.substring(0, 4);
        _phoneCtrl.text = phone.substring(4);
      }
    } else {
      _countryCodeCtrl.text = '+212';
      if (phone.startsWith('0')) phone = phone.substring(1);
      _phoneCtrl.text = phone;
    }
  }

  @override
  void dispose() {
    _countryCodeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final country = _countryCodeCtrl.text.trim();
    String number = _phoneCtrl.text.trim();

    if (country.isEmpty || number.isEmpty) {
      setState(
          () => _errorMsg = 'Please enter both country code and phone number.');
      return;
    }

    if (number.startsWith('0')) {
      number = number.substring(1); // Remove leading zero
    }

    final newPhone = '$country$number';

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final res = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/account/phone'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'phoneNumber': newPhone}),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(
            context, newPhone); // return the new phone string to update UI
      } else {
        setState(() =>
            _errorMsg = body['error'] ?? 'Failed to update phone number.');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Server error. Please check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: Text('Update Phone',
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
            Text('Enter your new phone number.',
                style: TextStyle(color: f.textMuted, fontSize: 14)),
            SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 90,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: f.card2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: f.border),
                  ),
                  child: TextField(
                    controller: _countryCodeCtrl,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '+212',
                      hintStyle: TextStyle(color: f.textMuted),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: f.card2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: f.border),
                    ),
                    child: TextField(
                      controller: _phoneCtrl,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          letterSpacing: 1.5),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '6XX XXX XXX',
                        hintStyle:
                            TextStyle(color: f.textMuted, letterSpacing: 0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMsg != null) ...[
              SizedBox(height: 16),
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
                    : Text('Save Changes',
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
