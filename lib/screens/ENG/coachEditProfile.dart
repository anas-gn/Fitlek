import '../../services/media_picker_service.dart';
import 'userLocationSettings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'coachProfile.dart' show CoachProfileData;
import 'package:fitlek1/models/anas/coachPackage.dart';

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
  
  List<Map<String, dynamic>> _galleryImages = [];
  bool _loadingGallery = true;
  bool _uploadingGallery = false;
  // Suggested fitness specialties for quick selection
  static const List<String> _suggestedSpecialties = [
    'Musculation',
    'Perte de poids',
    'Yoga',
    'CrossFit',
    'Boxe',
    'Nutrition',
    'Pilates',
    'Cardio',
    'Stretching',
    'Functional Training',
  ];

  // Packages
  List<CoachPackage> _packages = [];
  bool _loadingPackages = true;

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
    _loadGallery();
    _loadPackages();
  }

  Future<void> _loadGallery() async {
    try {
      final p = widget.profile;
      final res = await ApiService.get('/coaches/${p.id}/images');
      if (mounted) {
        setState(() {
          if (res['ok'] == true && res['data'] != null) {
            _galleryImages = List<Map<String, dynamic>>.from(res['data']);
          }
          _loadingGallery = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGallery = false);
    }
  }

  Future<void> _loadPackages() async {
    try {
      final coachID = widget.profile.id;
      final res = await http.get(
        Uri.parse('$baseUrl/packages/me?coachID=$coachID'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _packages = data.map((e) => CoachPackage.fromJson(e)).toList();
          _loadingPackages = false;
        });
      } else {
        if (mounted) setState(() => _loadingPackages = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPackages = false);
    }
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
    final picker = AppMediaPicker(context);
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
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

  Future<void> _pickAndUploadGalleryImage() async {
    if (_uploadingGallery || _saving) return;
    final int allowedImages = 5 - _galleryImages.length;
    if (allowedImages <= 0) {
      _showSnack('Maximum 5 images allowed in the gallery', isError: true);
      return;
    }

    final picker = AppMediaPicker(context);
    final List<XFile> files = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    if (files.isEmpty) return;

    final filesToUpload = files.take(allowedImages).toList();
    if (files.length > allowedImages) {
      _showSnack('Only $allowedImages images will be added to respect the limit.');
    }

    setState(() => _uploadingGallery = true);
    try {
      bool anyError = false;
      for (final file in filesToUpload) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        final mime = ext == 'png'
            ? 'image/png'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg';

        final up = await ApiService.uploadMultipart(
          '/upload/coach-gallery',
          fields: {'coachID': widget.profile.id.toString()},
          fileBytes: bytes,
          fileField: 'image',
          fileName: file.name,
          mimeType: mime,
        );
        if (up['ok'] != true) {
          anyError = true;
          _showSnack(up['message']?.toString() ?? 'Upload failed for ${file.name}', isError: true);
        }
      }
      
      if (!anyError) {
        _showSnack('Images added to gallery!');
      }
      await _loadGallery(); // Reload the gallery to get the new images
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingGallery = false);
    }
  }

  Future<void> _deleteGalleryImage(int imageId) async {
    try {
      final p = widget.profile;
      final res = await ApiService.delete('/coaches/${p.id}/images/$imageId');
      if (res['ok'] == true) {
        setState(() {
          _galleryImages.removeWhere((img) => img['id'] == imageId);
        });
        _showSnack('Image deleted');
      } else {
        _showSnack(res['message']?.toString() ?? 'Error deleting image', isError: true);
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
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
        'instagramPage': _instagramCtrl.text.trim().replaceAll(RegExp(r'^@+'), ''),
        'tel': _telCtrl.text.trim(),
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
                  _buildPackagesSection(cs, f),
                  const SizedBox(height: 18),
                  _buildGallerySection(cs, f),
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
            readOnly: true,
            onTap: () async {
              final city = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const UserLocationSettings()));
              if (mounted && city != null) setState(() => _villeCtrl.text = city);
            },
            style: TextStyle(color: cs.onSurface, fontSize: 14.5, fontWeight: FontWeight.w600),
            decoration: _inputDecoration(f, cs, hint: 'Use location').copyWith(
                suffixIcon: const Icon(Icons.my_location)),
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
        _sectionHeader('SPECIALTIES', icon: Icons.fitness_center_rounded),
        const SizedBox(height: 6),
        Text(
          'Select the specialties you teach (you can select multiple):',
          style: TextStyle(color: f.textMuted, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedSpecialties.map((spec) {
            final isSelected = _specialties.any((s) => s.toLowerCase() == spec.toLowerCase());
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _specialties.removeWhere((s) => s.toLowerCase() == spec.toLowerCase());
                  } else {
                    if (_specialties.length >= 10) {
                      _showSnack('Maximum 10 specialties', isError: true);
                      return;
                    }
                    _specialties.add(spec);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primary
                      : f.card2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cs.primary : f.border,
                    width: isSelected ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_rounded, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      spec,
                      style: TextStyle(
                        color: isSelected ? Colors.black : cs.onSurface,
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_specialties.any((s) => !_suggestedSpecialties.any((opt) => opt.toLowerCase() == s.toLowerCase()))) ...[
          const SizedBox(height: 14),
          Text('Custom Specialties:', style: TextStyle(color: f.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specialties
                .where((s) => !_suggestedSpecialties.any((opt) => opt.toLowerCase() == s.toLowerCase()))
                .map((customSpec) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(customSpec, style: TextStyle(color: cs.primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _specialties.remove(customSpec)),
                      child: Icon(Icons.close_rounded, size: 14, color: cs.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _addSpecialty,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: f.card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: f.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 4),
                Text('Add Other Specialty', style: TextStyle(color: cs.primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // ──────────────────────────────────────────────────────────────
  //  PACKAGES SECTION
  // ──────────────────────────────────────────────────────────────

  Future<void> _showPackageDialog({CoachPackage? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final sessCtrl = TextEditingController(
        text: existing?.sessions != null ? existing!.sessions.toString() : '');
    final priceCtrl = TextEditingController(
        text: existing?.price != null ? existing!.price!.toStringAsFixed(0) : '');
    bool priceEnabled = existing?.price != null;
    bool isActive = existing?.isActive ?? true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final f = ctx.fitlek;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: f.card,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              existing == null ? 'Add Package' : 'Edit Package',
              style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 17),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text('Package Name *',
                      style: TextStyle(
                          color: f.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. Starter Pack',
                      hintStyle: TextStyle(color: f.textMuted),
                      filled: true,
                      fillColor: f.inputFill,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: f.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: f.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: cs.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Description
                  Text('Description (optional)',
                      style: TextStyle(
                          color: f.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: cs.onSurface, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Describe what\'s included…',
                      hintStyle: TextStyle(color: f.textMuted),
                      filled: true,
                      fillColor: f.inputFill,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: f.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: f.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: cs.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Sessions
                  Text('Number of sessions (optional)',
                      style: TextStyle(
                          color: f.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sessCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g. 12',
                      hintStyle: TextStyle(color: f.textMuted),
                      filled: true,
                      fillColor: f.inputFill,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: f.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: f.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: cs.primary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Price toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set a price',
                              style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700)),
                          Text('Leave off to discuss price after booking',
                              style: TextStyle(
                                  color: f.textMuted, fontSize: 11)),
                        ],
                      ),
                      Switch.adaptive(
                        value: priceEnabled,
                        onChanged: (v) =>
                            setDialogState(() => priceEnabled = v),
                        activeTrackColor: cs.primary,
                        activeThumbColor: cs.onPrimary,
                      ),
                    ],
                  ),
                  if (priceEnabled) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixText: 'MAD  ',
                        prefixStyle: TextStyle(
                            color: f.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        hintText: '0',
                        hintStyle: TextStyle(color: f.textMuted),
                        filled: true,
                        fillColor: f.inputFill,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: f.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: f.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: cs.primary, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                  if (existing != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Visible to clients',
                            style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                        Switch.adaptive(
                          value: isActive,
                          onChanged: (v) =>
                              setDialogState(() => isActive = v),
                          activeTrackColor: cs.primary,
                          activeThumbColor: cs.onPrimary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(
                        color: f.textMuted, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    _showSnack('Package name is required', isError: true);
                    return;
                  }
                  Navigator.pop(ctx, {
                    'name': name,
                    'description': descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    'sessions': sessCtrl.text.trim().isEmpty
                        ? null
                        : int.tryParse(sessCtrl.text.trim()),
                    'price': priceEnabled && priceCtrl.text.trim().isNotEmpty
                        ? double.tryParse(priceCtrl.text.trim())
                        : null,
                    'isActive': isActive,
                  });
                },
                child: Text(existing == null ? 'Add' : 'Update',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w800)),
              ),
            ],
          );
        });
      },
    ).then((data) async {
      nameCtrl.dispose();
      descCtrl.dispose();
      sessCtrl.dispose();
      priceCtrl.dispose();
      if (data == null) return;
      final coachID = widget.profile.id;
      try {
        http.Response res;
        if (existing == null) {
          // Create
          res = await http
              .post(
                Uri.parse('$baseUrl/packages'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${widget.token}',
                },
                body: jsonEncode({
                  'coachID': coachID,
                  ...data,
                }),
              )
              .timeout(const Duration(seconds: 10));
        } else {
          // Update
          res = await http
              .put(
                Uri.parse('$baseUrl/packages/${existing.id}'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer ${widget.token}',
                },
                body: jsonEncode({
                  'coachID': coachID,
                  ...data,
                }),
              )
              .timeout(const Duration(seconds: 10));
        }
        if (res.statusCode == 200 || res.statusCode == 201) {
          _showSnack(
              existing == null ? 'Package added!' : 'Package updated!');
          await _loadPackages();
        } else {
          final body = jsonDecode(res.body);
          _showSnack(body['error'] ?? 'Error', isError: true);
        }
      } catch (e) {
        _showSnack('Network error: $e', isError: true);
      }
    });
  }

  Future<void> _deletePackage(CoachPackage pkg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final f = ctx.fitlek;
        return AlertDialog(
          backgroundColor: f.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Delete package?',
              style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w800)),
          content: Text(
              'Are you sure you want to delete "${pkg.name}"? This cannot be undone.',
              style: TextStyle(color: f.textMuted, fontSize: 13)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: TextStyle(color: f.textMuted))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete',
                  style: TextStyle(
                      color: f.error, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      final res = await http
          .delete(
            Uri.parse('$baseUrl/packages/${pkg.id}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({'coachID': widget.profile.id}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _showSnack('Package deleted');
        await _loadPackages();
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['error'] ?? 'Error', isError: true);
      }
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    }
  }

  Widget _buildPackagesSection(ColorScheme cs, FitlekColors f) {
    return _card(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sectionHeader('COACHING PACKAGES',
              icon: Icons.workspace_premium_rounded),
          Text('${_packages.length}/3',
              style: TextStyle(
                  color: f.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Offer up to 3 packages. Price is optional — leave it off to discuss after booking.',
        style: TextStyle(color: f.textMuted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 14),
      if (_loadingPackages)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cs.primary)),
          ),
        )
      else ...[
        ..._packages.map((pkg) => _buildPackageCard(pkg, cs, f)),
        if (_packages.isNotEmpty) const SizedBox(height: 10),
        if (_packages.length < 3)
          GestureDetector(
            onTap: () => _showPackageDialog(),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                  color: cs.primary.withValues(alpha: 0.45), radius: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text('+ Add Package',
                      style: TextStyle(
                          color: cs.primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          )
        else
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: cs.primary),
              const SizedBox(width: 8),
              Text('Maximum 3 packages reached',
                  style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
      ],
    ]);
  }

  Widget _buildPackageCard(
      CoachPackage pkg, ColorScheme cs, FitlekColors f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: f.card2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: pkg.isActive ? f.border : f.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.workspace_premium_rounded,
                color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(pkg.name,
                        style: TextStyle(
                            color: pkg.isActive
                                ? cs.onSurface
                                : f.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (!pkg.isActive)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: f.textMuted.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Hidden',
                          style: TextStyle(
                              color: f.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                ]),
                if (pkg.description != null &&
                    pkg.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(pkg.description!,
                      style: TextStyle(color: f.textMuted, fontSize: 11.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 5),
                Wrap(spacing: 8, children: [
                  if (pkg.sessions != null)
                    _pkgChip('${pkg.sessions} sessions', cs),
                  pkg.price != null
                      ? _pkgChip(
                          '${pkg.price!.toInt()} MAD', cs,
                          colored: true)
                      : _pkgChip('Price on request', cs),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showPackageDialog(existing: pkg),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.edit_rounded, size: 15, color: cs.primary),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _deletePackage(pkg),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: f.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.delete_rounded, size: 15, color: f.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pkgChip(String label, ColorScheme cs, {bool colored = false}) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colored
              ? cs.primary.withValues(alpha: 0.12)
              : context.fitlek.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: colored
                  ? cs.primary.withValues(alpha: 0.3)
                  : context.fitlek.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: colored ? cs.primary : context.fitlek.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700)),
      );

  Widget _buildGallerySection(ColorScheme cs, FitlekColors f) {

    return _card(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader('GALLERY', icon: Icons.photo_library_rounded),
            Text('${_galleryImages.length}/5', style: TextStyle(color: f.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingGallery)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
            ),
          )
        else if (_galleryImages.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('No images in your gallery yet.', style: TextStyle(color: f.textMuted, fontSize: 13)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _galleryImages.length,
            itemBuilder: (_, i) {
              final img = _galleryImages[i];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      img['urlImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: f.card2,
                        child: Icon(Icons.broken_image_rounded, color: f.textMuted),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _deleteGalleryImage(img['id']),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 14),
        if (_galleryImages.length < 5)
          GestureDetector(
            onTap: _uploadingGallery ? null : _pickAndUploadGalleryImage,
            child: CustomPaint(
              painter: _DashedBorderPainter(color: cs.primary.withValues(alpha: 0.45), radius: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: _uploadingGallery
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                      : Text('+ Add Gallery Image', style: TextStyle(color: cs.primary, fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
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
