import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ManagerEditCoach extends StatefulWidget {
  final dynamic coachData;
  const ManagerEditCoach({super.key, required this.coachData});
  @override
  State<ManagerEditCoach> createState() => _ManagerEditCoachState();
}

class _ManagerEditCoachState extends State<ManagerEditCoach> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _instagramCtrl;
  late String _gender;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.coachData['firstName'] ?? '');
    _lastNameCtrl  = TextEditingController(text: widget.coachData['lastName']  ?? '');
    _emailCtrl     = TextEditingController(text: widget.coachData['email']     ?? '');
    _bioCtrl       = TextEditingController(text: widget.coachData['bio']       ?? '');
    _instagramCtrl = TextEditingController(text: widget.coachData['instagramPage'] ?? '');
    _gender        = widget.coachData['gender'] ?? 'Male';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose();
    _bioCtrl.dispose(); _instagramCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ApiService.showError(context, 'All fields are required.');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.put('/manager/coaches/edit/${widget.coachData['id']}', {
      'firstName':     _firstNameCtrl.text.trim(),
      'lastName':      _lastNameCtrl.text.trim(),
      'email':         _emailCtrl.text.trim(),
      'gender':        _gender,
      'bio':           _bioCtrl.text.trim(),
      'instagramPage': _instagramCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['ok'] == true) Navigator.of(context).pop(true);
    else ApiService.showError(context, result['message'] ?? 'Update failed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: Column(children: [
        _topBar(),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 24),
          _buildAvatar(),
          const SizedBox(height: 28),
          _sectionLabel('Personal Information'),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: _field(_firstNameCtrl, 'First Name', 'John')), const SizedBox(width: 12), Expanded(child: _field(_lastNameCtrl, 'Last Name', 'Doe'))]),
          const SizedBox(height: 14),
          _field(_emailCtrl, 'Email', 'coach@fitlek.com', keyboard: TextInputType.emailAddress),
          const SizedBox(height: 18),
          _sectionLabel('Gender'),
          const SizedBox(height: 10),
          _genderSelector(),
          const SizedBox(height: 22),
          _sectionLabel('About'),
          const SizedBox(height: 10),
          _field(_bioCtrl, 'Bio', 'Coach bio...', maxLines: 4),
          const SizedBox(height: 22),
          _sectionLabel('Social'),
          const SizedBox(height: 10),
          _field(_instagramCtrl, 'Instagram Page', '@coachhandle',
              prefix: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 18)),
          const SizedBox(height: 36),
          _submitBtn(),
          const SizedBox(height: 32),
        ]))),
      ])),
    );
  }

  Widget _topBar() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.of(context).pop(),
        child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18))),
      const SizedBox(width: 16),
      const Text('Edit Coach', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      const Spacer(),
      GestureDetector(onTap: _loading ? null : _save,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(10)),
          child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)))),
    ]));

  Widget _buildAvatar() => Center(child: Stack(children: [
    Container(width: 88, height: 88,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF7C4DFF), width: 2.5),
          boxShadow: [BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.25), blurRadius: 18)]),
      child: ClipOval(child: widget.coachData['avatarUrl'] != null
          ? Image.network(widget.coachData['avatarUrl'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.sports_rounded, color: Color(0xFF7C4DFF), size: 40))
          : const Icon(Icons.sports_rounded, color: Color(0xFF7C4DFF), size: 40))),
    Positioned(right: 0, bottom: 0, child: Container(width: 28, height: 28,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
      child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 14))),
  ]));

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700))]);

  Widget _field(TextEditingController ctrl, String label, String hint, {TextInputType? keyboard, int maxLines = 1, Widget? prefix}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: keyboard, maxLines: maxLines, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
          prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.only(left: 14, right: 8), child: prefix) : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true, fillColor: const Color(0xFF111111), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFA3FF12), width: 1.5)))),
    ]);

  Widget _genderSelector() => Row(children: ['Male', 'Female', 'Other'].map((g) {
    final sel = _gender == g;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _gender = g),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: g != 'Other' ? 10 : 0),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(color: sel ? const Color(0xFFA3FF12) : const Color(0xFF111111), borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? const Color(0xFFA3FF12) : Colors.white.withOpacity(0.08))),
        child: Center(child: Text(g, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600))))));
  }).toList());

  Widget _submitBtn() => GestureDetector(onTap: _loading ? null : _save,
    child: Container(width: double.infinity, height: 56,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Center(child: _loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
          : const Text('Save Changes', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)))));
}
