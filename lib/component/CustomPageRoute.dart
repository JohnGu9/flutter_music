import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const CustomRouteTransitionDuration = const Duration(milliseconds: 400);

class CustomPageRoute<T> extends PageRoute<T> {
  CustomPageRoute({
    @required this.builder,
    RouteSettings settings,
    Widget Function(BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child)
        transitionBuilder,
    Duration transitionDuration,
    Widget Function(BuildContext context, CustomPageController controller,
            bool Function() enabledCallback, Widget child)
        routeController,
  })  : assert(builder != null),
        this.duration = transitionDuration ?? CustomRouteTransitionDuration,
        this.transitionBuilder = transitionBuilder ?? _defaultTransitionBuilder,
        this.routeController = routeController ?? _defaultRouteController,
        super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;
  final Duration duration;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  bool canTransitionFrom(TransitionRoute previousRoute) {
    // TODO: implement canTransitionFrom
    return true;
  }

  @override
  bool canTransitionTo(TransitionRoute nextRoute) {
    // TODO: implement canTransitionTo
    return true;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final Widget result = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
    assert(() {
      if (result == null) {
        throw FlutterError(
            'The builder for route "${settings.name}" returned null.\n'
            'Route builders must never return null.');
      }
      return true;
    }());
    return result;
  }

  final Widget Function(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) transitionBuilder;

  static final _transitionTween = Tween<double>(begin: 0, end: 1);
  static final Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) _defaultTransitionBuilder = (BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child) =>
      FadeTransition(
        opacity: _transitionTween.animate(animation),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          child: child,
        ),
      );

  /// use [routeController]
  ///  Must check [enabledCallback] inside [routeController] function
  final Widget Function(BuildContext context, CustomPageController controller,
      bool Function() enabledCallback, Widget child) routeController;
  static final Widget Function(
      BuildContext context,
      CustomPageController controller,
      bool Function() enabledCallback,
      Widget child) _defaultRouteController = (BuildContext context,
          CustomPageController controller,
          bool Function() enabledCallback,
          Widget child) =>
      child;

  static bool isPopGestureInProgress(PageRoute<dynamic> route) =>
      route.navigator.userGestureInProgress;

  bool popGestureEnabled() => _isPopGestureEnabled(this);

  static bool _isPopGestureEnabled<T>(PageRoute<T> route) {
    // If there's nothing to go back to, then obviously we don't support
    // the back gesture.
    if (route.isFirst) return false;
    // If the route wouldn't actually pop if we popped it, then the gesture
    // would be really confusing (or would skip internal routes), so disallow it.
    if (route.willHandlePopInternally) return false;
    // If attempts to dismiss this route might be vetoed such as in a page
    // with forms, then do not allow the user to dismiss the route with a swipe.
    if (route.hasScopedWillPopCallback) return false;
    // Fullscreen dialogs aren't dismissible by back swipe.
    if (route.fullscreenDialog) return false;
    // If we're in an animation already, we cannot be manually swiped.
    if (route.animation.status != AnimationStatus.completed) return false;
    // If we're being popped into, we also cannot be swiped until the pop above
    // it completes. This translates to our secondary animation being
    // dismissed.
    if (route.secondaryAnimation.status != AnimationStatus.dismissed)
      return false;
    // If we're in a gesture already, we cannot start another.

    if (isPopGestureInProgress(route)) return false;

    // Looks like a back gesture would be welcome!
    return true;
  }

  static CustomPageController<T> backGestureController<T>(PageRoute<T> route) {
    return CustomPageController<T>(
      navigator: route.navigator,
      controller: route.controller, // protected access
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      // TODO: implement buildTransitions
      transitionBuilder(context, animation, secondaryAnimation, child);

  static clipOvalTransition(Offset start, {bool backdropShadow = true}) {
    double targetWidth;
    double targetHeight;
    double maxRadius;
    return backdropShadow
        ? (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child) {
            final curve =
                CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);

            final width = MediaQuery.of(context).size.width;
            final height = MediaQuery.of(context).size.height;
            start.dx > width / 2
                ? targetWidth = start.dx
                : targetWidth = width - start.dx;
            start.dy > height / 2
                ? targetHeight = start.dy
                : targetHeight = height - start.dy;
            maxRadius =
                sqrt((pow(targetWidth * 2, 2) + pow(targetHeight * 2, 2)));
            final radius = Tween(begin: 0.0, end: maxRadius).animate(curve);
            final maxShadow = 0.6;
            return AnimatedBuilder(
              animation: curve,
              builder: (BuildContext context, Widget child) {
                return Container(
                  color: Colors.black.withOpacity(maxShadow * animation.value),
                  child: ClipOval(
                    clipper: CustomRect(start, radius.value),
                    child: Semantics(
                      scopesRoute: true,
                      explicitChildNodes: true,
                      child: child,
                    ),
                  ),
                );
              },
              child: child,
            );
          }
        : (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child) {
            final curve =
                CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
            final width = MediaQuery.of(context).size.width;
            final height = MediaQuery.of(context).size.height;
            start.dx > width / 2
                ? targetWidth = start.dx
                : targetWidth = width - start.dx;
            start.dy > height / 2
                ? targetHeight = start.dy
                : targetHeight = height - start.dy;
            maxRadius =
                sqrt((pow(targetWidth * 2, 2) + pow(targetHeight * 2, 2)));
            final radius = Tween(begin: 0.0, end: maxRadius).animate(curve);
            return AnimatedBuilder(
              animation: curve,
              builder: (BuildContext context, Widget child) {
                return ClipOval(
                  clipper: CustomRect(start, radius.value),
                  child: Semantics(
                    scopesRoute: true,
                    explicitChildNodes: true,
                    child: child,
                  ),
                );
              },
              child: child,
            );
          };
  }
}

class CustomPageController<T> {
  CustomPageController({
    @required this.navigator,
    @required this.controller,
  })  : _routeControllerMaxValue = controller.upperBound,
        _routeControllerMinValue = controller.lowerBound,
        assert(navigator != null),
        assert(controller != null) {
    navigator.didStartUserGesture();
  }

  static const double _kMinFlingVelocity = 1.0; // Screen widths per second.
  static const int _kMaxDroppedSwipePageForwardAnimationTime =
      800; // Milliseconds.
  static const int _kMaxPageBackAnimationTime = 300; // Milliseconds.

  final _routeControllerMaxValue;
  final _routeControllerMinValue;

  final AnimationController controller;
  final NavigatorState navigator;
  double _updatedValue;

  void dragUpdate(double delta) {
    // protect controller from value overflow
    // hero widget will cause bug due to controller value overflow
    // the max value should be small than 1.0
    // boundary pretest
    _updatedValue = controller.value - delta;
    if (_updatedValue >= _routeControllerMaxValue) {
      controller.value = _routeControllerMaxValue;
    } else if (_updatedValue <= _routeControllerMinValue) {
      controller.value = _routeControllerMinValue;
    } else {
      controller.value = _updatedValue;
    }
  }

  /// The drag gesture has ended with a horizontal motion of
  /// [fractionalVelocity] as a fraction of screen width per second.
  void dragEnd(double velocity) {
    const Curve animationToCurve = Curves.bounceOut;
    const Curve animationBackCurve = Curves.decelerate;
    bool animateForward;

    animateForward = velocity < _kMinFlingVelocity;
    if (animateForward) {
      final int droppedPageForwardAnimationTime = min(
        lerpDouble(
                _kMaxDroppedSwipePageForwardAnimationTime, 0, controller.value)
            .floor(),
        _kMaxPageBackAnimationTime,
      );
      controller.animateTo(1.0,
          duration: Duration(milliseconds: droppedPageForwardAnimationTime),
          curve: animationToCurve);
    } else {
      navigator.pop();

      if (controller.isAnimating) {
        final int droppedPageBackAnimationTime = lerpDouble(
                0, _kMaxDroppedSwipePageForwardAnimationTime, controller.value)
            .floor();
        controller.animateBack(0.0,
            duration: Duration(milliseconds: droppedPageBackAnimationTime),
            curve: animationBackCurve);
      }
    }

    if (controller.isAnimating) {
      AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller?.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}

class CustomPageRouteGestureDetector extends StatefulWidget {
  const CustomPageRouteGestureDetector({
    Key key,
    @required this.enabledCallback,
    @required this.child,
    @required this.controller,
    this.direction = AxisDirection.down,

    /// The abstract push animation direction
  }) : super(key: key);
  final Widget child;
  final CustomPageController controller;
  final bool Function() enabledCallback;
  final AxisDirection direction;

  @override
  _CustomPageRouteGestureDetectorState createState() =>
      _CustomPageRouteGestureDetectorState();
}

class _CustomPageRouteGestureDetectorState
    extends State<CustomPageRouteGestureDetector> {
  CustomPageController _backGestureController;

  VerticalDragGestureRecognizer _recognizer;

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    _backGestureController = widget.controller;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    _backGestureController.dragUpdate(
        _convertToLogical(details.primaryDelta / context.size.height));
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    _backGestureController.dragEnd(_convertToLogical(
        details.velocity.pixelsPerSecond.dy / context.size.height));
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) _recognizer.addPointer(event);
  }

  // ignore: unused_element
  double _convertToLogical(double value) {
    switch (widget.direction) {
      case AxisDirection.up:
        return value;
      default:
        return -value;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _recognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Listener(
        onPointerDown: _handlePointerDown,
        behavior: HitTestBehavior.translucent,
        child: widget.child);
  }
}

class CustomRect extends CustomClipper<Rect> {
  CustomRect(this.startPoint, this.radius);

  Offset startPoint;
  double radius;

  @override
  Rect getClip(Size size) {
    // TODO: implement getClip
    return Rect.fromCenter(center: startPoint, width: radius, height: radius);
  }

  @override
  bool shouldReclip(CustomRect oldClipper) {
    // TODO: implement shouldReclip
    return true;
  }
}
