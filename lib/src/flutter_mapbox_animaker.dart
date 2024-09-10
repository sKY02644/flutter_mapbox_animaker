import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'utils/common.dart';
import 'dart:developer';

/// Class to animate markers on a Mapbox map.
class MarkerAnimator extends TickerProvider {
  // A map that stores marker marker points based on their ID.
  final Map<String, List<Map<String, dynamic>>> markerPoints = {};

  // Stores the marker layer IDs based on marker ID.
  final Map<String, String> markerLayerIds = {};

  // The Mapbox map instance where the markers will be added.
  final MapboxMap mapboxMap;

  // Controllers for marker location streams.
  final Map<String, StreamController<String>> _locationStreamControllers = {};

  // ID of the last layer added.
  String? _lastLayerId;

  late Ticker _ticker;

  /// A map storing animation controllers for markers.
  final Map<String, AnimationController> _controller = {};

  /// A map storing position animations for markers.
  final Map<String, Animation<Offset>> _positionAnimation = {};

  /// A map storing rotation animations for markers.
  final Map<String, Animation<double>> _rotationAnimation = {};

  @override
  Ticker createTicker(TickerCallback onTick) {
    _ticker = Ticker(onTick);
    return _ticker;
  }

  /// Constructor to initialize the MarkerAnimator with the MapboxMap instance.
  MarkerAnimator(this.mapboxMap);

  /// Adds a marker marker to the map and animates it between points.
  ///
  /// - [markerId]: A unique identifier for the marker.
  /// - [markerImage]: The path to the image file to be used as the marker icon.
  /// - [data]: A list of position and rotation data for the marker animation {position: [double, double], rotation: double}[].
  /// - [properties]: (Optional) Custom properties for marker style.
  /// - [scale]: (optional) A scale factor for the image.
  /// - [animationDuration]: (optional) How long the animation should last.
  /// - [positionCurve]: (optional) Custom curve for position animations.
  /// - [rotationCurve]: (optional) Custom curve for rotation animations.
  Future<void> addMarkerPoint(
    String markerId,
    String markerImage,
    List<Map<String, dynamic>> data, {
    int animationDuration = 50,
    double scale = 15,
    Map<String, dynamic> properties = const {
      "icon-opacity": 1.0,
      "icon-size": 1.0,
      "icon-anchor": "center",
      "icon-offset": [0.5, 0.5],
      'icon-allow-overlap': true,
      'icon-ignore-placement': true,
    },
    Curve positionCurve = Curves.linear,
    Curve rotationCurve = Curves.linear,
  }) async {
    try {
      // Store marker points (positions and rotations).
      markerPoints.putIfAbsent(markerId, () => []);
      for (var data in data) {
        Point newPoint = Point(coordinates: Position(data['position'][0], data['position'][1]));
        num rotation = data['rotation'];
        markerPoints[markerId]?.add({'point': newPoint, 'rotation': rotation});
      }

      // Initialize the marker stream if it doesn't exist.
      if (!_locationStreamControllers.containsKey(markerId) && markerPoints[markerId]!.length > 2) {
        await _initializeMarkerStreams(
          markerId: markerId,
          markerImage: markerImage,
          properties: properties,
          scale: scale,
          animationDuration: animationDuration,
          positionCurve: positionCurve,
          rotationCurve: rotationCurve,
        );
      }

      // Trigger the stream to start the animation.
      _locationStreamControllers[markerId]?.add("animate");
    } on Exception catch (_) {
      rethrow;
    }
  }

  /// Removes a marker marker from the map.
  Future<void> removeMarker(String markerId) async {
    // Remove marker points and close the location stream.
    try {
      markerPoints.remove(markerId);
      _locationStreamControllers[markerId]?.close();
      _locationStreamControllers.remove(markerId);

      // Remove the marker layer and source from the map.
      if (markerLayerIds[markerId] != null) {
        String layerId = 'layer-$markerId';
        String sourceId = 'source-$markerId';
        mapboxMap.style.removeStyleLayer(layerId);
        mapboxMap.style.removeStyleSource(sourceId);
        markerLayerIds.remove(markerId);

        // Update the last layer ID if necessary.
        if (_lastLayerId == layerId) {
          _lastLayerId = markerLayerIds.values.isNotEmpty ? markerLayerIds.values.last : null;
        }
      }
    } on Exception catch (_) {
      rethrow;
    }
  }

  /// Initializes the stream for animating the marker markers.
  Future<void> _initializeMarkerStreams({
    required String markerId,
    required String markerImage,
    required double scale,
    required int animationDuration,
    required Map<String, dynamic> properties,
    required Curve positionCurve,
    required Curve rotationCurve,
  }) async {
    try {
      List<Map<String, dynamic>> points = markerPoints[markerId]!;

      String iconId = 'icon-$markerId';
      String layerId = 'layer-$markerId';
      String sourceId = 'source-$markerId';

      if (!markerLayerIds.containsKey(markerId)) {
        Uint8List? imgU8List = await loadImageAsUint8List(markerImage);
        Point point = points.first['point'];
        num rotation = points.first['rotation'];
        var source = {
          "type": "geojson",
          "data": {
            "type": "Feature",
            "geometry": {
              "type": "Point",
              "coordinates": [point.coordinates[0], point.coordinates[1]]
            }
          }
        };
        var imageSize = await getImageSizeFromBytes(imgU8List!);
        var width = imageSize['width']?.toInt();
        var height = imageSize['height']?.toInt();

        log("WIDTH: $width HEIGHT: $height");

        await mapboxMap.style.addStyleImage(iconId, scale, MbxImage(width: width!, height: height!, data: imgU8List), false, [], [], null);
        await mapboxMap.style.addStyleSource(sourceId, json.encode(source));
        LayerPosition layerPosition = LayerPosition(below: _lastLayerId);
        await mapboxMap.style.addStyleLayer(json.encode({"id": layerId, "type": "symbol", "source": sourceId}), layerPosition);
        await mapboxMap.style.setStyleLayerProperties(
          layerId,
          json.encode(
            {
              "icon-image": iconId,
              "icon-opacity": 1.0,
              "icon-rotate": rotation.toDouble(),
              "icon-size": 1.0,
              "icon-anchor": "center",
              "icon-offset": [0.5, 0.5],
              'icon-allow-overlap': true,
              'icon-ignore-placement': true,
            },
          ),
        );
        _lastLayerId = layerId;
        markerLayerIds[markerId] = layerId;
      }

      // Listen for animation events and animate the marker when new points are available.
      final controller = StreamController<String>();
      _locationStreamControllers[markerId] = controller;
      _locationStreamControllers[markerId]?.stream.asyncMap((_) async {
        if (markerPoints[markerId]!.length > 1) {
          await _animateMarkerWithAnimation(markerId, animationDuration, positionCurve, rotationCurve);
        }
      }).listen((_) {});
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> _animateMarkerWithAnimation(
    String markerId,
    int animationDuration,
    Curve positionCurve,
    Curve rotationCurve,
  ) async {
    try {
      List<Map<String, dynamic>> points = markerPoints[markerId]!;

      String iconId = 'icon-$markerId';
      String layerId = 'layer-$markerId';
      String sourceId = 'source-$markerId';

      // Inside your animation loop, adjust the rotation tween
      for (int i = 0; i < points.length - 1; i++) {
        Point startPoint = points[i]['point'];
        Point endPoint = points[i + 1]['point'];
        Duration duration = Duration(milliseconds: animationDuration);
        // Create AnimationController and Tween for position and rotation
        _controller[markerId] = AnimationController(duration: duration, vsync: this);
        double startRotation = points[i]['rotation'].toDouble();
        double endRotation = points[i + 1]['rotation'].toDouble();

        // Normalize the end rotation to avoid jumps
        endRotation = normalizeRotation(startRotation, endRotation);

        _positionAnimation[markerId] = Tween<Offset>(
          begin: Offset(startPoint.coordinates[0]!.toDouble(), startPoint.coordinates[1]!.toDouble()),
          end: Offset(endPoint.coordinates[0]!.toDouble(), endPoint.coordinates[1]!.toDouble()),
        ).animate(
          _controller[markerId]!.drive(CurveTween(curve: positionCurve)),
        );

        _rotationAnimation[markerId] = Tween<double>(
          begin: startRotation,
          end: endRotation,
        ).animate(
          _controller[markerId]!.drive(CurveTween(curve: rotationCurve)),
        );

        // Add a listener to the animation to update the marker position and rotation
        _controller[markerId]!.addListener(() async {
          var source = {
            "type": "geojson",
            "data": {
              "type": "Feature",
              "geometry": {
                "type": "Point",
                "coordinates": [_positionAnimation[markerId]?.value.dx, _positionAnimation[markerId]?.value.dy]
              }
            }
          };

          var iconProperties = {"icon-image": iconId, "icon-rotate": _rotationAnimation[markerId]?.value};

          // Update the marker's position and rotation on the map
          await mapboxMap.style.setStyleSourceProperties(sourceId, json.encode(source));
          await mapboxMap.style.setStyleLayerProperties(layerId, json.encode(iconProperties));
        });

        // Start the animation
        await _controller[markerId]?.forward();
        _controller[markerId]?.dispose(); // Dispose the controller after each iteration
      }
      markerPoints[markerId]?.clear();
    } on Exception catch (_) {
      rethrow;
    }
  }
}
