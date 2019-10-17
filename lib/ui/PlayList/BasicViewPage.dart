import 'dart:ui';

import 'package:flutter/material.dart';
import '../../data/Constants.dart';

class BasicViewPage extends StatelessWidget {
  const BasicViewPage({Key key, this.onWillPop, this.child}) : super(key: key);
  final Function() onWillPop;
  final Widget child;

  Future<bool> _onWillPop() async {
    await onWillPop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Container(
        color: Colors.black38,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            MainContent(child: child),
            RemainSpace(onWillPop: onWillPop),
          ],
        ),
      ),
    );
  }
}

class MainContent extends StatelessWidget {
  const MainContent({Key key, this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class RemainSpace extends StatelessWidget {
  const RemainSpace({Key key, this.onWillPop}) : super(key: key);
  final onWillPop;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTap: onWillPop,
      child: Container(
        height: Constants.miniPanelHeight,
        color: Colors.transparent,
      ),
    );
  }
}

class GeneralPanel extends StatelessWidget {
  const GeneralPanel({Key key, this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Material(
      elevation: 4.0,
      borderRadius: Constants.borderRadius,
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: Constants.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: child,
        ),
      ),
    );
  }
}
