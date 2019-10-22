import 'package:flutter/material.dart';

const defaultFadeInDuration = Duration(milliseconds: 300);
const defaultFadeInDelayDuration = const Duration(milliseconds: 500);

class FadeInWidget extends StatefulWidget {
  const FadeInWidget(
      {Key key, @required this.child, Duration duration, Duration delay})
      : this.duration = duration ?? defaultFadeInDuration,
        this.delay = delay ?? defaultFadeInDelayDuration,
        super(key: key);
  final Duration duration;
  final Duration delay;

  final Widget child;

  @override
  _FadeInWidgetState createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _setupController();
  }

  _setupController() async {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    await Future.delayed(widget.delay);
    if (mounted) {
      _controller.animateTo(1.0, curve: Curves.linearToEaseOut);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FadeTransition(
      opacity: _controller,
      child: widget.child,
    );
  }
}

const defaultExpansionDuration = Duration(milliseconds: 300);
const defaultExpansionDelayDuration = Duration(milliseconds: 300);

class ExpansionWidget extends StatefulWidget {
  const ExpansionWidget(
      {Key key, Duration duration, Duration delay, this.child})
      : this.duration = duration ?? defaultExpansionDuration,
        this.delay = delay ?? defaultExpansionDelayDuration,
        assert(child != null),
        super(key: key);
  final Duration duration;
  final Duration delay;

  final Widget child;

  @override
  _ExpansionWidgetState createState() => _ExpansionWidgetState();
}

class _ExpansionWidgetState extends State<ExpansionWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  _setupController() async {
    _controller = AnimationController(vsync: this, duration: widget.duration);
    await Future.delayed(widget.delay);
    _controller.animateTo(1.0, curve: Curves.fastOutSlowIn);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _setupController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ScaleTransition(
      scale: _controller,
      child: widget.child,
    );
  }
}
