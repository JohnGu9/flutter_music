import 'package:flutter/services.dart';

/// By now only support Android
class ExtendPlugin {
  static const MethodChannel AndroidChannel = MethodChannel('Android');
//  static const MethodChannel IOSChannel = MethodChannel('IOS');

  static moveTaskToBack() async =>
      AndroidChannel.invokeMethod('moveTaskToBack');


}
