import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as paths;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fitlek1/services/chat_media_store.dart';

class FakeMediaDb implements Database {
  final String databasePath;
  final Map<int, Map<String, Object?>> rows = {};
  final List<String> events;
  int updates = 0;
  FakeMediaDb(this.databasePath, this.events);
  @override
  dynamic noSuchMethod(Invocation call) {
    if (call.memberName == #path) return databasePath;
    if (call.memberName == #query) {
      final id = (call.namedArguments[#whereArgs] as List).first as int;
      return Future<List<Map<String, Object?>>>.value(
          rows.containsKey(id) ? [Map.of(rows[id]!)] : []);
    }
    if (call.memberName == #insert) {
      final row = Map<String, Object?>.from(call.positionalArguments[1] as Map);
      rows[row['id'] as int] = row;
      events.add('persist');
      return Future<int>.value(row['id'] as int);
    }
    if (call.memberName == #update) {
      updates++;
      final id = (call.namedArguments[#whereArgs] as List).first as int;
      rows[id]!.addAll(
          Map<String, Object?>.from(call.positionalArguments[1] as Map));
      return Future<int>.value(1);
    }
    return super.noSuchMethod(call);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory folder;
  late FakeMediaDb db;
  late ChatMediaStore store;
  late List<String> events;
  late int downloads, acks;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('sirvya-local-media-test-');
    events = [];
    downloads = 0;
    acks = 0;
    db = FakeMediaDb('${folder.path}/media.db', events);
    store = ChatMediaStore(
        userProvider: () async => 12,
        databaseProvider: (_) async => db,
        downloadProvider: (_) async {
          downloads++;
          return Uint8List.fromList([1, 2, 3, 4]);
        },
        cacheDeleteProvider: (_) async {},
        receiptProvider: (path, payload) async {
          acks++;
          expect(
              await File(paths.join(folder.path, db.rows[1]!['path'] as String))
                  .exists(),
              true);
          expect(events, ['persist']);
          expect('${payload['sha256']}'.length, 64);
          events.add('ack');
          return {'ok': true};
        });
  });
  tearDown(() async {
    await folder.delete(recursive: true);
  });
  test(
      'relative filenames are durable and resolve against the current account folder',
      () async {
    final saved =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', false);
    expect(db.rows[1]!['path'], '1.m4a');
    expect(saved.filePath, paths.join(folder.path, '1.m4a'));
  });
  test(
      'legacy iOS container paths relocate to existing files without another download',
      () async {
    final file = File(paths.join(folder.path, '1.m4a'));
    await file.writeAsBytes([5, 6, 7]);
    final thumb = File(paths.join(folder.path, '1.thumb.jpg'));
    await thumb.writeAsBytes([1]);
    db.rows[1] = {
      'id': 1,
      'path':
          '/var/mobile/Containers/Data/Application/OLD-UUID/Library/Application Support/chat_media/12/1.m4a',
      'thumbnail':
          '/var/mobile/Containers/Data/Application/OLD-UUID/Library/Application Support/chat_media/12/1.thumb.jpg',
      'deleted': 0,
      'acknowledged': 1
    };
    final saved =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', true);
    expect(saved.filePath, file.path);
    expect(saved.thumbnailPath, thumb.path);
    expect(db.rows[1]!['path'], '1.m4a');
    expect(db.rows[1]!['thumbnail'], '1.thumb.jpg');
    await store.resolve(1, 'https://server/audio.m4a', 'audio', true);
    expect(db.updates, 1); // Only migrate once, never write on each scroll.
    expect(downloads, 0);
  });
  test('fresh install cannot restore server-expired media', () async {
    final saved =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', true);
    expect(saved.filePath, isNull);
    expect(downloads, 0);
    expect(acks, 0);
  });
  test(
      'complete file and durable metadata precede acknowledgement; server expiry preserves local copy',
      () async {
    final first =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', false);
    expect(await File(first.filePath!).readAsBytes(), [1, 2, 3, 4]);
    expect(acks, 1);
    final expired =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', true);
    expect(expired.filePath, first.filePath);
    expect(downloads, 1);
    expect(acks, 1);
  });
  test('explicit local deletion keeps a tombstone and never redownloads',
      () async {
    await store.resolve(1, 'https://server/audio.m4a', 'audio', false);
    await store.deleteLocal(1);
    expect(
        (await store.resolve(1, 'https://server/audio.m4a', 'audio', false))
            .filePath,
        isNull);
    expect(db.rows[1]!['deleted'], 1);
    expect(downloads, 1);
  });
  test('externally missing local file is not restored from server', () async {
    final saved =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', false);
    await File(saved.filePath!).delete();
    expect(
        (await store.resolve(1, 'https://server/audio.m4a', 'audio', false))
            .filePath,
        isNull);
    expect(downloads, 1);
  });
  test('failed disk persistence sends no acknowledgement', () async {
    final bad = ChatMediaStore(
        userProvider: () async => 12,
        databaseProvider: (_) async =>
            FakeMediaDb('${folder.path}/missing/dir/media.db', events),
        downloadProvider: (_) async => Uint8List.fromList([1]),
        receiptProvider: (_, __) async {
          acks++;
          return {'ok': true};
        });
    await expectLater(
        bad.resolve(1, 'https://server/audio.m4a', 'audio', false),
        throwsA(isA<FileSystemException>()));
    expect(acks, 0);
  });
  test(
      'deletion before download records a tombstone and blocks later downloads',
      () async {
    await store.deleteLocal(1, removeThumbnail: true);
    final media =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', false);
    expect(media.filePath, isNull);
    expect(downloads, 0);
    expect(acks, 0);
  });
  test('message deletion removes complete media and its retained thumbnail',
      () async {
    final media =
        await store.resolve(1, 'https://server/audio.m4a', 'audio', false);
    final preview = File('${folder.path}/test.thumb.jpg');
    await preview.writeAsBytes([1]);
    db.rows[1]!['thumbnail'] = preview.path;
    await store.deleteLocal(1, removeThumbnail: true);
    expect(await File(media.filePath!).exists(), false);
    expect(await preview.exists(), false);
    expect(db.rows[1]!['thumbnail'], isNull);
    expect(db.rows[1]!['deleted'], 1);
  });
}
