import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class ManagerCreateAdmin extends StatefulWidget {
  const ManagerCreateAdmin({super.key});
  @override
  State<ManagerCreateAdmin> createState() => _ManagerCreateAdminState();
}

class _ManagerCreateAdminState extends State<ManagerCreateAdmin> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  void _save() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ApiService.showError(context, 'All fields are required.');
      return;
    }
    setState(() => _loading = true);
    final result = await ApiService.post('/manager/admins/create', {
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
    });
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
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 32),
          Center(child: Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF001A1E), border: Border.all(color: const Color(0xFF00BCD4), width: 2), boxShadow: [BoxShadow(color: const Color(0xFF00BCD4).withOpacity(0.2), blurRadius: 16)]),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF00BCD4), size: 36))),
          const SizedBox(height: 32),
          _sectionLabel('Admin Information'),
          const SizedBox(height: 14),
          Row(children: [Expanded(child: _field(_firstNameCtrl, 'First Name', 'John')), const SizedBox(width: 12), Expanded(child: _field(_lastNameCtrl, 'Last Name', 'Doe'))]),
          const SizedBox(height: 14),
          _field(_emailCtrl, 'Email', 'admin@fitlek.com', keyboard: TextInputType.emailAddress),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF001A1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFF00BCD4), size: 18), const SizedBox(width: 10),
              Expanded(child: Text('A temporary password will be generated and shown after creation.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.5))),
            ])),
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
      const Text('Create Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    ]));

  Widget _sectionLabel(String label) => Row(children: [
    Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFF00BCD4), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Widget _field(TextEditingController ctrl, String label, String hint, {TextInputType? keyboard}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, keyboardType: keyboard, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          filled: true, fillColor: const Color(0xFF111111), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 1.5)))),
    ]);

  Widget _submitBtn() => GestureDetector(onTap: _loading ? null : _save,
    child: Container(width: double.infinity, height: 56,
      decoration: BoxDecoration(color: const Color(0xFFA3FF12), borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFA3FF12).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Center(child: _loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
        : const Text('Create Admin', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w800)))));
}
