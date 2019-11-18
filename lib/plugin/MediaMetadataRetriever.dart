import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/data/Constants.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../component/CustomValueNotifier.dart';

class MediaMetadataRetriever {
  // ignore: non_constant_identifier_names
  static final MethodChannel MediaMetadataRetrieverChannel =
      MethodChannel('MMR')..setMethodCallHandler(methodCallHandler);

  static Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Palette':
        int index = 0;
        List palette = methodCall.arguments;
        String path = palette[index++];
        if (palette.length == index) {
        } else {
          List<Color> colors = List<Color>();
          for (; index < palette.length; index++) {
            colors.add(
                palette[index] == null ? null : colorParse(palette[index]));
          }
          filePathToPaletteMap[path].value = colors;
        }
        break;

      case 'getRemotePicture':
        List arguments = methodCall.arguments;
        remotePicturePath = arguments[PicturePath];
        remotePictureData = arguments[PictureData];
        filePathToRemotePictureMap[remotePicturePath] = remotePictureData;
        getRemotePictureCallback.notifyListeners();
        break;
      default:
    }
    return null;
  }

  static const PicturePath = 0;
  static const PictureData = 1;
  static String remotePicturePath;
  static Uint8List remotePictureData;
  static CustomValueNotifier getRemotePictureCallback =
      CustomValueNotifier(null);
  static final filePathToRemotePictureMap = Map<String, Uint8List>();

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
  static Future<ImageProvider> getEmbeddedPicture(String filePath) async {
    filePathToPaletteMap[filePath] ??= CustomValueNotifier(null);
    return Future.microtask(() async {
      final Uint8List list = await MediaMetadataRetrieverChannel.invokeMethod(
          'getEmbeddedPicture', {
        'filePath': filePath,
      });
      return list == null ? null : MemoryImage(list);
    });
  }

  /// additional function
  /// getRemotePicture: search image from internet
  /// Warning: This function don't return any result
  ///  [getRemotePictureCallback] will notify when java return result
  ///  Results are [remotePicturePath] and [remotePictureData] but data will be sweeped when new data return from java!
  ///  [filePathToRemotePictureMap] will keep the data forever
  static void getRemotePicture(
      {String filePath,
      String artist,
      String title,
      String album,
      SongInfo songInfo}) {
    if (songInfo != null) {
      filePath = songInfo.filePath;
      artist = songInfo.artist;
      title = songInfo.title;
      album = songInfo.album;
    }
    if (artist?.length == 0 || artist == Constants.unknown) artist = null;
    if (album?.length == 0 || album == Constants.unknown) album = null;
    if (title?.length == 0 || title == Constants.unknown) title = null;

    filePathToPaletteMap[filePath] ??= CustomValueNotifier(null);
    MediaMetadataRetrieverChannel.invokeMethod('getRemotePicture', {
      'filePath': filePath,
      'artist': artist,
      'title': title,
      'album': album,
    });
    filePathToPaletteRequiredMap[filePath] = true;
  }

  /// additional function
  /// Warning: This function don't return any result
  static void getPalette(String filePath, Uint8List artwork) {
    assert(artwork != null);
    filePathToPaletteMap[filePath] ??= CustomValueNotifier(null);
    MediaMetadataRetrieverChannel.invokeMethod('getPalette', {
      'filePath': filePath,
      'artwork': artwork,
    });
  }
}
