import '../../services/media_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'coachProfile.dart' show CoachProfileData;

class CoachExpertise extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachExpertise({super.key, required this.profile, required this.token});

  @override
  State<CoachExpertise> createState() => _CoachExpertiseState();
}

class _CoachExpertiseState extends State<CoachExpertise> {
  bool _saving = false;
  int? _categoryID;
  String? _experience;
  List<String> _clientLevels = [];
  List<String> _specialties = [];
  List<dynamic> _certifications = [];

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  final List<String> _suggestedSpecialties = [
    'Functional training', 'Conditioning', 'Powerlifting', 'Bodybuilding',
    'Rehabilitation', 'Nutrition coaching', 'Yoga', 'Pilates'
  ];

  @override
  void initState() {
    super.initState();
    _categoryID = widget.profile.categoryID;
    _experience = widget.profile.experience.isEmpty ? null : widget.profile.experience;
    _clientLevels = List.from(widget.profile.clientLevels);
    _specialties = List.from(widget.profile.specialties);
    _certifications = List.from(widget.profile.certifications);
    _fetchCategories();
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'reviewing': return 'Reviewing';
      default: return 'Self-reported';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'reviewing': return AppColors.warning;
      default: return Colors.white;
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await ApiService.get('/categories');
      if (res['ok'] == true && res['data'] is List) {
        if (mounted) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(res['data']);
            _loadingCategories = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingCategories = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingCategories = false);
    }
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

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'experience': _experience ?? '',
        'categoryID': _categoryID,
        'clientLevels': _clientLevels,
        'specialties': _specialties,
        'certifications': _certifications,
        // Include other required fields to pass validation
        'firstName': widget.profile.firstName,
        'lastName': widget.profile.lastName,
        'gender': widget.profile.gender,
        'bio': widget.profile.bio,
      };

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

  void _addSpecialty() async {
    if (_specialties.length >= 5) {
      _showSnack('You can add up to 5 specialties', isError: true);
      return;
    }
    // simple dialog to add specialty
    final textCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitlek.card,
        title: Text('Add specialty', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
        content: TextField(
          controller: textCtrl,
          style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
          decoration: const InputDecoration(hintText: 'e.g. Strength building'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, textCtrl.text), child: const Text('Add')),
        ],
      )
    );
    if (result != null && result.trim().isNotEmpty) {
      if (!_specialties.contains(result.trim())) {
        setState(() => _specialties.add(result.trim()));
      }
    }
  }

  void _addCertification() async {
    final nameCtrl = TextEditingController();
    final providerCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    String? fileUrl;
    bool isUploading = false;
    final picker = AppMediaPicker(context);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: context.fitlek.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Add certification', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(nameCtrl, 'Certificate Name', ctx),
                  const SizedBox(height: 12),
                  _buildDialogTextField(providerCtrl, 'Provider / Academy', ctx),
                  const SizedBox(height: 12),
                  _buildDialogTextField(yearCtrl, 'Year', ctx, isNumber: true),
                  const SizedBox(height: 16),
                  if (fileUrl != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('File uploaded', style: TextStyle(color: Colors.white, fontSize: 13))),
                          GestureDetector(
                            onTap: () => setDialogState(() => fileUrl = null),
                            child: const Icon(Icons.cancel, color: Colors.white54, size: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        try {
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setDialogState(() => isUploading = true);
                            final bytes = await image.readAsBytes();
                            final uploadRes = await ApiService.uploadMultipart(
                              '/upload/certification',
                              fields: {},
                              fileBytes: bytes,
                              fileField: 'certificate',
                              fileName: image.name,
                              mimeType: image.mimeType ?? 'image/jpeg',
                            );
                            if (uploadRes['ok'] == true && uploadRes['url'] != null) {
                              setDialogState(() {
                                fileUrl = uploadRes['url'];
                                isUploading = false;
                              });
                            } else {
                              setDialogState(() => isUploading = false);
                              _showSnack(uploadRes['error']?.toString() ?? uploadRes['message']?.toString() ?? 'Upload failed', isError: true);
                            }
                          }
                        } catch (e) {
                          setDialogState(() => isUploading = false);
                          _showSnack('Error picking file', isError: true);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.fitlek.border, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF0F261F),
                        ),
                        child: isUploading 
                          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file, color: Theme.of(context).colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                const Text('Upload certificate', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, {
                    'name': nameCtrl.text.trim(),
                    'provider': providerCtrl.text.trim(),
                    'year': yearCtrl.text.trim(),
                    if (fileUrl != null) 'fileUrl': fileUrl,
                  });
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      )
    );

    if (result != null) {
      setState(() => _certifications.add(result));
    }
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, BuildContext ctx, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface, fontSize: 14),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.fitlek.textMuted, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF0F261F),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.fitlek.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.fitlek.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(ctx).colorScheme.primary),
        ),
      ),
    );
  }

  void _viewDetails(Map cert) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.fitlek.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.fitlek.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F261F),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: context.fitlek.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.workspace_premium_rounded, color: Theme.of(ctx).colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Certification Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(cert['status'] == 'approved' ? 'Verified Certificate' : 'Review in progress', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Name', cert['name'] ?? ''),
                    const SizedBox(height: 16),
                    _buildDetailRow('Provider / Academy', cert['provider'] ?? ''),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDetailRow('Year', cert['year'] ?? '')),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status', style: TextStyle(color: context.fitlek.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(cert['status']).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_getStatusLabel(cert['status']), style: TextStyle(color: _getStatusColor(cert['status']), fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (cert['fileUrl'] != null) ...[
                      const SizedBox(height: 24),
                      const Text('Attached Document', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  InteractiveViewer(
                                    clipBehavior: Clip.none,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        cert['fileUrl'],
                                        fit: BoxFit.contain,
                                        loadingBuilder: (ctx, child, progress) {
                                          if (progress == null) return child;
                                          return const SizedBox(
                                            height: 300,
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        },
                                        errorBuilder: (ctx, err, stack) => Container(
                                          height: 200,
                                          width: double.infinity,
                                          decoration: BoxDecoration(color: context.fitlek.card, borderRadius: BorderRadius.circular(12)),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image, color: Colors.white54, size: 40),
                                              SizedBox(height: 8),
                                              Text('Failed to load document', style: TextStyle(color: Colors.white54)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F261F),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.fitlek.border),
                            image: DecorationImage(
                              image: NetworkImage(cert['fileUrl']),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 32),
                                  SizedBox(height: 4),
                                  Text('Tap to preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.fitlek.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fitlek.border),
      ),
      child: child,
    );
  }

  Widget _buildPrimaryCategory() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Primary category', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F261F), // dark inner bg
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.fitlek.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _categoryID,
                hint: Text('Select category', style: TextStyle(color: context.fitlek.textMuted)),
                isDense: false,
                isExpanded: true,
                dropdownColor: context.fitlek.card,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.fitlek.textMuted),
                items: _categories.map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center_rounded, color: context.fitlek.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(c['name'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoryID = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingSince() {
    final currentYear = DateTime.now().year;
    final years = List.generate(40, (i) => (currentYear - i).toString());

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Coaching since', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F261F), // dark inner bg
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.fitlek.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _experience,
                hint: Text('Select year', style: TextStyle(color: context.fitlek.textMuted)),
                isDense: false,
                isExpanded: true,
                dropdownColor: context.fitlek.card,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.fitlek.textMuted),
                items: years.map((y) => DropdownMenuItem<String>(
                  value: y,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: context.fitlek.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Text(y, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
                    ],
                  ),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _experience = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoYouCoach() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who you coach', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLevelBtn('Beginners', Icons.person_outline),
              const SizedBox(width: 8),
              _buildLevelBtn('Intermediate', Icons.bar_chart_rounded),
              const SizedBox(width: 8),
              _buildLevelBtn('Advanced', Icons.directions_run_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBtn(String label, IconData icon) {
    final isSelected = _clientLevels.contains(label);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) _clientLevels.remove(label);
            else _clientLevels.add(label);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : const Color(0xFF0F261F),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : context.fitlek.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : context.fitlek.textSecondary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: isSelected ? Colors.white : context.fitlek.textSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: isSelected ? Theme.of(context).colorScheme.primary : context.fitlek.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialties() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Specialties', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Add up to 5 specialties that best match your coaching.', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          if (_specialties.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _specialties.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F261F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _specialties.remove(s)),
                      child: Icon(Icons.cancel_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                    ),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: _addSpecialty,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F261F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Add specialty', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Suggested for you', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedSpecialties.where((s) => !_specialties.contains(s)).map((s) => GestureDetector(
              onTap: () {
                if (_specialties.length < 5) setState(() => _specialties.add(s));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F261F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.fitlek.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(s, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCertifications() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Certifications', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Add your relevant certifications and credentials.', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ..._certifications.map((cert) {
            if (cert is! Map) return const SizedBox();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F261F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.workspace_premium_rounded, color: context.fitlek.textSecondary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cert['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('${cert['provider'] ?? ''} • ${cert['year'] ?? ''}', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (cert['fileUrl'] != null)
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        clipBehavior: Clip.none,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(cert['fileUrl'], fit: BoxFit.contain),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black87,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.close, color: Colors.white),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.description, color: Theme.of(context).colorScheme.primary, size: 16),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(cert['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_getStatusLabel(cert['status']), style: TextStyle(color: _getStatusColor(cert['status']), fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: context.fitlek.border, height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _viewDetails(cert),
                          icon: Icon(Icons.visibility_outlined, color: context.fitlek.textSecondary, size: 16),
                          label: const Text('View details', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                      if (cert['status'] != 'approved' && cert['status'] != 'reviewing') ...[
                        Container(width: 1, height: 20, color: context.fitlek.border),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() => cert['status'] = 'reviewing');
                              _showSnack('The review process will take up to 48 hours.');
                            },
                            icon: Icon(Icons.description_outlined, color: context.fitlek.textSecondary, size: 16),
                            label: Text(cert['status'] == 'rejected' ? 'Resubmit' : 'Submit for verification', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            );
          }),
          GestureDetector(
            onTap: _addCertification,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F261F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.fitlek.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('Add certification', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: context.fitlek.textSecondary, size: 14),
              const SizedBox(width: 6),
              Text('Only reviewed credentials receive a verified badge.', style: TextStyle(color: context.fitlek.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = const Color(0xFF0A1817);

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
        title: const Text('Expertise', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text('Preview', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPrimaryCategory(),
                _buildCoachingSince(),
                _buildWhoYouCoach(),
                _buildSpecialties(),
                _buildCertifications(),
                const SizedBox(height: 80), // space for bottom button
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: bgDark,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: TextButton(
          onPressed: _save,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.sand,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
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
