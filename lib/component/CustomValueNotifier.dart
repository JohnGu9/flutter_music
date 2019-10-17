// This CustomValueNotifier is modified from ValueNotifier.
// Feature with public notifyListeners and a state mask.
// The state mask will be change while notifyListeners is called, that could be used for ValueKey in order to update widget properly.
// This is easy to use List and etc. in this value notifier.
import 'package:flutter/foundation.dart';

class CustomValueNotifier<T> extends ChangeNotifier
    implements ValueListenable<T> {
  CustomValueNotifier(this._value) : _stateCounter = 0;
  int _stateCounter;

  static const int maxSubState = 10000;

  @override
  T get value => _value;
  T _value;

  int get state => this.hashCode * maxSubState + (_stateCounter % maxSubState);

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';

  notifyListeners() {
    super.notifyListeners();
    _stateCounter += 1;
  }
}
