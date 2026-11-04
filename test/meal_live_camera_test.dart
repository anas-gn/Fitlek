import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitlek1/components/meal_live_camera.dart';

class FakeMealCamera extends CameraPlatform {
  int created = 0, disposed = 0, captured = 0;
  bool denied = false;
  bool? audio;
  CameraDescription? selected;

  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (denied) throw CameraException('CameraAccessDenied', 'Denied');
    return const [
      CameraDescription(
          name: 'front',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 90),
      CameraDescription(
          name: 'rear',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90),
    ];
  }

  @override
  Future<int> createCamera(
      CameraDescription cameraDescription, ResolutionPreset? resolutionPreset,
      {bool enableAudio = false}) async {
    selected = cameraDescription;
    audio = enableAudio;
    return ++created;
  }

  @override
  Future<void> initializeCamera(int cameraId,
      {ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown}) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(CameraInitializedEvent(cameraId, 1280, 720,
          ExposureMode.auto, false, FocusMode.auto, false));

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => Stream.multi((_) {});

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();

  @override
  Widget buildPreview(int cameraId) => const ColoredBox(
      key: ValueKey('live-camera-preview'), color: Colors.green);

  @override
  Future<XFile> takePicture(int cameraId) async {
    captured++;
    return XFile('captured-meal.jpg');
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposed++;
  }
}

void main() {
  late CameraPlatform original;
  late FakeMealCamera camera;
  setUp(() {
    original = CameraPlatform.instance;
    camera = FakeMealCamera();
    CameraPlatform.instance = camera;
  });
  tearDown(() => CameraPlatform.instance = original);

  testWidgets('shows live rear camera, captures, and releases it off screen',
      (tester) async {
    final key = GlobalKey<MealLiveCameraState>();
    XFile? photo;
    final capturing = <bool>[];
    Widget scanner(bool visible) => MaterialApp(
        home: Scaffold(
            body: TickerMode(
                enabled: visible,
                child: SizedBox(
                    width: 280,
                    height: 260,
                    child: MealLiveCamera(
                        key: key,
                        onCaptured: (value) => photo = value,
                        onCapturing: capturing.add)))));
    await tester.pumpWidget(scanner(true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('live-camera-preview')), findsOneWidget);
    expect(camera.selected!.lensDirection, CameraLensDirection.back);
    expect(camera.audio, isFalse);
    await key.currentState!.capture();
    expect(photo!.path, 'captured-meal.jpg');
    expect(capturing, [true, false]);
    expect(camera.captured, 1);

    await tester.pumpWidget(scanner(false));
    await tester.pumpAndSettle();
    expect(camera.disposed, 1);
    await tester.pumpWidget(scanner(true));
    await tester.pumpAndSettle();
    expect(camera.created, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(camera.disposed, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('camera permission failure offers an inline retry',
      (tester) async {
    camera.denied = true;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 280,
                height: 260,
                child:
                    MealLiveCamera(onCaptured: (_) {}, onCapturing: (_) {})))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Allow camera access'), findsOneWidget);
    camera.denied = false;
    await tester.tap(find.text('Retry camera'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('live-camera-preview')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
