import 'package:flutter_mapbox_animarker/flutter_mapbox_animarker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MockMapboxMap extends Mock implements MapboxMap {}

class MockStyle extends Mock implements StyleManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MarkerAnimator vehicleAnimator;
  late MockMapboxMap mapboxMap;
  late String url;
  late String markerId;

  setUp(() {
    mapboxMap = MockMapboxMap();
    vehicleAnimator = MarkerAnimator(mapboxMap);
    url = "assets/images/car.png";
    markerId = 'driver1';
  });

  group('VehicleAnimator', () {
    test('should add driver points', () async {
      List<Map<String, dynamic>> preCalculatedData = [
        {
          'position': [30.0, 50.0],
          'rotation': 0
        },
      ];

      await vehicleAnimator.addMarkerPoint(markerId, url, preCalculatedData);
      expect(vehicleAnimator.markerPoints.containsKey(markerId), true);
      expect(vehicleAnimator.markerPoints[markerId]!.length, 1);
    });

    test('should remove vehicle and corresponding data', () async {
      List<Map<String, dynamic>> preCalculatedData = [
        {
          'position': [30.0, 50.0],
          'rotation': 0
        },
      ];

      await vehicleAnimator.addMarkerPoint(
          "${markerId}2", url, preCalculatedData);
      await vehicleAnimator.removeMarker("${markerId}2");
      expect(vehicleAnimator.markerPoints.containsKey("${markerId}2"), false);
    });

    test('should initialize driver stream on addDriverPoint', () async {
      List<Map<String, dynamic>> preCalculatedData = [
        {
          'position': [30.0, 50.0],
          'rotation': 0
        },
      ];

      await vehicleAnimator.addMarkerPoint(
          "${markerId}3", url, preCalculatedData);
      expect(vehicleAnimator.markerPoints["${markerId}3"]!.isNotEmpty, true);
    });

    test('should update vehicle location and rotation correctly', () async {
      List<Map<String, dynamic>> preCalculatedData = [
        {
          'position': [30.0, 50.0],
          'rotation': 45
        },
      ];
      await vehicleAnimator.addMarkerPoint(
          "${markerId}4", url, preCalculatedData);
      expect(vehicleAnimator.markerPoints["${markerId}4"]!.isNotEmpty, true);
      expect(
          vehicleAnimator
              .markerPoints["${markerId}4"]![0]['point'].coordinates[0],
          30.0);
      expect(
          vehicleAnimator
              .markerPoints["${markerId}4"]![0]['point'].coordinates[1],
          50.0);
      expect(vehicleAnimator.markerPoints["${markerId}4"]![0]['rotation'], 45);
    });
  });
}
