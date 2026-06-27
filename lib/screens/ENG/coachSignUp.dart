import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/names.dart';
import '../../services/apiService.dart';
import 'coachSignIn.dart';

class CoachSignUp extends StatefulWidget {
  const CoachSignUp({super.key});
  @override
  State<CoachSignUp> createState() => _CoachSignUpState();
}

class _CoachSignUpState extends State<CoachSignUp>
    with SingleTickerProviderStateMixin {
  final _firstNameCtrl   = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmCtrl     = TextEditingController();
  final _bioCtrl         = TextEditingController();
  final _instagramCtrl   = TextEditingController();

  String _gender          = 'Male';
  bool _obscurePassword   = true;
  bool _obscureConfirm    = true;
  bool _isLoading         = false;

  Uint8List? _certBytes;
  String?    _certFileName;
  String?    _certMime;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    _bioCtrl.dispose(); _instagramCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _certBytes    = file.bytes!;
      _certFileName = file.name;
      _certMime     = file.extension == 'pdf'
          ? 'application/pdf'
          : 'image/${file.extension?.toLowerCase() ?? 'jpeg'}';
    });
  }

  void _signUp() async {
    final firstName   = _firstNameCtrl.text.trim();
    final lastName    = _lastNameCtrl.text.trim();
    final email       = _emailCtrl.text.trim();
    final password    = _passwordCtrl.text;
    final confirm     = _confirmCtrl.text;
    final bio         = _bioCtrl.text.trim();
    final instagram   = _instagramCtrl.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty ||
        password.isEmpty || confirm.isEmpty || bio.isEmpty || instagram.isEmpty) {
      ApiService.showError(context, 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      ApiService.showError(context, 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      ApiService.showError(context, 'Password must be at least 6 characters.');
      return;
    }
    if (_certBytes == null) {
      ApiService.showError(context, 'Please upload your certificate.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.uploadMultipart(
      '/coach/register',
      fields: {
        'firstName':    firstName,
        'lastName':     lastName,
        'email':        email,
        'password':     password,
        'confirmPassword': confirm,
        'gender':       _gender,
        'bio':          bio,
        'instagramPage': instagram,
      },
      fileBytes: _certBytes!,
      fileField: 'certificate',
      fileName:  _certFileName ?? 'certificate',
      mimeType:  _certMime    ?? 'image/jpeg',
      auth: false,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['ok'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFF1A3008), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFFA3FF12), size: 36)),
            const SizedBox(height: 18),
            const Text('Registration Submitted', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text('Your application is pending manager approval. You will be notified once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.6)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CoachSignIn()), (_) => false),
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('Go to Sign In', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)))),
            ),
          ])),
        ),
      );
    } else {
      ApiService.showError(context, result['message'] ?? 'Registration failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: FadeTransition(opacity: _fadeAnim,
        child: Column(children: [
          _buildTopBar(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 24),
              const Text('Create Your\nCoach Profile.',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Join ${AppNames.appName} and start training your clients.',
                style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
              const SizedBox(height: 28),

              // ── Personal info ──
              _sectionLabel('Personal Information'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(_firstNameCtrl, 'First Name', 'John')),
                const SizedBox(width: 12),
                Expanded(child: _field(_lastNameCtrl, 'Last Name', 'Doe')),
              ]),
              const SizedBox(height: 14),
              _field(_emailCtrl, 'Email', 'your@email.com', keyboard: TextInputType.emailAddress),
              const SizedBox(height: 18),
              _buildGenderSelector(),
              const SizedBox(height: 18),

              // ── Password ──
              _sectionLabel('Password'),
              const SizedBox(height: 12),
              _passwordField(_passwordCtrl, 'Password', _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
              const SizedBox(height: 14),
              _passwordField(_confirmCtrl, 'Confirm Password', _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 18),

              // ── About ──
              _sectionLabel('About'),
              const SizedBox(height: 12),
              _field(_bioCtrl, 'Bio', 'Tell your clients about yourself...', maxLines: 4),
              const SizedBox(height: 14),
              _field(_instagramCtrl, 'Instagram Page', '@yourhandle',
                prefix: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 18)),
              const SizedBox(height: 18),

              // ── Certificate ──
              _sectionLabel('Certificate'),
              const SizedBox(height: 12),
              _buildCertificateSelector(),
              const SizedBox(height: 36),

              _buildSignUpButton(),
              const SizedBox(height: 40),
            ]),
          )),
        ]),
      )),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18))),
      const SizedBox(width: 16),
      const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    ]));

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Widget _field(TextEditingController ctrl, String label, String hint,
      {int maxLines = 1, TextInputType? keyboard, Widget? prefix}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
          prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: prefix) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: const Color(0xFF111111),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  Widget _passwordField(TextEditingController ctrl, String label, bool obscure, VoidCallback toggle) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(hintText: '••••••••', hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
          suffixIcon: GestureDetector(onTap: toggle,
            child: Padding(padding: const EdgeInsets.only(right: 14),
              child: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.4), size: 20))),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: const Color(0xFF111111),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  Widget _buildGenderSelector() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Gender', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Row(children: ['Male', 'Female', 'Other'].map((g) {
      final sel = _gender == g;
      return Expanded(child: GestureDetector(onTap: () => setState(() => _gender = g),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.08))),
          child: Center(child: Text(g, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))))));
    }).toList()),
  ]);

  Widget _buildCertificateSelector() => GestureDetector(
    onTap: _pickCertificate,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity, height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _certBytes != null ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.08), width: 1.5)),
      child: _certBytes != null
        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFA3FF12), size: 30),
            const SizedBox(height: 6),
            Text(_certFileName ?? 'Certificate selected', style: const TextStyle(color: Color(0xFFA3FF12), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Tap to change', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ])
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cloud_upload_rounded, color: Colors.white.withOpacity(0.3), size: 30),
            const SizedBox(height: 6),
            Text('Tap to upload certificate', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
            const SizedBox(height: 2),
            Text('JPG, PNG or PDF · Max 10 MB', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
          ]),
    ),
  );

  Widget _buildSignUpButton() => GestureDetector(
    onTap: _isLoading ? null : _signUp,
    child: Container(width: double.infinity, height: 56,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Center(child: _isLoading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
        : const Text('Create Account', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)))),
  );
}
