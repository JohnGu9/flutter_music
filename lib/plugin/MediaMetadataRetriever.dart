import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../component/CustomValueNotifier.dart';

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
          debugPrint('Palette is null');
        } else {
          List<Color> colors = List<Color>();
          for (; index < palette.length; index++) {
            colors.add(
                palette[index] == null ? null : colorParse(palette[index]));
          }
          filePathToPaletteMap[path].value = colors;
        }
        debugPrint(filePathToPaletteMap[path].value.toString());
        break;
      default:
    }
    return null;
  }

  static final filePathToPaletteRequiredMap = Map<String, bool>();
  static final filePathToPaletteMap =
      Map<String, CustomValueNotifier<List<Color>>>();

  // Index of Palette Colors
  static const DominantColor = 0;
  static const VibrantColor = 1;
  static const MutedColor = 2;
  static const LightVibrantColor = 3;
  static const LightMutedColor = 4;
  static const DarkVibrantColor = 5;
  static const DarkMutedColor = 6;

  static Color getDarkColor(List<Color> colors) {
    assert(colors.length >= 7);
    return colors[DarkVibrantColor] != null
        ? colors[DarkVibrantColor]
        : colors[DarkMutedColor] != null
            ? colors[DarkMutedColor]
            : colors[DominantColor];
  }

  static Color getLightColor(List<Color> colors) {
    assert(colors.length >= 7);
    return colors[LightVibrantColor] != null
        ? colors[LightVibrantColor]
        : colors[LightMutedColor] != null
            ? colors[LightMutedColor]
            : colors[DominantColor];
  }

  // Parse Android [Color] Object getRgb method result
  static Color colorParse(int rgb) => Color.fromARGB(
      255, (rgb & 16711680) >> 16, (rgb & 65280) >> 8, (rgb & 255));

  // raw api async
  static Future<ImageProvider> getEmbeddedPicture(String path) async {
    filePathToPaletteMap[path] ??= CustomValueNotifier(null);
    return Future.microtask(() async {
      final Uint8List list = await MediaMetadataRetrieverCHANNEL.invokeMethod(
          'getEmbeddedPicture', {
        'path': path,
        'palette': !filePathToPaletteRequiredMap.containsKey(path)
      });
      filePathToPaletteRequiredMap[path] = true;

      return list == null ? null : MemoryImage(list);
    });
  }
}
