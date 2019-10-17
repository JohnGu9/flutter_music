import 'package:flutter/services.dart';

class AndroidPlugin {
  static const MethodChannel AndroidCHANNEL = MethodChannel('Android');

  static moveTaskToBack() async =>
      AndroidCHANNEL.invokeMethod('moveTaskToBack');


}
