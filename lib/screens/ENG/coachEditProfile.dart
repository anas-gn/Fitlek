import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'coachProfile.dart' show CoachProfileData;

/// Coach Edit Profile — a safe form pre-filled with the coach's real backend
/// values. Only fields supported by the secure `/coach/profile/edit` endpoint
/// are editable. Read-only fields (email, invitation code, points…) are shown
/// for context but never submitted.
class CoachEditProfile extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachEditProfile({super.key, required this.profile, required this.token});

  @override
  State<CoachEditProfile> createState() => _CoachEditProfileState();
}

class _CoachEditProfileState extends State<CoachEditProfile> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _villeCtrl;

  late String _gender;
  String? _avatarUrl;

  bool _saving = false;
  bool _uploadingAvatar = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstNameCtrl = TextEditingController(text: p.firstName);
    _lastNameCtrl = TextEditingController(text: p.lastName);
    _bioCtrl = TextEditingController(text: p.bio);
    _instagramCtrl = TextEditingController(text: p.instagramPage);
    _telCtrl = TextEditingController(text: p.tel);
    _villeCtrl = TextEditingController(text: p.ville);
    _gender = _genders.contains(p.gender) ? p.gender : 'Other';
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    _instagramCtrl.dispose();
    _telCtrl.dispose();
    _villeCtrl.dispose();
    super.dispose();
  }

  String get _initials {
    final f = _firstNameCtrl.text.trim();
    final l = _lastNameCtrl.text.trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    final res = (a + b).toUpperCase();
    return res.isEmpty ? '?' : res;
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

  bool get _isDirty {
    final p = widget.profile;
    return _firstNameCtrl.text.trim() != p.firstName ||
        _lastNameCtrl.text.trim() != p.lastName ||
        _bioCtrl.text.trim() != p.bio ||
        _instagramCtrl.text.trim() != p.instagramPage ||
        _telCtrl.text.trim() != p.tel ||
        _villeCtrl.text.trim() != p.ville ||
        _gender != p.gender ||
        (_avatarUrl != null && _avatarUrl != p.avatarUrl);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isDirty) {
      _showSnack('No changes to save.');
      return;
    }

    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'gender': _gender,
        'bio': _bioCtrl.text.trim(),
        'instagramPage': _instagramCtrl.text.trim(),
        'tel': _telCtrl.text.trim(),
        'ville': _villeCtrl.text.trim(),
      };
      // Only send avatarUrl when it changed, to avoid unnecessary writes.
      if (_avatarUrl != null && _avatarUrl != widget.profile.avatarUrl) {
        body['avatarUrl'] = _avatarUrl;
      }

      final res = await ApiService.put('/coach/profile/edit', body);
      if (!mounted) return;

      if (res['ok'] == true) {
        _showSnack('Profile updated ✓');
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
        centerTitle: true,
        title: Text('Edit profile',
            style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w800)),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildAvatarPicker(cs, f),
                  const SizedBox(height: 24),
                  _sectionTitle('Identity'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          controller: _firstNameCtrl,
                          label: 'First name',
                          icon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _lastNameCtrl,
                          label: 'Last name',
                          icon: Icons.badge_outlined,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildGenderSelector(cs, f),
                  const SizedBox(height: 24),
                  _sectionTitle('Professional information'),
                  const SizedBox(height: 12),
                  _field(
                    controller: _bioCtrl,
                    label: 'Biography',
                    icon: Icons.chat_bubble_outline_rounded,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Biography is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _instagramCtrl,
                    label: 'Instagram page',
                    icon: Icons.camera_alt_outlined,
                    keyboardType: TextInputType.url,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Instagram page is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _telCtrl,
                    label: 'Phone (optional)',
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]'))],
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length < 6 || digits.length > 15) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _villeCtrl,
                    label: 'City (optional)',
                    icon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Account (read-only)'),
                  const SizedBox(height: 12),
                  _readOnlyRow(Icons.mail_outline_rounded, 'Email', widget.profile.email.isNotEmpty ? widget.profile.email : 'Not provided', f, cs),
                  _readOnlyRow(Icons.confirmation_number_outlined, 'Invitation code',
                      widget.profile.invitationCode.isNotEmpty ? widget.profile.invitationCode : '—', f, cs),
                  _readOnlyRow(Icons.emoji_events_outlined, 'Points earned', '${widget.profile.earnedPoints}', f, cs),
                  _readOnlyRow(Icons.group_add_outlined, 'Total invitations', '${widget.profile.totalInvitations}', f, cs),
                  const SizedBox(height: 28),
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
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [cs.primary, f.primaryDim]),
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: Container(
                color: f.card,
                child: (url != null && url.isNotEmpty)
                    ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback(cs))
                    : _avatarFallback(cs),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
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
        child: Text(_initials, style: TextStyle(color: cs.primary, fontSize: 32, fontWeight: FontWeight.w800)),
      );

  Widget _sectionTitle(String text) {
    return Text(text,
        style: TextStyle(
          color: context.fitlek.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ));
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: f.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, size: 19, color: cs.primary),
        filled: true,
        fillColor: f.inputFill,
        errorStyle: TextStyle(color: f.error, fontSize: 11.5, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: f.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: f.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: f.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: f.error, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(ColorScheme cs, FitlekColors f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Gender', style: TextStyle(color: f.textMuted, fontSize: 13)),
        ),
        Row(
          children: _genders.map((g) {
            final selected = g == _gender;
            final label = g == 'Male'
                ? 'Male'
                : g == 'Female'
                    ? 'Female'
                    : 'Other';
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g == _genders.last ? 0 : 10),
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: selected ? cs.primary.withValues(alpha: 0.12) : f.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.5) : f.border),
                    ),
                    child: Center(
                      child: Text(label,
                          style: TextStyle(
                            color: selected ? cs.primary : cs.onSurface,
                            fontSize: 13.5,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          )),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _readOnlyRow(IconData icon, String label, String value, FitlekColors f, ColorScheme cs) {
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
          Icon(icon, size: 18, color: f.textMuted),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: f.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.lock_outline_rounded, size: 14, color: f.textMuted.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ColorScheme cs) {
    return GestureDetector(
      onTap: _saving ? null : _save,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _saving ? cs.primary.withValues(alpha: 0.6) : cs.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _saving
              ? null
              : [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))],
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
                    Icon(Icons.check_rounded, size: 20, color: cs.onPrimary),
                    const SizedBox(width: 8),
                    Text('Save', style: TextStyle(color: cs.onPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
        ),
      ),
    );
  }
}
