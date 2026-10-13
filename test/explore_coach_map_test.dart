import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fitlek1/components/ENG/exploreCoachMap.dart';
import 'package:fitlek1/models/anas/coach.dart';
import 'package:fitlek1/theme/app_theme.dart';

class BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      const AssetImage('assets/branding/icon_app.png');
}

void main() {
  for (final height in [240.0, 550.0]) {
    testWidgets(
        'map groups overlapping coaches and opens selected profile at ${height}px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(320, height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      int? opened;
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');
        return http.Response(
            jsonEncode(request.url.path.endsWith('/map')
                ? [
                    {'id': 1, 'mapLatitude': 33.57, 'mapLongitude': -7.59},
                    {'id': 2, 'mapLatitude': 33.57, 'mapLongitude': -7.59},
                    {'id': 3, 'mapLatitude': 34.0, 'mapLongitude': -6.0},
                  ]
                : {'latitude': 33.57, 'longitude': -7.59}),
            200);
      });
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
              body: ExploreCoachMap(
            coaches: [
              for (final id in [1, 2])
                CoachModel.fromJson({
                  'id': id,
                  'firstName': 'Coach $id',
                  'lastName': 'Test',
                  'ville': 'Casablanca',
                  'distanceKm': 1.2
                })
            ],
            token: 'test-token',
            httpClient: client,
            tileProvider: BlankTiles(),
            onOpen: (coach) => opened = coach.id,
            onRefresh: () async {},
          ))));
      await tester.pumpAndSettle();
      for (final label in ['Near me', 'Show all coaches', 'Refresh map']) {
        expect(find.byTooltip(label), findsOneWidget);
      }
      expect(find.byType(RichAttributionWidget), findsNothing);
      final mapController = tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
      final initialZoom = mapController.camera.zoom;
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(mapController.camera.zoom, initialZoom + 1);
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(mapController.camera.zoom, initialZoom);
      final markers =
          tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
      expect(markers.length,
          2); // Client + one group; filtered-out coach 3 is absent.
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(find.text('Coaches in this area'), findsOneWidget);
      await tester.tap(find.text('Coach 2 Test'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View & Book'));
      expect(opened, 2);
      expect(tester.takeException(), isNull);
      if (height > 300) {
        tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!
            .move(const LatLng(33.57, -7.59), 15);
        await tester.pumpAndSettle();
        expect(tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.length, 3);
        expect(find.byType(CircleAvatar), findsAtLeastNWidgets(2));
        await tester.tap(find.byType(CircleAvatar).first);
        await tester.pumpAndSettle();
        expect(find.text('Coach 1 Test'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
