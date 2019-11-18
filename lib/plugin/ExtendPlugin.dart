import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// By now only support Android
class ExtendPlugin {
  static const MethodChannel AndroidChannel = MethodChannel('Android');

//  static const MethodChannel IOSChannel = MethodChannel('IOS');

  static moveTaskToBack() async =>
      AndroidChannel.invokeMethod('moveTaskToBack');

  static saveJpegFile(
          {@required String filePath, @required Uint8List bytes}) async =>
      await AndroidChannel.invokeMethod(
          'SaveByteAsJpeg', {'filePath': filePath, 'bytes': bytes});

  static Future<Uint8List> readJpegFile({@required String filePath}) =>
      AndroidChannel.invokeMethod('ReadJpegAsByte', {'filePath': filePath});

  static test() async => AndroidChannel.invokeMethod('test');
}
