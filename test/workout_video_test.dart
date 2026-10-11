import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'support/fake_workout_video.dart';
import 'dart:io';
import 'package:fitlek1/screens/ENG/workout/workout_gif.dart';
import 'package:fitlek1/screens/ENG/workout/workout_demonstration.dart';
import 'package:fitlek1/models/workout.dart';
import 'package:fitlek1/models/workout_video.dart';
import 'package:fitlek1/screens/ENG/workout/workout_video.dart';
import 'package:fitlek1/screens/ENG/workout/exercise_library.dart';
import 'package:fitlek1/services/workout_service.dart';

void main() {
  final original = VideoPlayerPlatform.instance;
  late FakeVideoPlatform player;
  final bench = Exercise.fromJson({
    'id': 1,
    'name': 'Bench Press',
    'muscleGroup': 'chest',
    'equipment': 'barbell',
    'exerciseType': 'reps',
    'externalSource': 'exercises-dataset',
    'externalId': '0025'
  });
  setUp(() {
    player = FakeVideoPlatform();
    VideoPlayerPlatform.instance = player;
    WorkoutService.preferences = {};
    SharedPreferences.setMockInitialValues({'token': 'video-test-fixture'});
  });
  tearDown(() {
    VideoPlayerPlatform.instance = original;
    WorkoutService.preferences = {};
  });
  Exercise supplied({String? video, String? image}) => Exercise.fromJson({
        'id': 9000,
        'name': 'Custom demo',
        'muscleGroup': 'chest',
        'equipment': 'barbell',
        'videoUrl': video,
        'imageUrl': image,
      });
  final hosted = Exercise.fromJson({
    'id': 8001,
    'name': 'Band demo',
    'muscleGroup': 'biceps',
    'equipment': 'band',
    'externalSource': 'exercises-dataset',
    'externalId': '0968',
    'hasHostedMedia': true,
  });
  Map<String, dynamic> hostedVideo(String url) => {
        'name': hosted.name,
        'asset': url,
        'poster': url,
        'author': 'AscendAPI',
        'license': 'Noncommercial preview',
        'licenseUrl': 'https://docs.ascendapi.com',
        'sourceUrl': 'https://ascendapi.com',
        'modifications': '',
      };
  test('hosted media URLs are resolved fresh and bypass durable offline caches',
      () async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42});
    var calls = 0;
    var failing = false;
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('/exercises/8001/demonstration'));
      calls++;
      if (failing) {
        return http.Response(
            jsonEncode({'message': 'exercise_media_unavailable'}), 503);
      }
      return http.Response(
          jsonEncode({
            'video': hostedVideo(
                'https://static.exercisedb.dev/media/demo.gif?revision=$calls')
          }),
          200);
    });
    await http.runWithClient(() async {
      final first = await WorkoutVideoCatalog.forExercise(hosted);
      final second = await WorkoutVideoCatalog.forExercise(hosted);
      expect(first?.asset, isNot(second?.asset));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((key) => key.contains('/demonstration')),
          isEmpty);
      failing = true;
      await expectLater(WorkoutVideoCatalog.forExercise(hosted),
          throwsA(isA<WorkoutApiException>()));
      expect(calls, 3);
    }, () => client);
  });
  testWidgets(
      'hosted demonstration survives parent rebuild and retries a failed lookup',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42});
    var calls = 0;
    final bytes = File('test/fixtures/exercise-demo.gif').readAsBytesSync();
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/demonstration')) {
        calls++;
        if (calls == 1) {
          return http.Response(
              jsonEncode({'message': 'exercise_media_unavailable'}), 503);
        }
        return http.Response(
            jsonEncode({
              'video':
                  hostedVideo('https://static.exercisedb.dev/media/demo.gif')
            }),
            200);
      }
      return http.Response.bytes(bytes, 200);
    });
    await http.runWithClient(() async {
      Widget page() => MaterialApp(
          home: Scaffold(body: WorkoutDemonstrationPanel(exercise: hosted)));
      await tester.pumpWidget(page());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('Reload demonstration'), findsOneWidget);
      await tester.tap(find.text('Reload demonstration'));
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(find.byType(WorkoutVideoPanel), findsOneWidget);
      await tester.pumpWidget(page());
      await tester.pump();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }, () => client);
  });
  test('supplied GIF/video media is resolved without a catalog identity',
      () async {
    final gif = await WorkoutVideoCatalog.forExercise(
        supplied(video: 'https://media.example/demo.GIF?version=1'));
    expect(gif?.isGif, isTrue);
    expect(gif?.isNetwork, isTrue);
    expect(gif?.poster, gif?.asset);
    expect(
        await WorkoutVideoCatalog.forExercise(
            supplied(video: 'javascript:alert(1)')),
        isNull);
    expect(
        await WorkoutVideoCatalog.forExercise(
            supplied(video: 'https://youtube.com/watch?v=demo')),
        isNull);
    expect(workoutMediaLocation('/uploads/demo.gif'), startsWith('http'));
    expect(workoutMediaLocation('//unknown.example/demo.gif'), isNull);
    expect(
        Exercise.fromJson({'gif_url': 'https://media.example/demo.gif'})
            .videoUrl,
        endsWith('.gif'));
  });
  testWidgets('supplied MP4 plays inline with the network player',
      (tester) async {
    final video = (await WorkoutVideoCatalog.forExercise(
        supplied(video: 'https://media.example/demo.mp4')))!;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WorkoutVideoPanel(video: video))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.events, contains('uri:https://media.example/demo.mp4'));
    expect(player.events, contains('play:1'));
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });
  testWidgets('a supplied image is used as the library thumbnail',
      (tester) async {
    const image = 'assets/workout/demonstrations/wger-68.png';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkoutExerciseThumbnail(exercise: supplied(image: image)))));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutMediaImage), findsOneWidget);
    expect(
        tester
            .widget<WorkoutMediaImage>(find.byType(WorkoutMediaImage))
            .location,
        image);
    expect(find.byIcon(Icons.fitness_center), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('media labels do not make hosted lookup requests',
      (tester) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{}', 500);
    });
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: WorkoutMediaKindLabel(exercise: hosted))));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('GIF'), findsOneWidget);
      expect(requests, 0);
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });
  testWidgets('offscreen thumbnails wait until visible and scrolling settles',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'token': 'fixture-token', 'userId': 42});
    final controller = ScrollController();
    final requests = <int>[];
    final client = MockClient((request) async {
      expect(request.url.queryParameters['priority'], 'preview');
      requests
          .add(int.parse(request.url.path.split('/').reversed.elementAt(1)));
      return http.Response(jsonEncode({'video': null}), 200);
    });
    await http.runWithClient(() async {
      final list = ListView.builder(
          controller: controller,
          scrollCacheExtent: const ScrollCacheExtent.pixels(1000),
          itemExtent: 100,
          itemCount: 5,
          itemBuilder: (_, index) => Center(
                  child: WorkoutExerciseThumbnail(
                      exercise: Exercise.fromJson({
                'id': 8001 + index,
                'name': 'Hosted fixture $index',
                'externalSource': 'exercises-dataset',
                'externalId': '0968',
                'hasHostedMedia': true,
              }))));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(height: 100, child: list)))));
      expect(requests, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(requests, [8001]);
      controller.jumpTo(300);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(requests, [8001, 8004]);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(tester.takeException(), isNull);
    }, () => client);
  });
  testWidgets('GIF preview pauses and respects reduced motion', (tester) async {
    final bytes = File('test/fixtures/exercise-demo.gif').readAsBytesSync();
    final client = MockClient((_) async => http.Response.bytes(bytes, 200));
    await http.runWithClient(() async {
      Widget preview({bool playing = false, bool reduced = false}) =>
          MaterialApp(
              home: MediaQuery(
                  data: MediaQueryData(disableAnimations: reduced),
                  child: SizedBox(
                      width: 100,
                      height: 100,
                      child: WorkoutAnimatedImage(
                          location: 'https://media.example/demo.gif',
                          playing: playing))));
      await tester.pumpWidget(preview());
      for (var i = 0; i < 40 && find.byType(RawImage).evaluate().isEmpty; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      final first = tester.widget<RawImage>(find.byType(RawImage)).image;
      expect(first, isNotNull);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(first));
      await tester.pumpWidget(preview(playing: true));
      await tester.pump(const Duration(milliseconds: 250));
      for (var i = 0;
          i < 40 &&
              identical(
                  tester.widget<RawImage>(find.byType(RawImage)).image, first);
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      expect(tester.widget<RawImage>(find.byType(RawImage)).image,
          isNot(same(first)));
      await tester.pumpWidget(preview(playing: true, reduced: true));
      final paused = tester.widget<RawImage>(find.byType(RawImage)).image;
      await tester.pump(const Duration(seconds: 1));
      expect(
          tester.widget<RawImage>(find.byType(RawImage)).image, same(paused));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }, () => client);
  });
  test(
      'video lookup uses source identity rather than matching an exercise name',
      () async {
    expect((await WorkoutVideoCatalog.forExercise(bench))?.asset,
        endsWith('.mp4'));
    final custom = Exercise.fromJson({
      'id': 2,
      'name': 'Bench Press',
      'muscleGroup': 'chest',
      'equipment': 'barbell',
      'exerciseType': 'reps',
      'externalSource': 'sirvya-custom',
      'externalId': '0025'
    });
    expect(await WorkoutVideoCatalog.forExercise(custom), isNull);
  });
  testWidgets(
      'real video control mutes, loops, pauses on background and releases its player',
      (tester) async {
    final video =
        (await tester.runAsync(() => WorkoutVideoCatalog.forExercise(bench)))!;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WorkoutVideoPanel(video: video))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.events, contains('volume:0.0'));
    expect(player.events, contains('loop:true'));
    expect(player.events, contains('play:1'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(player.events.last, 'pause:1');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(player.events.last, 'play:1');
    await tester.tap(find.byTooltip('Pause demonstration'));
    await tester.pump();
    expect(player.events.last, 'pause:1');
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 6));
    expect(find.byType(WorkoutVideoPanel), findsNothing);
    expect(player.events, contains('dispose:1'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed player creation offers retry without blocking the poster',
      (tester) async {
    final video =
        (await tester.runAsync(() => WorkoutVideoCatalog.forExercise(bench)))!;
    player.failNextCreation = true;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: WorkoutVideoPanel(video: video))));
    await tester.pump();
    expect(find.text('Reload video'), findsOneWidget);
    await tester.tap(find.text('Reload video'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(player.events, contains('play:1'));
    expect(find.text('Reload video'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(seconds: 6));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'video filter changes the authenticated query and keeps search working',
      (tester) async {
    final queries = <Map<String, String>>[];
    final client = MockClient((request) async {
      queries.add(request.url.queryParameters);
      return http.Response(
          jsonEncode({
            'data': [],
            'total': 0,
            'hasMore': false,
            'filters': {'bodyPart': [], 'equipment': []}
          }),
          200);
    });
    await http.runWithClient(() async {
      await tester
          .pumpWidget(const MaterialApp(home: WorkoutExerciseLibrary()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Video demos'));
      await tester.pumpAndSettle();
      expect(queries.last['video'], 'true');
      await tester.enterText(find.byType(TextField), 'bench');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(queries.last['search'], 'bench');
      expect(queries.last['video'], 'true');
      await tester.tap(find.text('Video demos'));
      await tester.pumpAndSettle();
      expect(queries.last.containsKey('video'), false);
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });
}
