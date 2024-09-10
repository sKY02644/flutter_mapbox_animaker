import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<Uint8List?> loadImageAsUint8List(String assetPath) async {
  try {
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List();
    Uint8List uint8List = Uint8List.fromList(bytes);
    return uint8List;
  } catch (e) {
    if (kDebugMode) {
      print("Error loading image: $e");
    }
    return null;
  }
}

// Function to normalize rotation angles to avoid large jumps
double normalizeRotation(double start, double end) {
  double difference = end - start;
  if (difference > 180) {
    end -= 360; // Adjust counter-clockwise rotation
  } else if (difference < -180) {
    end += 360; // Adjust clockwise rotation
  }
  return end;
}

Future<Size> getImageSizeFromAssets(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  final codec = await instantiateImageCodec(data.buffer.asUint8List());
  final frameInfo = await codec.getNextFrame();
  return Size(
      frameInfo.image.width.toDouble(), frameInfo.image.height.toDouble());
}
