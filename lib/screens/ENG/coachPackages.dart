import '../../services/image_upload_service.dart';
import 'package:http_parser/http_parser.dart';
import '../../services/media_picker_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import '../../constants/app_colors.dart';
import 'coachProfile.dart' show CoachProfileData;
import 'package:http/http.dart' as http;
import '../../constants/urls.dart' as urls;
import 'dart:io';

class CoachPackage {
  final int? id;
  String name;
  String description;
  int? sessions;
  int? duration;
  double? price;
  bool isPriceOnRequest;
  List<String> locations;
  String? imageUrl;
  bool isActive;

  CoachPackage({
    this.id,
    this.name = '',
    this.description = '',
    this.sessions,
    this.duration = 60,
    this.price,
    this.isPriceOnRequest = false,
    List<String>? locations,
    this.imageUrl,
    this.isActive = true,
  }) : locations = locations ?? [];

  factory CoachPackage.fromJson(Map<String, dynamic> json) {
    List<String> parseLocs(dynamic locs) {
      if (locs == null) return [];
      if (locs is List) return locs.map((e) => e.toString()).toList();
      if (locs is String) {
        try {
          final decoded = jsonDecode(locs);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return CoachPackage(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sessions: json['sessions'] != null
          ? int.tryParse(json['sessions'].toString())
          : null,
      duration: json['duration'] != null
          ? int.tryParse(json['duration'].toString())
          : 60,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      isPriceOnRequest:
          json['isPriceOnRequest'] == 1 || json['isPriceOnRequest'] == true,
      locations: parseLocs(json['locations']),
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] == 1 || json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'sessions': sessions,
        'duration': duration,
        'price': price,
        'isPriceOnRequest': isPriceOnRequest,
        'locations': locations,
        'imageUrl': imageUrl,
        'isActive': isActive,
      };
}

class CoachPackages extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachPackages({super.key, required this.profile, required this.token});

  @override
  State<CoachPackages> createState() => _CoachPackagesState();
}

class _CoachPackagesState extends State<CoachPackages> {
  bool _loading = true;
  List<CoachPackage> _packages = [];
  final int _maxPackages = 3;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final res =
          await ApiService.get('/packages/me?coachID=${widget.profile.id}');
      if (res['ok'] == true && res['data'] is List) {
        setState(() {
          _packages = (res['data'] as List)
              .map((e) => CoachPackage.fromJson(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading packages: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: context.fitlek.card));
  }

  Future<void> _deletePackage(int id) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: context.fitlek.card,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text('Delete Package',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
              content: Text('Are you sure you want to delete this package?',
                  style: TextStyle(color: context.fitlek.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel',
                        style: TextStyle(color: context.fitlek.textMuted))),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error))),
              ],
            ));
    if (confirm != true) return;

    try {
      await ApiService.delete('/packages/$id?coachID=${widget.profile.id}');
      _loadPackages();
      _showSnack('Package deleted');
    } catch (e) {
      _showSnack('Error deleting package');
    }
  }

  void _openPackageModal({CoachPackage? package}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PackageModal(
        package: package,
        coachID: widget.profile.id,
        token: widget.token,
        onSave: () {
          Navigator.pop(ctx);
          _loadPackages();
        },
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Text('${_packages.length} of $_maxPackages packages',
              style: TextStyle(
                  color: context.fitlek.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          SizedBox(width: 16),
          Expanded(
            child: Row(
              children: List.generate(_maxPackages, (index) {
                final isFilled = index < _packages.length;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? AppColors.success
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(CoachPackage pkg) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fitlek.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (pkg.imageUrl != null && pkg.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(pkg.imageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => _buildPlaceholderImage()),
            )
          else
            _buildPlaceholderImage(),

          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(pkg.name,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold))),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20),
                      color: context.fitlek.card,
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: AppColors.error))),
                      ],
                      onSelected: (val) {
                        if (val == 'delete' && pkg.id != null)
                          _deletePackage(pkg.id!);
                      },
                    ),
                  ],
                ),
                Text(
                  (pkg.sessions == null || pkg.sessions == 1)
                      ? 'Individual session'
                      : '${pkg.sessions} sessions · ${pkg.duration} min each',
                  style: TextStyle(
                      color: context.fitlek.textSecondary, fontSize: 13),
                ),
                if (pkg.description.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(pkg.description,
                      style: TextStyle(
                          color: context.fitlek.textMuted, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                if (pkg.locations.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Row(
                    children: pkg.locations
                        .map((loc) => Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                      loc.toLowerCase() == 'gym'
                                          ? Icons.fitness_center
                                          : Icons.videocam_outlined,
                                      color: context.fitlek.textSecondary,
                                      size: 12),
                                  SizedBox(width: 4),
                                  Text(loc,
                                      style: TextStyle(
                                          color: context.fitlek.textSecondary,
                                          fontSize: 11)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: pkg.isPriceOnRequest
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price on request',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: context.fitlek.textSecondary,
                                        size: 12),
                                    SizedBox(width: 4),
                                    Expanded(
                                        child: Text(
                                            'Agree on price before confirming a booking.',
                                            style: TextStyle(
                                                color: context
                                                    .fitlek.textSecondary,
                                                fontSize: 11))),
                                  ],
                                ),
                              ],
                            )
                          : RichText(
                              text: TextSpan(
                                text:
                                    '${pkg.price?.toStringAsFixed(0) ?? 0} MAD',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                                children: [
                                  TextSpan(
                                      text: ' / session',
                                      style: TextStyle(
                                          color: context.fitlek.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.normal)),
                                ],
                              ),
                            ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openPackageModal(package: pkg),
                      icon: Icon(Icons.edit,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface),
                      label: Text('Edit',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.fitlek.border),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: Size(0, 32),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.fitness_center, color: Colors.white24, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text('Services & packages',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.visibility_outlined,
                    size: 14, color: Theme.of(context).colorScheme.onSurface),
                label: Text('Preview',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.fitlek.border),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: Size(0, 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.only(bottom: 40),
              children: [
                _buildProgressHeader(),
                ..._packages.map(_buildPackageCard).toList(),
                if (_packages.length < _maxPackages)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () => _openPackageModal(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: AppColors.success, size: 18),
                            SizedBox(width: 8),
                            Text('Add package',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PackageModal extends StatefulWidget {
  final CoachPackage? package;
  final int coachID;
  final String token;
  final VoidCallback onSave;

  const _PackageModal(
      {this.package,
      required this.coachID,
      required this.token,
      required this.onSave});

  @override
  State<_PackageModal> createState() => _PackageModalState();
}

class _PackageModalState extends State<_PackageModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;

  int _sessions = 4;
  int _duration = 60;
  bool _isPriceOnRequest = false;
  List<String> _locations = ['Gym'];
  String? _imageUrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.package;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
        text: p?.price != null ? p!.price!.toStringAsFixed(0) : '');

    if (p != null) {
      _sessions = p.sessions ?? 1;
      _duration = p.duration ?? 60;
      _isPriceOnRequest = p.isPriceOnRequest;
      _locations = List.from(p.locations);
      _imageUrl = p.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = AppMediaPicker(context);
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() => _saving = true);
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('${urls.baseUrl}/upload/package-image'));
      req.headers['Authorization'] = 'Bearer ${widget.token}';
      final image = await ImageUploadService.prepare(await xfile.readAsBytes(),xfile.name);
final bytes = image.bytes;
      req.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: image.filename, contentType: MediaType.parse(image.mimeType)));

      final res = await req.send();
      final bodyStr = await res.stream.bytesToString();
      if (res.statusCode == 200 || res.statusCode == 201) {
        final j = jsonDecode(bodyStr);
        setState(() => _imageUrl = j['fileUrl']);
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _toggleLoc(String loc) {
    setState(() {
      if (_locations.contains(loc))
        _locations.remove(loc);
      else
        _locations.add(loc);
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final body = {
      'coachID': widget.coachID,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'sessions': _sessions,
      'duration': _duration,
      'price': _isPriceOnRequest ? null : double.tryParse(_priceCtrl.text),
      'isPriceOnRequest': _isPriceOnRequest,
      'locations': _locations,
      'imageUrl': _imageUrl,
      'isActive': true,
    };

    try {
      if (widget.package == null) {
        await ApiService.post('/packages', body);
      } else {
        await ApiService.put('/packages/${widget.package!.id}', body);
      }
      widget.onSave();
    } catch (e) {
      debugPrint('Save err: $e');
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving package'),
            backgroundColor: context.fitlek.card));
      }
    }
  }

  Widget _buildCounter(String label, int value, VoidCallback onDec,
      VoidCallback onInc, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFF0F261F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.fitlek.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$value $suffix',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14)),
              Row(
                children: [
                  GestureDetector(
                    onTap: onDec,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(Icons.remove,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: onInc,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(Icons.add,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 16),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.fitlek.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.package == null ? 'Add package' : 'Edit package',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: Icon(Icons.close, color: context.fitlek.textMuted),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image upload
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Color(0xFF0F261F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.fitlek.border),
                            image: _imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_imageUrl!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: _imageUrl == null
                              ? Icon(Icons.add_a_photo,
                                  color: context.fitlek.textMuted)
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    Text('Name',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Strength starter',
                        hintStyle: TextStyle(
                            color: context.fitlek.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: Color(0xFF0F261F),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: context.fitlek.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: context.fitlek.border)),
                      ),
                    ),
                    SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                            child: _buildCounter('Sessions', _sessions, () {
                          if (_sessions > 1) setState(() => _sessions--);
                        }, () => setState(() => _sessions++), '')),
                        SizedBox(width: 16),
                        Expanded(
                            child: _buildCounter('Duration', _duration, () {
                          if (_duration > 15) setState(() => _duration -= 15);
                        }, () => setState(() => _duration += 15), 'min')),
                      ],
                    ),
                    SizedBox(height: 20),

                    Text('Pricing',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isPriceOnRequest = false),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: !_isPriceOnRequest
                                    ? AppColors.success.withOpacity(0.1)
                                    : Color(0xFF0F261F),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: !_isPriceOnRequest
                                        ? AppColors.success
                                        : context.fitlek.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                          !_isPriceOnRequest
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          color: !_isPriceOnRequest
                                              ? AppColors.success
                                              : context.fitlek.textMuted,
                                          size: 16),
                                      SizedBox(width: 8),
                                      Text('Fixed price',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text('Set a specific price',
                                      style: TextStyle(
                                          color: context.fitlek.textMuted,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isPriceOnRequest = true),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isPriceOnRequest
                                    ? AppColors.success.withOpacity(0.1)
                                    : Color(0xFF0F261F),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _isPriceOnRequest
                                        ? AppColors.success
                                        : context.fitlek.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                          _isPriceOnRequest
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          color: _isPriceOnRequest
                                              ? AppColors.success
                                              : context.fitlek.textMuted,
                                          size: 16),
                                      SizedBox(width: 8),
                                      Text('On request',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                      'Agree on price before confirming a booking.',
                                      style: TextStyle(
                                          color: context.fitlek.textMuted,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!_isPriceOnRequest) ...[
                      SizedBox(height: 12),
                      TextField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Price (MAD)',
                          hintStyle: TextStyle(
                              color: context.fitlek.textMuted, fontSize: 14),
                          filled: true,
                          fillColor: Color(0xFF0F261F),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: context.fitlek.border)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: context.fitlek.border)),
                        ),
                      ),
                    ],
                    SizedBox(height: 20),

                    Text('Locations',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _buildLocToggle('Gym'),
                        SizedBox(width: 12),
                        _buildLocToggle('Online'),
                      ],
                    ),
                    SizedBox(height: 20),

                    Text('What\'s included',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      maxLength: 500,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Describe what the package includes...',
                        hintStyle: TextStyle(
                            color: context.fitlek.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: Color(0xFF0F261F),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: context.fitlek.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: context.fitlek.border)),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sand,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : Text('Save changes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocToggle(String loc) {
    final sel = _locations.contains(loc);
    return GestureDetector(
      onTap: () => _toggleLoc(loc),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.success.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? AppColors.success : context.fitlek.border),
        ),
        child: Row(
          children: [
            Icon(loc == 'Gym' ? Icons.fitness_center : Icons.videocam_outlined,
                color: sel
                    ? AppColors.success
                    : Theme.of(context).colorScheme.onSurface,
                size: 14),
            SizedBox(width: 6),
            Text(loc,
                style: TextStyle(
                    color: sel
                        ? AppColors.success
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
