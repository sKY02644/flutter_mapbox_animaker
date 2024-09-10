
# Marker Animator for Mapbox in Flutter

This package allows smooth animation of markers on a Mapbox map by adding and moving markers dynamically based on the live locations of markers.

## Features

- Add marker(s) dynamically to the map.
- Animate marker markers from one location to another with smooth transitions.
- Supports both position and rotation animation curves.
- Customize marker properties such as size, opacity, and rotation.
- Easily remove marker markers from the map.

## Installation

To use this package, add the following dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  mapbox_maps_flutter: ^1.0.0
  <your_other_dependencies>
```

## Usage

### 1. Initialize the `MarkerAnimator`:

```dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'marker_animator.dart';  // Import the MarkerAnimator class

final mapboxMap = MapboxMap(<your_mapbox_initialization>);
final markerAnimator = MarkerAnimator(mapboxMap);
```

### 2. Add a Marker(s):

You can add a marker(s) and pass the marker's movement data as follows:

```dart
markerAnimator.addMarkerPoint(
  'markerId123',
  'assets/marker_icon.png',  // Path to your marker image
  [
    {'position': [longitude, latitude], 'rotation': 0},
    {'position': [longitude2, latitude2], 'rotation': 30},
    // Add more positions as needed
  ],
  interval: 0.05,  // Optional: interval between animation frames
  imageWidth: 64,   // Optional: width of the marker image
  imageHeight: 64,  // Optional: height of the marker image
  properties: {
    "icon-opacity": 0.9,
    "icon-size": 1.2,
  }
);
```

### 3. Remove a Marker Marker:

To remove a marker marker from the map:

```dart
await markerAnimator.removeMarker();
```

### 4. Customize Marker Properties:

You can pass custom properties for the marker:

```dart
Map<String, dynamic> customProperties = {
  "icon-opacity": 0.8,
  "icon-size": 1.5,
  "icon-anchor": "center",
  'icon-allow-overlap': true,
};

markerAnimator.addMarkerPoint(
  'markerId456',
  'assets/another_marker_icon.png',
  data,  // The marker movement data
  properties: customProperties,
);
```

### 5. Marker Style Properties

The properties should follow the [Mapbox Style Specification](https://docs.mapbox.com/mapbox-gl-js/style-spec/layers/#type) for symbol layers. These properties allow you to control aspects like icon size, opacity, rotation, anchor position, and more.

## Notes

- The marker movement data should include a list of positions and rotations.
- The animation interval controls the speed of the marker transition. A smaller interval results in smoother animations.
- Ensure you handle the Mapbox API key and map initialization properly.