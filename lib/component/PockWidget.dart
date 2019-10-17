import 'dart:math';

import 'package:flutter/material.dart';

const _kDefaultDuration = const Duration(milliseconds: 500);

class PockWidget extends StatefulWidget {
  const PockWidget(
      {Key key, @required this.child, @required this.flingCallBack, this.onTap})
      : super(key: key);

  final Widget child;
  final Function(Velocity) flingCallBack;
  final Function() onTap;

  @override
  _PockWidgetState createState() => _PockWidgetState();
}

class _PockWidgetState extends State<PockWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _offsetController;
  Animation _offsetAnimation;
  ValueNotifier<Offset> _offset;
  Offset _onVerticalDragStartPosition;

  _onVerticalDragStart(DragStartDetails detail) {
    _onVerticalDragStartPosition = detail.globalPosition;
  }

  _onVerticalDragUpdate(DragUpdateDetails detail) {
    if (_offsetController.isAnimating) {
      return;
    }
    _offset.value = Offset(
        0,
        attenuation(detail.globalPosition.dy - _onVerticalDragStartPosition.dy,
            factor: 0.6));
  }

  _onVerticalDragEnd(DragEndDetails detail) {
    if (_offset.value != Offset.zero) {
      _offsetAnimation = Tween<Offset>(begin: _offset.value, end: Offset.zero)
          .animate(_offsetController)
            ..addListener(() => _offset.value = _offsetAnimation.value);
      _offsetController.reset();
      _offsetController.fling();
    }
    widget.flingCallBack(detail.velocity);
  }

  static double attenuation(double input, {double factor = 0.5}) {
    return input >= 0 ? pow(input, factor) : (-pow(input.abs(), factor));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _offsetController =
        AnimationController(vsync: this, duration: _kDefaultDuration);
    _offset = ValueNotifier<Offset>(Offset(0, 0));
  }


  @override
  void dispose() {
    // TODO: implement dispose
    _offset.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTap: widget.onTap,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: ValueListenableBuilder(
        valueListenable: _offset,
        builder: (BuildContext context, Offset _offset, Widget child) {
          return Transform.translate(
            offset: _offset,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
