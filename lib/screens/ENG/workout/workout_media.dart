import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../services/apiService.dart';
import '../../../services/workout_service.dart';
import '../../../models/workout.dart';
import 'workout_ui.dart';

class WorkoutMediaPanel extends StatefulWidget {
  final int? sessionID, exerciseID;
  const WorkoutMediaPanel({super.key, this.sessionID, this.exerciseID})
      : assert((sessionID == null) != (exerciseID == null));
  @override
  State<WorkoutMediaPanel> createState() => _WorkoutMediaPanelState();
}

class _WorkoutMediaPanelState extends State<WorkoutMediaPanel> {
  List<Map<String, dynamic>> _media = [];
  bool _upload = false, _busy = false;
  Object? _error;
  String get _path => widget.sessionID != null
      ? '/sessions/${widget.sessionID}/media'
      : '/exercises/${widget.exerciseID}/media';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await WorkoutService.get(_path);
      if (mounted) {
        setState(() {
          _media = workoutRows(result['data']);
          _upload = result['canUpload'] == true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _add() async {
    final chosen = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
        withData: true);
    if (chosen == null || !mounted) return;
    final file = chosen.files.single;
    if (file.size > 30 * 1024 * 1024 || file.bytes == null) {
      workoutError(context, const WorkoutApiException('invalid_media', 400));
      return;
    }
    setState(() => _busy = true);
    try {
      WorkoutService.checked(await ApiService.uploadMultipart('/workout$_path',
          fields: {},
          fileBytes: file.bytes!,
          fileField: 'file',
          fileName: file.name,
          mimeType: file.extension == 'mp4'
              ? 'video/mp4'
              : 'image/${file.extension}'));
      await _load();
    } catch (e) {
      if (mounted) workoutError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(int id) async {
    final yes = await workoutDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const WorkoutLabel('Remove attachment?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const WorkoutLabel('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const WorkoutLabel('Delete'))
                ]));
    if (yes != true) return;
    try {
      WorkoutService.checked(await ApiService.delete('/workout/media/$id'));
      await _load();
    } catch (e) {
      if (mounted) workoutError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null)
          TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const WorkoutLabel('Reload attachments')),
        ..._media.map((m) => Card(
                child: Column(children: [
              _WorkoutMediaPreview(
                  id: workoutInt(m['id']), video: m['mimeType'] == 'video/mp4'),
              if (_upload)
                Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                        tooltip: (('Remove attachment')).workoutTr(context),
                        onPressed: () => _remove(workoutInt(m['id'])),
                        icon: const Icon(Icons.delete_outline)))
            ]))),
        if (_upload && _media.length < 10)
          OutlinedButton.icon(
              onPressed: _busy ? null : _add,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: WorkoutLabel(widget.sessionID != null
                  ? 'Add workout photo or video'
                  : 'Add demonstration'))
      ]);
}

class _WorkoutMediaPreview extends StatefulWidget {
  final int id;
  final bool video;
  const _WorkoutMediaPreview({required this.id, required this.video});
  @override
  State<_WorkoutMediaPreview> createState() => _WorkoutMediaPreviewState();
}

class _WorkoutMediaPreviewState extends State<_WorkoutMediaPreview> {
  String? _url;
  VideoPlayerController? _controller;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await WorkoutService.get('/media/${widget.id}/ticket');
      final url =
          '${ApiService.baseUrl}/workout/media/${widget.id}/content?ticket=${Uri.encodeQueryComponent(result['ticket'])}';
      if (widget.video) {
        final c = VideoPlayerController.networkUrl(Uri.parse(url));
        await c.initialize();
        if (!mounted) {
          await c.dispose();
          return;
        }
        final previous = _controller;
        _controller = c;
        await previous?.dispose();
      }
      if (mounted) {
        setState(() {
          _url = url;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return TextButton(
          onPressed: _load, child: const WorkoutLabel('Reload media'));
    }
    if (_url == null) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()));
    }
    if (!widget.video) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(_url!,
              fit: BoxFit.contain,
              height: 240,
              errorBuilder: (_, __, ___) => TextButton(
                  onPressed: _load,
                  child: const WorkoutLabel('Reload media'))));
    }
    return Column(children: [
      AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!)),
      Row(children: [
        IconButton(
            tooltip: ((_controller!.value.isPlaying ? 'Pause' : 'Play'))
                .workoutTr(context),
            onPressed: () async {
              if (_controller!.value.isPlaying) {
                await _controller!.pause();
              } else {
                await _controller!.play();
              }
              if (mounted) setState(() {});
            },
            icon: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow)),
        Expanded(
            child: VideoProgressIndicator(_controller!,
                allowScrubbing: true, padding: const EdgeInsets.all(12)))
      ])
    ]);
  }
}
