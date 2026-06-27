import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/apiService.dart';

class ManagerCreateCoach extends StatefulWidget {
  const ManagerCreateCoach({super.key});
  @override
  State<ManagerCreateCoach> createState() => _ManagerCreateCoachState();
}

class _ManagerCreateCoachState extends State<ManagerCreateCoach> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _bioCtrl       = TextEditingController();
  final _instagramCtrl = TextEditingController();
  String _gender = 'Male';
  bool _loading = false;

  Uint8List? _certBytes;
  String?    _certFileName;
  String?    _certMime;

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose();
    _bioCtrl.dispose(); _instagramCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;
    setState(() {
      _certBytes    = file.bytes!;
      _certFileName = file.name;
      _certMime     = file.extension == 'pdf' ? 'application/pdf' : 'image/${file.extension?.toLowerCase() ?? 'jpeg'}';
    });
  }

  void _save() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty || _bioCtrl.text.trim().isEmpty ||
        _instagramCtrl.text.trim().isEmpty) {
      ApiService.showError(context, 'All fields are required.');
      return;
    }
    if (_certBytes == null) {
      ApiService.showError(context, 'Certificate file is required.');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.uploadMultipart(
      '/manager/coaches/create',
      fields: {
        'firstName':     _firstNameCtrl.text.trim(),
        'lastName':      _lastNameCtrl.text.trim(),
        'email':         _emailCtrl.text.trim(),
        'gender':        _gender,
        'bio':           _bioCtrl.text.trim(),
        'instagramPage': _instagramCtrl.text.trim(),
      },
      fileBytes: _certBytes!,
      fileField: 'certificate',
      fileName:  _certFileName ?? 'certificate',
      mimeType:  _certMime    ?? 'image/jpeg',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['ok'] == true) Navigator.of(context).pop(true);
    else ApiService.showError(context, result['message'] ?? 'Create failed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        _topBar(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            _sectionLabel('Personal Information'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field(_firstNameCtrl, 'First Name', 'John')),
              const SizedBox(width: 12),
              Expanded(child: _field(_lastNameCtrl, 'Last Name', 'Doe')),
            ]),
            const SizedBox(height: 14),
            _field(_emailCtrl, 'Email', 'coach@fitlek.com', keyboard: TextInputType.emailAddress),
            const SizedBox(height: 18),
            _sectionLabel('Gender'),
            const SizedBox(height: 10),
            _genderSelector(),
            const SizedBox(height: 22),
            _sectionLabel('About'),
            const SizedBox(height: 10),
            _field(_bioCtrl, 'Bio', 'Tell clients about this coach...', maxLines: 4),
            const SizedBox(height: 22),
            _sectionLabel('Social & Certificate'),
            const SizedBox(height: 10),
            _field(_instagramCtrl, 'Instagram Page', '@coachhandle',
                prefix: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 18)),
            const SizedBox(height: 14),
            _buildCertSelector(),
            const SizedBox(height: 36),
            _submitBtn(),
            const SizedBox(height: 32),
          ]),
        )),
      ])),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18))),
      const SizedBox(width: 16),
      const Text('Create Coach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    ]));

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Widget _field(TextEditingController ctrl, String label, String hint,
      {TextInputType? keyboard, int maxLines = 1, Widget? prefix}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: keyboard, maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: prefix) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: const Color(0xFF111111),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  Widget _genderSelector() => Row(
    children: ['Male', 'Female', 'Other'].map((g) {
      final sel = _gender == g;
      return Expanded(child: GestureDetector(onTap: () => setState(() => _gender = g),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: g != 'Other' ? 10 : 0),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.08))),
          child: Center(child: Text(g, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))))));
    }).toList());

  Widget _buildCertSelector() => GestureDetector(
    onTap: _pickCertificate,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity, height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF111111), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _certBytes != null ? const Color(0xFF7C4DFF) : Colors.white.withOpacity(0.08), width: 1.5)),
      child: _certBytes != null
        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF7C4DFF), size: 28),
            const SizedBox(height: 6),
            Text(_certFileName ?? 'Certificate uploaded', style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Tap to change', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          ])
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.cloud_upload_rounded, color: Colors.white.withOpacity(0.3), size: 28),
            const SizedBox(height: 6),
            Text('Upload Certificate', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
            Text('JPG, PNG or PDF', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
          ]),
    ),
  );

  Widget _submitBtn() => GestureDetector(
    onTap: _loading ? null : _save,
    child: Container(width: double.infinity, height: 56,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Center(child: _loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
          : const Text('Create Coach', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)))));
}
