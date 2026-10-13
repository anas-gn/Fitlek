import '../../services/media_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';
import 'coachProfile.dart' show CoachProfileData;

class CoachAboutYou extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachAboutYou({super.key, required this.profile, required this.token});

  @override
  State<CoachAboutYou> createState() => _CoachAboutYouState();
}

class _CoachAboutYouState extends State<CoachAboutYou> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  late String _gender;
  late bool _showGender;
  late List<String> _languages;
  String? _avatarUrl;
  bool _saving = false;
  bool _uploadingAvatar = false;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _fullNameCtrl.text = '${p.firstName} ${p.lastName}'.trim();
    _titleCtrl.text = p.professionalTitle.isNotEmpty ? p.professionalTitle : p.experience;
    _bioCtrl.text = p.bio;
    _instagramCtrl.text = p.instagramPage;
    _gender = _normalizeGender(p.gender);
    _showGender = p.showGender;
    _languages = List<String>.from(p.languages);
  }

  String _normalizeGender(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'male' || v == 'm' || v == 'homme') return 'Male';
    if (v == 'female' || v == 'f' || v == 'femme') return 'Female';
    if (v.isEmpty) return 'Other';
    for (final g in _genders) {
      if (g.toLowerCase() == v) return g;
    }
    return 'Other';
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _titleCtrl.dispose();
    _bioCtrl.dispose();
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

  static const _availableLanguages = [
    'Arabic', 'French', 'English', 'Spanish',
    'Tamazight', 'German', 'Italian', 'Dutch', 'Portuguese', 'Russian'
  ];

  Future<void> _addLanguage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final f = ctx.fitlek;
        return Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: f.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: f.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Language', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 18)),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _availableLanguages.length,
                    itemBuilder: (context, index) {
                      final lang = _availableLanguages[index];
                      final isSelected = _languages.any((l) => l.toLowerCase() == lang.toLowerCase());
                      return Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                          title: Text(lang, style: TextStyle(color: isSelected ? cs.primary : cs.onSurface, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                          trailing: isSelected ? Icon(Icons.check_circle_rounded, color: cs.primary) : null,
                          onTap: () {
                            Navigator.pop(ctx, lang);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result == null || result.isEmpty) return;
    if (_languages.any((l) => l.toLowerCase() == result.toLowerCase())) {
      _showSnack('Language already added', isError: true);
      return;
    }
    setState(() => _languages.add(result));
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
      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'gender': _gender,
        'showGender': _showGender,
        'bio': _bioCtrl.text.trim(),
        'professionalTitle': _titleCtrl.text.trim(),
        'languages': _languages,
        'instagramPage': _instagramCtrl.text.trim().replaceAll(RegExp(r'^@+'), ''),
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
    final bgDark = const Color(0xFF0A1817); // from app_colors.dart darkBackground
    final cardDark = const Color(0xFF0F261F); // closer to the screenshot

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About you', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: preview
            },
            child: const Text('Preview', style: TextStyle(color: Color(0xFF6DE899), fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  children: [
                    _buildAvatarCard(cardDark, cs, f),
                    const SizedBox(height: 16),
                    _buildDetailsCard(cardDark, cs, f),
                    const SizedBox(height: 16),
                    _buildContactCard(cardDark, cs, f),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarCard(Color cardBg, ColorScheme cs, FitlekColors f) {
    final url = _avatarUrl ?? widget.profile.avatarUrl;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
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
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6DE899),
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBg, width: 2),
                    ),
                    child: _uploadingAvatar
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
            child: const Text('Change photo', style: TextStyle(color: Color(0xFF6DE899), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(ColorScheme cs) => Center(
        child: Text(_initials, style: TextStyle(color: cs.primary, fontSize: 30, fontWeight: FontWeight.w800)),
      );

  Widget _buildDetailsCard(Color cardBg, ColorScheme cs, FitlekColors f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Full name'),
          const SizedBox(height: 8),
          _textField(_fullNameCtrl),
          const SizedBox(height: 16),
          _label('Professional title'),
          const SizedBox(height: 8),
          _textField(_titleCtrl),
          const SizedBox(height: 16),
          _label('About me'),
          const SizedBox(height: 8),
          _textField(_bioCtrl, maxLines: 4),
          const SizedBox(height: 16),
          _label('Languages'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._languages.map((l) => _chip(l, onRemove: () {
                    setState(() => _languages.remove(l));
                  })),
              GestureDetector(
                onTap: _addLanguage,
                child: CustomPaint(
                  painter: _DashedBorderPainter(color: Colors.white.withOpacity(0.3), radius: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Add', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Gender (optional)'),
          const SizedBox(height: 8),
          _buildGenderDropdown(),
          const SizedBox(height: 8),
          Text('Choose whether this appears on your public profile.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF143029), // lighter card inside
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Show on profile', style: TextStyle(color: Colors.white, fontSize: 14)),
                Switch(
                  value: _showGender,
                  onChanged: (v) => setState(() => _showGender = v),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF6DE899),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF143029),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          isExpanded: true,
          dropdownColor: const Color(0xFF143029),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: _genders.map((g) => DropdownMenuItem(value: g, child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.white),
              const SizedBox(width: 12),
              Text(g),
            ],
          ))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _gender = v);
          },
        ),
      ),
    );
  }

  Widget _chip(String text, {required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF143029),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600));
  }

  Widget _textField(TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF143029),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6DE899))),
      ),
    );
  }

  Future<void> _editInstagram() async {
    final ctrl = TextEditingController(text: _instagramCtrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final f = ctx.fitlek;
        return AlertDialog(
          backgroundColor: f.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Instagram handle', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. mouad.coach',
              prefixText: '@',
              prefixStyle: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
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
              child: Text('Save', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (result != null) {
      setState(() => _instagramCtrl.text = result);
    }
  }

  Future<void> _openInstagram() async {
    final handle = _instagramCtrl.text.trim();
    if (handle.isEmpty) {
      _showSnack('Please add your Instagram handle first', isError: true);
      return;
    }
    final url = Uri.parse('https://instagram.com/$handle');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not launch Instagram', isError: true);
    }
  }

  Widget _buildContactCard(Color cardBg, ColorScheme cs, FitlekColors f) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contact', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _editInstagram,
            child: Row(
              children: [
                const InstagramIcon(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Instagram', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(_instagramCtrl.text.isNotEmpty ? '@${_instagramCtrl.text}' : 'Add Instagram', style: TextStyle(color: _instagramCtrl.text.isNotEmpty ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.4), fontSize: 13)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _openInstagram,
                  child: Row(
                    children: [
                      const Icon(Icons.open_in_new, color: Color(0xFF6DE899), size: 14),
                      const SizedBox(width: 4),
                      const Text('Open', style: TextStyle(color: Color(0xFF6DE899), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.email_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Email and phone are managed\nin Account settings.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ),
              Row(
                children: [
                  const Text('Account settings', style: TextStyle(color: Color(0xFF6DE899), fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Color(0xFF6DE899), size: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF0ECE1),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)))
              : const Text('Save changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
    const dashWidth = 5.0;
    const dashSpace = 4.0;
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

class InstagramIcon extends StatelessWidget {
  final double size;
  const InstagramIcon({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFFEDA77),
            Color(0xFFF58529),
            Color(0xFFDD2A7B),
            Color(0xFF8134AF),
            Color(0xFF515BD4),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: size * 0.08),
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
          ),
          Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: size * 0.08),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: size * 0.18,
            right: size * 0.18,
            child: Container(
              width: size * 0.1,
              height: size * 0.1,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
