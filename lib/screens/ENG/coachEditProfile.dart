import 'package:flutter/material.dart';
import '../../models/coach.dart';
import '../../services/apiService.dart';

class CoachEditProfile extends StatefulWidget {
  final Coach coach;
  const CoachEditProfile({super.key, required this.coach});
  @override
  State<CoachEditProfile> createState() => _CoachEditProfileState();
}

class _CoachEditProfileState extends State<CoachEditProfile> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _instagramCtrl;
  late String _selectedGender;
  bool _hasChanges = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl  = TextEditingController(text: widget.coach.firstName);
    _lastNameCtrl   = TextEditingController(text: widget.coach.lastName);
    _bioCtrl        = TextEditingController(text: widget.coach.bio);
    _instagramCtrl  = TextEditingController(text: widget.coach.instagramPage);
    _selectedGender = widget.coach.gender;
    for (final c in [_firstNameCtrl, _lastNameCtrl, _bioCtrl, _instagramCtrl]) {
      c.addListener(() => setState(() => _hasChanges = true));
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _bioCtrl.dispose(); _instagramCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      ApiService.showError(context, 'First and last name are required.');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.put('/coach/profile/edit', {
      'firstName':    _firstNameCtrl.text.trim(),
      'lastName':     _lastNameCtrl.text.trim(),
      'gender':       _selectedGender,
      'bio':          _bioCtrl.text.trim(),
      'instagramPage':_instagramCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['ok'] == true) {
      final updated = widget.coach.copyWith(
        firstName:     _firstNameCtrl.text.trim(),
        lastName:      _lastNameCtrl.text.trim(),
        gender:        _selectedGender,
        bio:           _bioCtrl.text.trim(),
        instagramPage: _instagramCtrl.text.trim(),
      );
      Navigator.of(context).pop(updated);
    } else {
      ApiService.showError(context, result['message'] ?? 'Update failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        _buildTopBar(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            _buildAvatarSection(),
            const SizedBox(height: 32),
            _buildSectionLabel('Personal Information'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _buildTextField(_firstNameCtrl, 'First Name', 'John')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_lastNameCtrl, 'Last Name', 'Doe')),
            ]),
            const SizedBox(height: 18),
            _buildSectionLabel('Gender'),
            const SizedBox(height: 10),
            _buildGenderSelector(),
            const SizedBox(height: 22),
            _buildSectionLabel('About'),
            const SizedBox(height: 10),
            _buildTextField(_bioCtrl, 'Bio', 'Tell your clients about yourself...', maxLines: 5),
            const SizedBox(height: 22),
            _buildSectionLabel('Social'),
            const SizedBox(height: 10),
            _buildTextField(_instagramCtrl, 'Instagram Page', '@yourhandle',
                prefix: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 18)),
            const SizedBox(height: 36),
            _buildSaveButton(),
            const SizedBox(height: 32),
          ]),
        )),
      ])),
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
      const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const Spacer(),
      if (_hasChanges && !_loading)
        GestureDetector(onTap: _save,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(10)),
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)))),
    ]));

  Widget _buildAvatarSection() => Center(child: Stack(children: [
    Container(width: 100, height: 100,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFA3FF12), width: 2.5),
          boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.25), blurRadius: 20)]),
      child: ClipOval(child: widget.coach.avatarUrl.isNotEmpty
          ? Image.network(widget.coach.avatarUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFFA3FF12), size: 46))
          : const Icon(Icons.person, color: Color(0xFFA3FF12), size: 46))),
    Positioned(right: 0, bottom: 0, child: Container(width: 32, height: 32,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
      child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16))),
  ]));

  Widget _buildSectionLabel(String label) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
  ]);

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, {int maxLines = 1, Widget? prefix}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, maxLines: maxLines, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: prefix) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: const Color(0xFF111111), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  Widget _buildGenderSelector() => Row(
    children: ['Male', 'Female', 'Other'].map((g) {
      final sel = _selectedGender == g;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() { _selectedGender = g; _hasChanges = true; }),
        child: AnimatedContainer(duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: g != 'Other' ? 8 : 0),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.08))),
          child: Center(child: Text(g, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))))));
    }).toList());

  Widget _buildSaveButton() => GestureDetector(
    onTap: _loading ? null : _save,
    child: Container(width: double.infinity, height: 56,
      decoration: BoxDecoration(
        color: _hasChanges ? const Color(0xFFA3FF12) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _hasChanges ? [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))] : null),
      child: Center(child: _loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
          : Text('Save Changes', style: TextStyle(color: _hasChanges ? Colors.black : Colors.white38, fontSize: 16, fontWeight: FontWeight.w800)))));
}
