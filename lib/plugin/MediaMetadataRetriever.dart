import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MethodChannel MediaMetadataRetrieverCHANNEL =
    MethodChannel('MediaMetadataRetriever');

// raw api async
// return ImageProvider
Future<ImageProvider> getArtworkFromAudioFile(String path) async =>
    Future.microtask(() async {
      final Uint8List list = await MediaMetadataRetrieverCHANNEL.invokeMethod(
          'getEmbeddedPicture', {'path': path});
      return list == null ? null : MemoryImage(list);
    });
