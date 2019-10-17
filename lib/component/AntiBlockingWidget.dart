import 'package:flutter/material.dart';

const AntiBlockDuration = const Duration(milliseconds: 400);

class AntiBlockingWidget extends StatelessWidget {
  const AntiBlockingWidget({Key key, @required this.listenable, this.child, this.offset})
      : super(key: key);
  final Listenable listenable;
  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: this.listenable,
      builder: (BuildContext context, bool isIgnoring, Widget child) {
        // Automatic hide the child while listenable's value is true.
        return AnimatedContainer(
          duration: AntiBlockDuration,
          curve: Curves.fastOutSlowIn,
          transform: isIgnoring
              ? Matrix4.translationValues(this.offset.dx, this.offset.dy, 0)
              : Matrix4.translationValues(0, 0, 0),
          child: IgnorePointer(
            ignoring: isIgnoring,
            child: child,
          ),
        );
      },
      child: this.child,
    );
  }
}
