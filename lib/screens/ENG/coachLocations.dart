import '../../components/app_dialog.dart';
import '../../services/image_upload_service.dart';
import 'package:http_parser/http_parser.dart';
import '../../services/media_picker_service.dart';
import 'userLocationSettings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:fitlek1/constants/urls.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../../services/apiService.dart';
import '../../theme/fitlek_theme_extension.dart';
import 'coachProfile.dart' show CoachProfileData;
import 'coachCalendar.dart';

class CoachLocations extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachLocations({super.key, required this.profile, required this.token});

  @override
  State<CoachLocations> createState() => _CoachLocationsState();
}

class _CoachLocationsState extends State<CoachLocations> {
  bool _saving = false;
  late String _ville;
  late String _gymName;
  late String _gymAddress;
  late String _gymImage;
  late String _serviceArea;
  List<String> _coachingFormats = [];

  List<Map<String, dynamic>> _getFormats(AppLocalizations l10n) => [
    {'id': 'gym', 'label': l10n.coachLocationsFormatGym, 'icon': Icons.fitness_center},
    {'id': 'online', 'label': l10n.coachLocationsFormatOnline, 'icon': Icons.laptop_mac},
    {'id': 'home', 'label': l10n.coachLocationsFormatHome, 'icon': Icons.home_outlined},
    {'id': 'outdoors', 'label': l10n.coachLocationsFormatOutdoors, 'icon': Icons.park_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _ville = widget.profile.ville;
    _gymName = '';
    _gymAddress = '';
    _gymImage = '';
    _serviceArea = ''; // We will load from API
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final res = await ApiService.get(
          '/coaches/me/profile?userID=${widget.profile.id}');
      if (res['ok'] == true && mounted) {
        setState(() {
          _ville = res['ville'] ?? '';
          _gymName = res['gymName'] ?? '';
          _gymAddress = res['gymAddress'] ?? '';
          _gymImage = res['gymImage'] ?? '';
          _serviceArea = res['serviceArea'] ?? '';
          if (res['coachingFormats'] != null) {
            try {
              if (res['coachingFormats'] is String) {
                _coachingFormats =
                    List<String>.from(jsonDecode(res['coachingFormats']));
              } else {
                _coachingFormats = List<String>.from(res['coachingFormats']);
              }
            } catch (e) {
              _coachingFormats = [];
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.put('/coaches/me/profile', {
        'userID': widget.profile.id,
        'gymName': _gymName,
        'gymAddress': _gymAddress,
        'gymImage': _gymImage,
        'serviceArea': _serviceArea,
        'coachingFormats': _coachingFormats,
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (res['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.coachLocationsSaveSuccess)));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n.coachLocationsSaveFailed(
                  '${res['error'] ?? res['message']}'))));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)
                .coachLocationsErrorGeneric('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleFormat(String id) {
    setState(() {
      if (_coachingFormats.contains(id)) {
        _coachingFormats.remove(id);
      } else {
        _coachingFormats.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formats = _getFormats(l10n);
    return Scaffold(
      backgroundColor:
          const Color(0xFF0F261F), // Dark background matching the screenshot
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.coachLocationsTitle,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(l10n.coachLocationsPreview,
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(l10n.coachLocationsFormatsTitle),
            const SizedBox(height: 4),
            Text(l10n.coachLocationsFormatsSubtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 16),

            // Coaching formats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: formats.map((f) {
                final isSelected = _coachingFormats.contains(f['id']);
                return GestureDetector(
                  onTap: () => _toggleFormat(f['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15)
                          : Colors.transparent,
                      border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(f['icon'],
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                                  size: 24),
                              const SizedBox(height: 4),
                              Text(f['label'],
                                  style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withOpacity(0.5),
                            size: 16,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(l10n.coachLocationsCityTitle),
            OutlinedButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text(l10n.coachLocationsUpdateLocation),
                onPressed: () async {
                  final city = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                          builder: (_) => const UserLocationSettings()));
                  if (mounted && city != null)
                    setState(() {
                      _ville = city;
                    });
                }),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_ville.isEmpty ? l10n.coachLocationsDetectCityHint : _ville,
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(l10n.coachLocationsGymLocationTitle),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _gymImage.isNotEmpty
                        ? Image.network(_gymImage,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[800],
                                child: const Icon(Icons.fitness_center)))
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: const Icon(Icons.fitness_center,
                                color: Colors.white54)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_gymName.isNotEmpty ? _gymName : l10n.coachLocationsSelectGym,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(_gymAddress.isNotEmpty ? _gymAddress : '$_ville',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showEditLocationDialog();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(l10n.coachLocationsEditLocation,
                              style:
                                  const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(l10n.coachLocationsServiceAreaTitle),
            const SizedBox(height: 4),
            Text(l10n.coachLocationsServiceAreaSubtitle,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (val) => _serviceArea = val,
              controller: TextEditingController(text: _serviceArea)
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _serviceArea.length)),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon:
                    const Icon(Icons.map_outlined, color: Colors.white70),
                hintText: l10n.coachLocationsServiceAreaHint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.white),
              title: Text(l10n.coachLocationsOpenCalendar,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(l10n.coachLocationsManageAvailability,
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoachCalendar()),
                );
              },
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                      0xFFE8E1D9), // Light button color matching mockup
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2))
                    : Text(l10n.coachLocationsSaveChanges,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  void _showEditLocationDialog() {
    String tempName = _gymName;
    String tempAddress = _gymAddress;
    String tempImage = _gymImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final l10n = AppLocalizations.of(ctx);
          return AppDialog(
            backgroundColor: const Color(0xFF1E3A32),
            title: Text(l10n.coachLocationsEditGymDialogTitle,
                style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: TextEditingController(text: tempName)
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: tempName.length)),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l10n.coachLocationsGymNameLabel,
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: l10n.coachLocationsGymNameHint,
                      hintStyle: const TextStyle(color: Colors.white54),
                    ),
                    onChanged: (val) => tempName = val,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: tempAddress)
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: tempAddress.length)),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l10n.coachLocationsAddressLabel,
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: l10n.coachLocationsAddressHint,
                      hintStyle: const TextStyle(color: Colors.white54),
                    ),
                    onChanged: (val) => tempAddress = val,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (tempImage.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(tempImage,
                              width: 40, height: 40, fit: BoxFit.cover),
                        ),
                      if (tempImage.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final picker = AppMediaPicker(context);
                                  final xfile = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (xfile != null) {
                                    setDialogState(() => isUploading = true);
                                    try {
                                      final req = http.MultipartRequest('POST',
                                          Uri.parse('$baseUrl/upload/gym-image'));
                                      req.headers['Authorization'] =
                                          'Bearer ${widget.token}';
                                      final image = await ImageUploadService.prepare(await xfile.readAsBytes(),xfile.name);
                                      final bytes = image.bytes;
                                      req.files.add(http.MultipartFile.fromBytes(
                                          'file', bytes,
                                          filename: image.filename, contentType: MediaType.parse(image.mimeType)));
                                      final res = await req.send();
                                      if (res.statusCode == 200 ||
                                          res.statusCode == 201) {
                                        final respStr =
                                            await res.stream.bytesToString();
                                        final data = jsonDecode(respStr);
                                        if (data['fileUrl'] != null) {
                                          setDialogState(
                                              () => tempImage = data['fileUrl']);
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('Upload err: $e');
                                    } finally {
                                      setDialogState(() => isUploading = false);
                                    }
                                  }
                                },
                          icon: isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.image, size: 18),
                          label: Text(isUploading
                              ? l10n.coachLocationsUploading
                              : l10n.coachLocationsUploadImage),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.coachLocationsCancel,
                    style: const TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: isUploading
                    ? null
                    : () {
                        setState(() {
                          _gymName = tempName;
                          _gymAddress = tempAddress;
                          _gymImage = tempImage;
                        });
                        Navigator.pop(ctx);
                      },
                child: Text(l10n.coachLocationsSave,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Simple dashed rect painter for the "Add photo" button
class DashedRectPainter extends CustomPainter {
  final Color color;
  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8)));

    // Simple dash effect
    Path dashPath = Path();
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    for (ui.PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
            measurePath.extractPath(distance, distance + dashWidth),
            Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
