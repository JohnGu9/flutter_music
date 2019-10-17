import 'package:flutter/material.dart';

const TransparentRouteTransitionDuration = const Duration(milliseconds: 400);

class TransparentRoute<T> extends PageRoute<T> {
  TransparentRoute({
    @required this.builder,
    RouteSettings settings,
    Widget Function(BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation, Widget child)
        transitionBuilder,
  })  : assert(builder != null),
        this.transitionBuilder = transitionBuilder ?? _defaultTransitionBuilder,
        super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => TransparentRouteTransitionDuration;

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

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      // TODO: implement buildTransitions
      transitionBuilder(context, animation, secondaryAnimation, child);
}
