import '../../components/app_dialog.dart';
import '../../services/image_upload_service.dart';
import 'package:http_parser/http_parser.dart';
import '../../services/media_picker_service.dart';
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

class CoachPhotos extends StatefulWidget {
  final CoachProfileData profile;
  final String token;

  const CoachPhotos({super.key, required this.profile, required this.token});

  @override
  State<CoachPhotos> createState() => _CoachPhotosState();
}

class _CoachPhotosState extends State<CoachPhotos> {
  bool _saving = false;
  late String _ville;
  late String _gymName;
  late String _gymAddress;
  late String _gymImage;
  late String _serviceArea;
  List<String> _coachingFormats = [];

  List<Map<String, dynamic>> _galleryImages = [];
  bool _loadingGallery = true;
  String _caption = '';
  int? _selectedPhotoIndex;
  final TextEditingController _captionCtrl = TextEditingController();

  final List<String> _moroccoCities = [
    'Casablanca', 'Rabat', 'Marrakech', 'Fes', 'Tangier', 'Agadir', 'Meknes', 'Oujda'
  ];

  List<Map<String, dynamic>> _getFormats(AppLocalizations l10n) => [
    {'id': 'gym', 'label': l10n.coachPhotosFormatGym, 'icon': Icons.fitness_center},
    {'id': 'online', 'label': l10n.coachPhotosFormatOnline, 'icon': Icons.laptop_mac},
    {'id': 'home', 'label': l10n.coachPhotosFormatHome, 'icon': Icons.home_outlined},
    {'id': 'outdoors', 'label': l10n.coachPhotosFormatOutdoors, 'icon': Icons.park_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _ville = widget.profile.ville.isNotEmpty ? widget.profile.ville : 'Casablanca';
    _gymName = '';
    _gymAddress = '';
    _gymImage = '';
    _serviceArea = ''; // We will load from API
    _loadProfileData();
    _loadGallery();

    _captionCtrl.addListener(() {
      if (_selectedPhotoIndex != null && _selectedPhotoIndex! < _galleryImages.length) {
        setState(() {
          _galleryImages[_selectedPhotoIndex!]['caption'] = _captionCtrl.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final res = await ApiService.get('/coaches/me/profile?userID=${widget.profile.id}');
      if (res['ok'] == true && mounted) {
        setState(() {
          _ville = res['ville'] ?? 'Casablanca';
          _gymName = res['gymName'] ?? '';
          _gymAddress = res['gymAddress'] ?? '';
          _gymImage = res['gymImage'] ?? '';
          _serviceArea = res['serviceArea'] ?? '';
          if (res['coachingFormats'] != null) {
            try {
              if (res['coachingFormats'] is String) {
                _coachingFormats = List<String>.from(jsonDecode(res['coachingFormats']));
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

  Future<void> _loadGallery() async {
    try {
      final res = await ApiService.get('/coaches/${widget.profile.id}/images');
      if (mounted) {
        setState(() {
          if (res['ok'] == true && res['data'] != null) {
            _galleryImages = List<Map<String, dynamic>>.from(res['data']);
            if (_galleryImages.isNotEmpty) {
              _selectedPhotoIndex = 0;
              _captionCtrl.text = _galleryImages[0]['caption'] ?? '';
            } else {
              _selectedPhotoIndex = null;
              _captionCtrl.text = '';
            }
          }
          _loadingGallery = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGallery = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.put('/coaches/me/profile', {
        'userID': widget.profile.id,
        'ville': _ville,
        'gymName': _gymName,
        'gymAddress': _gymAddress,
        'gymImage': _gymImage,
        'serviceArea': _serviceArea,
        'coachingFormats': _coachingFormats,
      });

      // Save caption for selected image if needed
      if (_selectedPhotoIndex != null && _selectedPhotoIndex! < _galleryImages.length) {
        final img = _galleryImages[_selectedPhotoIndex!];
        await ApiService.put('/coaches/${widget.profile.id}/images/${img['id']}', {
          'caption': _captionCtrl.text
        });
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (res['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.coachPhotosSaveSuccess)));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.coachPhotosSaveFailed('${res['error'] ?? res['message']}'))));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).coachPhotosErrorGeneric('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final availableSlots = 5 - _galleryImages.length;
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.coachPhotosMaxPhotos)));
      return;
    }

    final picker = AppMediaPicker(context);
    final List<XFile> xfiles = await picker.pickMultiImage();
    if (xfiles.isEmpty) return;

    final filesToUpload = xfiles.take(availableSlots).toList();
    if (xfiles.length > availableSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).coachPhotosPartialSlots(availableSlots))));
    }

    setState(() => _saving = true);
    try {
      bool anySuccess = false;
      for (final xfile in filesToUpload) {
        final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/coach-gallery'));
        req.headers['Authorization'] = 'Bearer ${widget.token}';
        req.fields['coachID'] = widget.profile.id.toString();
        final image = await ImageUploadService.prepare(await xfile.readAsBytes(),xfile.name);
        final bytes = image.bytes;
        req.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.filename, contentType: MediaType.parse(image.mimeType)));

        final res = await req.send();
        if (res.statusCode == 200 || res.statusCode == 201) {
          anySuccess = true;
        }
      }
      if (anySuccess) {
        await _loadGallery();
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePhoto(int id) async {
    setState(() => _saving = true);
    try {
      final res = await ApiService.delete('/coaches/${widget.profile.id}/images/$id');
      if (res['ok'] == true) {
        await _loadGallery();
      }
    } catch (e) {
      debugPrint('Delete error: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F261F), // Dark background matching the screenshot
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.coachPhotosTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(l10n.coachPhotosPreview, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: _saving && _galleryImages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(l10n.coachPhotosPortfolioTitle),
                      Text('${_galleryImages.length} / 5', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.coachPhotosPortfolioSubtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                  const SizedBox(height: 16),

                  _loadingGallery
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: (_galleryImages.length < 5) ? _galleryImages.length + 1 : 5,
                          itemBuilder: (context, index) {
                            if (index == _galleryImages.length) {
                              return GestureDetector(
                                onTap: _addPhoto,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white.withOpacity(0.3), style: BorderStyle.none),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: CustomPaint(
                                    painter: DashedRectPainter(color: Colors.white.withOpacity(0.3)),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_circle_outline, color: Colors.white70, size: 32),
                                          const SizedBox(height: 8),
                                          Text(l10n.coachPhotosAddPhoto, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final img = _galleryImages[index];
                            final isSelected = _selectedPhotoIndex == index;
                            return GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(img['urlImage'], fit: BoxFit.contain),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deletePhoto(img['id']);
                                              },
                                              icon: const Icon(Icons.delete, color: Colors.white),
                                              label: Text(l10n.coachPhotosDelete, style: const TextStyle(color: Colors.white)),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                setState(() {
                                                  _selectedPhotoIndex = index;
                                                  _captionCtrl.text = img['caption'] ?? '';
                                                });
                                              },
                                              icon: const Icon(Icons.edit, color: Colors.white),
                                              label: Text(l10n.coachPhotosEditCaption, style: const TextStyle(color: Colors.white)),
                                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(img['urlImage']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (index == 0)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(l10n.coachPhotosCover, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _deletePhoto(img['id']),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  if (_selectedPhotoIndex != null && _selectedPhotoIndex! < _galleryImages.length) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle(l10n.coachPhotosCaptionTitle),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _captionCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLength: 140,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: l10n.coachPhotosCaptionHint,
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        counterStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8E1D9), // Light button color matching mockup
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _saving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Text(l10n.coachPhotosSaveChanges, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
            title: Text(l10n.coachPhotosEditGymDialogTitle, style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: TextEditingController(text: tempName)..selection = TextSelection.fromPosition(TextPosition(offset: tempName.length)),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l10n.coachPhotosGymNameLabel,
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: l10n.coachPhotosGymNameHint,
                      hintStyle: const TextStyle(color: Colors.white54),
                    ),
                    onChanged: (val) => tempName = val,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: TextEditingController(text: tempAddress)..selection = TextSelection.fromPosition(TextPosition(offset: tempAddress.length)),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l10n.coachPhotosAddressLabel,
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: l10n.coachPhotosAddressHint,
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
                          child: Image.network(tempImage, width: 40, height: 40, fit: BoxFit.cover),
                        ),
                      if (tempImage.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final picker = AppMediaPicker(context);
                                  final xfile = await picker.pickImage(source: ImageSource.gallery);
                                  if (xfile != null) {
                                    setDialogState(() => isUploading = true);
                                    try {
                                      final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/gym-image'));
                                      req.headers['Authorization'] = 'Bearer ${widget.token}';
                                      final image = await ImageUploadService.prepare(await xfile.readAsBytes(),xfile.name);
                                      final bytes = image.bytes;
                                      req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.filename, contentType: MediaType.parse(image.mimeType)));
                                      final res = await req.send();
                                      if (res.statusCode == 200 || res.statusCode == 201) {
                                        final respStr = await res.stream.bytesToString();
                                        final data = jsonDecode(respStr);
                                        if (data['fileUrl'] != null) {
                                          setDialogState(() => tempImage = data['fileUrl']);
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
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.image, size: 18),
                          label: Text(isUploading ? l10n.coachPhotosUploading : l10n.coachPhotosUploadImage),
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
                child: Text(l10n.coachPhotosCancel, style: const TextStyle(color: Colors.white70)),
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
                child: Text(l10n.coachPhotosSave, style: const TextStyle(color: Colors.white)),
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
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));
    
    // Simple dash effect
    Path dashPath = Path();
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    for (ui.PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(measurePath.extractPath(distance, distance + dashWidth), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
