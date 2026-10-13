import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as imaging;
import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'apiService.dart';

class SavedChatMedia {
  final String? filePath, thumbnailPath;
  final bool remote;
  const SavedChatMedia(
      {this.filePath, this.thumbnailPath, this.remote = false});
}

Uint8List? _thumbnail(Uint8List bytes) {
  try {
    final image = imaging.decodeImage(bytes);
    if (image == null) return null;
    return Uint8List.fromList(
        imaging.encodeJpg(imaging.copyResize(image, width: 40), quality: 35));
  } catch (_) {
    return null;
  }
}

class ChatMediaStore {
  static final instance = ChatMediaStore();
  final Future<int?> Function()? userProvider;
  final Future<Database> Function(int)? databaseProvider;
  final Future<Uint8List> Function(String)? downloadProvider;
  final Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
      receiptProvider;
  final Future<void> Function(String)? cacheDeleteProvider;
  ChatMediaStore(
      {this.userProvider,
      this.databaseProvider,
      this.downloadProvider,
      this.receiptProvider,
      this.cacheDeleteProvider});
  final changes = ValueNotifier<int>(0);
  final Map<String, Future<SavedChatMedia>> _pending = {};
  final Map<int, Future<Database>> _databases = {};
  bool _syncing = false;
  bool _syncAgain = false;
  Future<Database> _database(int userID) =>
      databaseProvider?.call(userID) ??
      _databases.putIfAbsent(userID, () async {
        final support = await getApplicationSupportDirectory();
        final folder =
            Directory(paths.join(support.path, 'chat_media', '$userID'));
        await folder.create(recursive: true);
        return openDatabase(paths.join(folder.path, 'media.db'), version: 1,
            onCreate: (db, _) async {
          await db.execute(
              'CREATE TABLE media (id INTEGER PRIMARY KEY, path TEXT, thumbnail TEXT, url TEXT, checksum TEXT, deleted INTEGER NOT NULL DEFAULT 0, acknowledged INTEGER NOT NULL DEFAULT 0)');
        });
      });
  Future<int?> _userID() async => userProvider != null
      ? await userProvider!()
      : int.tryParse('${(await ApiService.getUserData())?['id']}');
  Future<SavedChatMedia> resolve(
      int id, String? url, String type, bool expired) async {
    if (kIsWeb)
      return SavedChatMedia(filePath: expired ? null : url, remote: true);
    final userID = await _userID();
    if (userID == null || id <= 0) return const SavedChatMedia();
    final key = '$userID:$id';
    final existing = _pending[key];
    if (existing != null) return existing;
    final future = _resolve(userID, id, url, type, expired);
    _pending[key] = future;
    try {
      return await future;
    } finally {
      _pending.remove(key);
    }
  }

  Future<SavedChatMedia> _resolve(
      int userID, int id, String? url, String type, bool expired) async {
    final db = await _database(userID);
    final rows = await db.query('media', where: 'id=?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final row = rows.first;
      final file = row['path'] as String?;
      if (row['deleted'] == 1 || file == null || !await File(file).exists()) {
        await db.update('media', {'deleted': 1},
            where: 'id=?', whereArgs: [id]);
        return SavedChatMedia(thumbnailPath: row['thumbnail'] as String?);
      }
      if (row['acknowledged'] != 1)
        await _ack(db, userID, id, row['checksum'] as String);
      return SavedChatMedia(
          filePath: file, thumbnailPath: row['thumbnail'] as String?);
    }
    if (url == null || !['image', 'audio'].contains(type))
      return const SavedChatMedia();
    Uint8List bytes;
    final cached = downloadProvider == null
        ? await DefaultCacheManager().getFileFromCache(url)
        : null;
    if (downloadProvider != null && !expired) {
      bytes = await downloadProvider!(url);
    } else if (cached != null && await cached.file.exists()) {
      bytes = await cached.file.readAsBytes();
    } else {
      if (expired) return const SavedChatMedia();
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode != 200 ||
          response.bodyBytes.isEmpty ||
          response.bodyBytes.length > 25 * 1024 * 1024 ||
          !(contentType.startsWith('image/') ||
              contentType.startsWith('audio/') ||
              contentType.startsWith('application/octet-stream'))) {
        throw StateError('Could not download chat media');
      }
      bytes = response.bodyBytes;
    }
    if (bytes.isEmpty || bytes.length > 25 * 1024 * 1024)
      throw StateError('Invalid downloaded media');
    if (await _userID() != userID) throw StateError('Account changed');
    final folder = paths.dirname(db.path);
    final file =
        File(paths.join(folder, '$id.${type == 'image' ? 'jpg' : 'm4a'}'));
    final temp = File('${file.path}.part');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(file.path);
    String? thumb;
    if (type == 'image') {
      final previewBytes = await compute(_thumbnail, bytes);
      if (previewBytes != null) {
        final thumbnail = File(paths.join(folder, '$id.thumb.jpg'));
        await thumbnail.writeAsBytes(previewBytes, flush: true);
        thumb = thumbnail.path;
      }
    }
    final checksum = sha256.convert(bytes).toString();
    await db.insert(
        'media',
        {
          'id': id,
          'path': file.path,
          'thumbnail': thumb,
          'url': url,
          'checksum': checksum
        },
        conflictAlgorithm: ConflictAlgorithm.abort);
    await _ack(db, userID, id, checksum);
    changes.value++;
    return SavedChatMedia(filePath: file.path, thumbnailPath: thumb);
  }

  Future<void> _ack(Database db, int userID, int id, String checksum) async {
    if (await _userID() != userID) return;
    final result = await (receiptProvider ?? ApiService.post)(
        '/chat-media/$id/saved', {'sha256': checksum});
    if (result['ok'] == true)
      await db.update('media', {'acknowledged': 1},
          where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteLocal(int id, {bool removeThumbnail = false}) async {
    if (kIsWeb) return;
    final userID = await _userID();
    if (userID == null) return;
    final downloading = _pending['$userID:$id'];
    if (downloading != null) {
      try {
        await downloading;
      } catch (_) {}
    }
    if (await _userID() != userID) return;
    final db = await _database(userID);
    final rows = await db.query('media', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) {
      await db.insert('media', {'id': id, 'deleted': 1});
      changes.value++;
      return;
    }
    final changed = rows.first['deleted'] != 1 ||
        (removeThumbnail && rows.first['thumbnail'] != null);
    await db.update(
        'media', {'deleted': 1, if (removeThumbnail) 'thumbnail': null},
        where: 'id=?', whereArgs: [id]);
    final filePath = rows.first['path'] as String?;
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    }
    final thumbnailPath = rows.first['thumbnail'] as String?;
    if (removeThumbnail && thumbnailPath != null) {
      final thumbnail = File(thumbnailPath);
      if (await thumbnail.exists()) await thumbnail.delete();
    }
    final url = rows.first['url'] as String?;
    if (url != null)
      await (cacheDeleteProvider ?? DefaultCacheManager().removeFile)(url);
    if (changed) changes.value++;
  }

  // Sync all undelivered media on connect/resume, even when no chat is open.
  // The OS does not guarantee downloads while the app is closed.
  Future<void> syncPending() async {
    if (kIsWeb) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      final userID = await _userID();
      if (userID == null) return;
      int removedAfter = 0;
      while (await _userID() == userID) {
        final removed =
            await ApiService.get('/chat-media/removed?after=$removedAfter');
        if (removed['ok'] != true || removed['data'] is! List) break;
        final rows = removed['data'] as List;
        if (rows.isEmpty) break;
        for (final row in rows) {
          final id = int.tryParse('${row['id']}');
          if (id == null) continue;
          removedAfter = id;
          await deleteLocal(id, removeThumbnail: true);
        }
        if (rows.length < 100) break;
      }
      int after = 0;
      while (await _userID() == userID) {
        final result = await ApiService.get('/chat-media/pending?after=$after');
        if (result['ok'] != true || result['data'] is! List) break;
        final rows = result['data'] as List;
        if (rows.isEmpty) break;
        for (final row in rows) {
          final id = int.tryParse('${row['id']}');
          if (id == null) continue;
          after = id;
          try {
            await resolve(
                id, row['mediaUrl'] as String?, '${row['mediaType']}', false);
          } catch (_) {}
        }
        if (rows.length < 50) break;
      }
    } catch (_) {
      // Retry pending downloads or removals on the next connection/sync.
    } finally {
      _syncing = false;
      if (_syncAgain) {
        _syncAgain = false;
        unawaited(syncPending());
      }
    }
  }
}
