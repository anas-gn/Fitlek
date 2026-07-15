import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'coachProfile.dart' show CoachProfileData;

/// Coach Edit Profile — redesign matching the coach mockups.
/// All editable values are loaded from and saved to the secure coach backend.
/// Price is intentionally not editable (subscription model later).
class CoachEditProfile extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachEditProfile({super.key, required this.profile, required this.token});

  @override
  State<CoachEditProfile> createState() => _CoachEditProfileState();
}

class _CoachEditProfileState extends State<CoachEditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _villeCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  late List<String> _certifications;
  late List<String> _specialties;
  late bool _publicProfile;
  late bool _directMessaging;
  late String _gender;
  String? _avatarUrl;

  bool _saving = false;
  bool _uploadingAvatar = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _fullNameCtrl.text = '${p.firstName} ${p.lastName}'.trim();
    _emailCtrl.text = p.email;
    _titleCtrl.text = p.professionalTitle.isNotEmpty ? p.professionalTitle : p.experience;
    _bioCtrl.text = p.bio;
    _telCtrl.text = p.tel;
    _villeCtrl.text = p.ville;
    _instagramCtrl.text = p.instagramPage;
    _certifications = List<String>.from(p.certifications);
    _specialties = p.specialties.isNotEmpty
        ? List<String>.from(p.specialties)
        : (p.specialty.isNotEmpty ? [p.specialty] : <String>[]);
    _publicProfile = p.publicProfile;
    _directMessaging = p.directMessaging;
    _gender = _normalizeGender(p.gender);
  }

  String _normalizeGender(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'male' || v == 'm' || v == 'homme') return 'Male';
    if (v == 'female' || v == 'f' || v == 'femme') return 'Female';
    if (v.isEmpty) return 'Other';
    // Keep custom values if already one of the known labels.
    for (final g in _genders) {
      if (g.toLowerCase() == v) return g;
    }
    return 'Other';
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
    _telCtrl.dispose();
    _villeCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _fullNameCtrl.text.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  (String firstName, String lastName) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, parts.first);
    return (parts.first, parts.sublist(1).join(' '));
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(
              color: isError ? Theme.of(context).colorScheme.onError : Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            )),
        backgroundColor: isError ? context.fitlek.error : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar || _saving) return;
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final mime = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final up = await ApiService.uploadMultipart(
        '/coach/avatar',
        fields: const {},
        fileBytes: bytes,
        fileField: 'avatar',
        fileName: file.name,
        mimeType: mime,
      );
      if (up['ok'] != true) {
        _showSnack(up['message']?.toString() ?? 'Upload failed', isError: true);
        return;
      }
      final newUrl = up['url']?.toString();
      if (newUrl == null || newUrl.isEmpty) {
        _showSnack('Upload failed', isError: true);
        return;
      }
      setState(() => _avatarUrl = newUrl);
      _showSnack('Photo ready. Save to confirm.');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<String?> _promptText({
    required String title,
    required String hint,
    int maxLength = 120,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final f = ctx.fitlek;
        return AlertDialog(
          backgroundColor: f.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: maxLength,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: f.textMuted),
              filled: true,
              fillColor: f.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: f.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: f.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: f.textMuted, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text('Add', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  Future<void> _addCertification() async {
    final value = await _promptText(title: 'Add Certification', hint: 'e.g. NASM Master Trainer');
    if (value == null) return;
    final exists = _certifications.any((c) => c.toLowerCase() == value.toLowerCase());
    if (exists) {
      _showSnack('This certification is already added', isError: true);
      return;
    }
    if (_certifications.length >= 10) {
      _showSnack('Maximum 10 certifications', isError: true);
      return;
    }
    setState(() => _certifications.add(value));
  }

  Future<void> _addSpecialty() async {
    final value = await _promptText(title: 'Add Specialty', hint: 'e.g. Hypertrophy', maxLength: 60);
    if (value == null) return;
    final exists = _specialties.any((c) => c.toLowerCase() == value.toLowerCase());
    if (exists) {
      _showSnack('This specialty is already added', isError: true);
      return;
    }
    if (_specialties.length >= 10) {
      _showSnack('Maximum 10 specialties', isError: true);
      return;
    }
    setState(() => _specialties.add(value));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final (firstName, lastName) = _splitName(_fullNameCtrl.text);
    if (firstName.isEmpty || lastName.isEmpty) {
      _showSnack('Please enter your full name', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final p = widget.profile;
      final title = _titleCtrl.text.trim();
      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': _emailCtrl.text.trim(),
        'gender': _gender,
        'bio': _bioCtrl.text.trim(),
        'professionalTitle': title,
        // Keep legacy fields in sync for any older readers.
        'experience': title,
        'specialty': _specialties.isNotEmpty ? _specialties.first : '',
        'certifications': _certifications,
        'specialties': _specialties,
        'publicProfile': _publicProfile,
        'directMessaging': _directMessaging,
        'instagramPage': _instagramCtrl.text.trim(),
        'tel': _telCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
        // Never send price — coaches do not set a session price in the app.
      };
      if (_avatarUrl != null && _avatarUrl != p.avatarUrl) {
        body['avatarUrl'] = _avatarUrl;
      }

      final res = await ApiService.put('/coach/profile/edit', body);
      if (!mounted) return;

      if (res['ok'] == true) {
        _showSnack('Profile updated');
        Navigator.of(context).pop(true);
      } else {
        _showSnack(res['message']?.toString() ?? 'Error while updating', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Edit Profile', style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  _buildAvatarPicker(cs, f),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.primary, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Update your professional details',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: f.textMuted, fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 22),
                  _buildBasicInformation(cs, f),
                  const SizedBox(height: 18),
                  _buildContactInformation(cs, f),
                  const SizedBox(height: 18),
                  _buildCertifications(cs, f),
                  const SizedBox(height: 18),
                  _buildSpecialties(cs, f),
                  const SizedBox(height: 18),
                  _buildAccountSettings(cs, f),
                  const SizedBox(height: 22),
                  _buildSaveButton(cs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(ColorScheme cs, FitlekColors f) {
    final url = _avatarUrl ?? widget.profile.avatarUrl;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary.withValues(alpha: 0.35), width: 2),
            ),
            child: ClipOval(
              child: Container(
                color: f.card2,
                child: (url != null && url.isNotEmpty)
                    ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(cs))
                    : _avatarFallback(cs),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                ),
                child: _uploadingAvatar
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                        ),
                      )
                    : Icon(Icons.camera_alt_rounded, size: 16, color: cs.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(ColorScheme cs) => Center(
        child: Text(_initials, style: TextStyle(color: cs.primary, fontSize: 34, fontWeight: FontWeight.w800)),
      );

  Widget _sectionHeader(String title, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            color: cs.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    final f = context.fitlek;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: f.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildBasicInformation(ColorScheme cs, FitlekColors f) {
    return _card(
      children: [
        _sectionHeader('BASIC INFORMATION'),
        const SizedBox(height: 16),
        _labeledField(
          label: 'Full Name',
          child: TextFormField(
            controller: _fullNameCtrl,
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).length < 2)
                ? 'Enter first and last name'
                : null,
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(f, cs),
          ),
        ),
        const SizedBox(height: 14),
        _labeledField(
          label: 'Email',
          child: TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(f, cs, hint: 'you@example.com'),
          ),
        ),
        const SizedBox(height: 14),
        _labeledField(
          label: 'Gender',
          child: DropdownButtonFormField<String>(
            initialValue: _gender,
            items: _genders
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _gender = v);
            },
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            dropdownColor: f.card,
            decoration: _inputDecoration(f, cs),
          ),
        ),
        const SizedBox(height: 14),
        _labeledField(
          label: 'Professional Title',
          child: TextFormField(
            controller: _titleCtrl,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(f, cs, hint: 'e.g. Elite Performance Specialist'),
          ),
        ),
        const SizedBox(height: 14),
        _labeledField(
          label: 'Bio',
          child: TextFormField(
            controller: _bioCtrl,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Bio is required' : null,
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w500, height: 1.45),
            decoration: _inputDecoration(f, cs),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInformation(ColorScheme cs, FitlekColors f) {
    return _card(
      children: [
        _sectionHeader('CONTACT & LOCATION', icon: Icons.contact_mail_rounded),
        const SizedBox(height: 16),
        _labeledField(
          label: 'Phone',
          child: TextFormField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(f, cs, hint: '+212 6XX XXX XXX'),
          ),
        ),
        const SizedBox(height: 14),
        _labeledField(
          label: 'City',
          child: TextFormField(
            controller: _villeCtrl,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(f, cs, hint: 'e.g. Casablanca'),
          ),
        ),
        const SizedBox(height: 14),
        _labeledField(
          label: 'Instagram',
          child: TextFormField(
            controller: _instagramCtrl,
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(f, cs, hint: '@yourhandle'),
          ),
        ),
      ],
    );
  }

  Widget _buildCertifications(ColorScheme cs, FitlekColors f) {
    return _card(
      children: [
        _sectionHeader('CERTIFICATIONS', icon: Icons.verified_rounded),
        const SizedBox(height: 14),
        if (_certifications.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('No certifications yet.', style: TextStyle(color: f.textMuted, fontSize: 13)),
          ),
        ..._certifications.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: f.card2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: f.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value, style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _certifications.removeAt(index)),
                  child: Icon(Icons.close_rounded, size: 18, color: f.textMuted),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: _addCertification,
          child: CustomPaint(
            painter: _DashedBorderPainter(color: cs.primary.withValues(alpha: 0.45), radius: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text('+ Add Certification',
                    style: TextStyle(color: cs.primary, fontSize: 13.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialties(ColorScheme cs, FitlekColors f) {
    return _card(
      children: [
        _sectionHeader('SPECIALTIES', icon: Icons.open_with_rounded),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._specialties.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(value, style: TextStyle(color: cs.primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _specialties.removeAt(index)),
                      child: Icon(Icons.close_rounded, size: 14, color: cs.primary),
                    ),
                  ],
                ),
              );
            }),
            GestureDetector(
              onTap: _addSpecialty,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: f.card2,
                  shape: BoxShape.circle,
                  border: Border.all(color: f.border),
                ),
                child: Icon(Icons.add_rounded, size: 18, color: cs.primary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSettings(ColorScheme cs, FitlekColors f) {
    return _card(
      children: [
        _sectionHeader('ACCOUNT SETTINGS'),
        const SizedBox(height: 8),
        _toggleRow(
          title: 'Public Profile',
          subtitle: 'Allow potential clients to find you',
          value: _publicProfile,
          onChanged: (v) => setState(() => _publicProfile = v),
          cs: cs,
          f: f,
        ),
        Divider(height: 1, color: f.border.withValues(alpha: 0.7)),
        _toggleRow(
          title: 'Direct Messaging',
          subtitle: 'Enable instant chat with clients',
          value: _directMessaging,
          onChanged: (v) => setState(() => _directMessaging = v),
          cs: cs,
          f: f,
        ),
      ],
    );
  }

  Widget _toggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
    required FitlekColors f,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: f.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: cs.primary,
            activeThumbColor: cs.onPrimary,
          ),
        ],
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(FitlekColors f, ColorScheme cs, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: f.textMuted.withValues(alpha: 0.8), fontSize: 13.5),
      filled: true,
      fillColor: f.inputFill,
      errorStyle: TextStyle(color: f.error, fontSize: 11.5, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: f.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: f.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: f.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: f.error, width: 1.5)),
    );
  }

  Widget _buildSaveButton(ColorScheme cs) {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: _saving ? cs.primary.withValues(alpha: 0.6) : cs.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _saving
              ? null
              : [BoxShadow(color: cs.primary.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: _saving
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary)),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, size: 18, color: cs.onPrimary),
                    const SizedBox(width: 8),
                    Text('Save Profile Changes',
                        style: TextStyle(color: cs.onPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, this.radius = 14});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dashWidth = 7.0;
    const dashSpace = 5.0;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
