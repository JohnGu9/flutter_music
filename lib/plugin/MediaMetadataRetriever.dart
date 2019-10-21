import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MediaMetadataRetriever {
  // ignore: non_constant_identifier_names
  static final MethodChannel MediaMetadataRetrieverCHANNEL =
      MethodChannel('MMR')..setMethodCallHandler(methodCallHandler);

  static Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Palette':
        int index = 0;
        List palette = methodCall.arguments;
        String path = palette[index++];
        if (palette.length == index) {
          filePathToPaletteMap[path] = null;
        } else {
          List<Color> colors = List<Color>();
          for (; index < palette.length;) {
            colors.add(colorParse(palette[index++]));
          }
          filePathToPaletteMap[path] = colors;
        }
        debugPrint(filePathToPaletteMap[path].toString());
        break;
      default:
    }
    return null;
  }

  static final filePathToPaletteRequiredMap = Map<String, bool>();
  static final filePathToPaletteMap = Map<String, List<Color>>();

  // Parse Android [Color] Object getRgb method result
  static Color colorParse(int rgb) => Color.fromARGB(
      255, (rgb & 16711680) >> 16, (rgb & 65280) >> 8, (rgb & 255));

// raw api async
// return ImageProvider
  static Future<ImageProvider> getEmbeddedPicture(String path) async =>
      Future.microtask(() async {
        final Uint8List list = await MediaMetadataRetrieverCHANNEL.invokeMethod(
            'getEmbeddedPicture', {
          'path': path,
          'palette': !filePathToPaletteRequiredMap.containsKey(path)
        });
        filePathToPaletteRequiredMap[path] = true;
        return list == null ? null : MemoryImage(list);
      });
}
