import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Constants {
  static const String MaterialAppTitle = 'Music';
  static const String HomePageTitle = 'Music';

  static const Color darkGrey = Color(0xFF202020);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const String defaultFontFamily = 'Hind';

  static const LightThemeFontWeight = FontWeight.w400;
  static const defaultLightTextTheme = TextTheme(
    headline: TextStyle(
        fontSize: 24.0,
        fontFamily: defaultFontFamily,
        fontWeight: LightThemeFontWeight),
    title: TextStyle(
        fontSize: 24.0,
        fontFamily: defaultFontFamily,
        fontWeight: LightThemeFontWeight),
    body1: TextStyle(
        fontSize: 18.0,
        fontFamily: defaultFontFamily,
        fontWeight: LightThemeFontWeight),
    body2: TextStyle(
        fontSize: 15.0,
        fontFamily: defaultFontFamily,
        fontWeight: LightThemeFontWeight),
  );
  static const DarkThemeFontWeight = FontWeight.w300;
  static const defaultDarkTextTheme = TextTheme(
    headline: TextStyle(
        fontSize: 24.0,
        fontFamily: defaultFontFamily,
        fontWeight: DarkThemeFontWeight),
    title: TextStyle(
        fontSize: 24.0,
        fontFamily: defaultFontFamily,
        fontWeight: DarkThemeFontWeight),
    body1: TextStyle(
        fontSize: 18.0,
        fontFamily: defaultFontFamily,
        fontWeight: DarkThemeFontWeight),
    body2: TextStyle(
        fontSize: 15.0,
        fontFamily: defaultFontFamily,
        fontWeight: DarkThemeFontWeight),
  );

  static final ThemeData customDarkTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: Colors.grey[850],
    backgroundColor: darkGrey,
    accentColor: Colors.white54,
    brightness: Brightness.dark,
    indicatorColor: Colors.grey[700],
    sliderTheme: const SliderThemeData(
      showValueIndicator: ShowValueIndicator.always,
      trackHeight: 5.0,
      valueIndicatorTextStyle: TextStyle(color: darkGrey),
      thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 0.0, disabledThumbRadius: 0.0),
    ),
    dividerColor: Colors.transparent,
    fontFamily: defaultFontFamily,
    textTheme: defaultDarkTextTheme,
  );

  static final ThemeData customLightTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: Colors.grey[200],
    backgroundColor: lightGrey,
    accentColor: Colors.black12,
    brightness: Brightness.light,
    indicatorColor: Colors.grey[850],
    sliderTheme: const SliderThemeData(
      showValueIndicator: ShowValueIndicator.always,
      trackHeight: 5.0,
      valueIndicatorTextStyle: TextStyle(color: lightGrey),
      thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 0.0, disabledThumbRadius: 0.0),
    ),
    dividerColor: Colors.transparent,
    fontFamily: defaultFontFamily,
    textTheme: defaultLightTextTheme,
  );

  static const String appTitle = 'Music';
  static const String defaultMusicTitle = 'Music';
  static const String defaultMusicArtist = 'For this moment';

  static const Duration defaultDuration = const Duration(milliseconds: 500);
  static const Duration defaultShortDuration =
      const Duration(milliseconds: 250);
  static const Duration defaultLongDuration = const Duration(seconds: 1);
  static const Duration defaultLoadingDelay = const Duration(milliseconds: 500);
  static const Curve HalfCurve = const halfCurve();
  static const Curve ReverseHalfCurve = const reverseHalfCurve();

  static const radius = Radius.circular(5.0);
  static const BorderRadius borderRadius = BorderRadius.all(radius);

  static final Widget Function(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) targetFadeInOutFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget;
    final Hero fromHero = fromHeroContext.widget;
    return flightDirection == HeroFlightDirection.push
        ? Stack(
            children: <Widget>[
              fromHero,
              FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeInCirc)),
                child: toHero,
              ),
            ],
          )
        : Stack(
            children: <Widget>[
              toHero,
              FadeTransition(
                  opacity:
                      animation.drive(CurveTween(curve: Curves.easeInCirc)),
                  child: fromHero),
            ],
          );
  };
  static final Widget Function(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) targetAndSourceFadeInOutFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget;
    final Hero fromHero = fromHeroContext.widget;
    return flightDirection == HeroFlightDirection.push
        ? Stack(
            children: <Widget>[
              FadeTransition(
                  opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
                      parent: animation, curve: Curves.fastOutSlowIn)),
                  child: fromHero),
              FadeTransition(
                opacity: Tween(begin: 0.0, end: 1.0).animate(animation),
                child: toHero,
              ),
            ],
          )
        : Stack(
            children: <Widget>[
              FadeTransition(
                  opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(
                      parent: animation, curve: Curves.fastOutSlowIn)),
                  child: toHero),
              FadeTransition(
                  opacity: Tween(begin: 0.0, end: 1.0).animate(animation),
                  child: fromHero),
            ],
          );
  };

  static final Function(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) targetPriorityFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget;
    final Hero fromHero = fromHeroContext.widget;
    return SizeTransition(
      sizeFactor: animation.drive(CurveTween(curve: Curves.easeInExpo)),
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeInExpo)),
        child: flightDirection == HeroFlightDirection.push ? toHero : fromHero,
      ),
    );
  };

  static final Function(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) fromHeroPriorityFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero fromHero = fromHeroContext.widget;
    return fromHero;
  };

  static final Function(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) sourcePriorityFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget;
    final Hero fromHero = fromHeroContext.widget;
    return SizeTransition(
      sizeFactor: animation.drive(CurveTween(curve: Curves.easeInExpo)),
      child: FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeInExpo)),
        child: flightDirection == HeroFlightDirection.push ? fromHero : toHero,
      ),
    );
  };

  static const double panelOpacity = 0.8;

  static const String unknown = '<unknown>';

  static const double miniPanelHeight = 115;

  static const double gridDelegateHeight = 1.25;
  static const gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1 / gridDelegateHeight,
  );

  static BoxDecoration customBoxDecoration(Brightness brightness) {
    return BoxDecoration(
      gradient: LinearGradient(
        // Where the linear gradient begins and ends
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Add one stop for each color. Stops should increase from 0 to 1
        stops: [0.68, 0.75, 1.0],
        colors: brightness == Brightness.light
            ? [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.3),
              ]
            : [
                Colors.black.withOpacity(0.0),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.4),
              ],
      ),
    );
  }

  static const double decorationOpacity = 0.5;
  static const Widget emptyArtwork = const SizedBox.expand(
    child: const FittedBox(
      fit: BoxFit.contain,
      child: const ScaleTransition(
        scale: const AlwaysStoppedAnimation<double>(0.5),
        child: const FadeTransition(
          opacity: const AlwaysStoppedAnimation<double>(decorationOpacity),
          child: const Icon(Icons.music_note),
        ),
      ),
    ),
  );

  static const Widget emptyPersonPicture = const SizedBox.expand(
    child: const FittedBox(
      fit: BoxFit.contain,
      child: const ScaleTransition(
        scale: const AlwaysStoppedAnimation<double>(0.5),
        child: const FadeTransition(
          opacity: const AlwaysStoppedAnimation<double>(decorationOpacity),
          child: const Icon(Icons.person_pin),
        ),
      ),
    ),
  );

  static const textOpacity = 0.7;

  static textStyleWithShadow(TextStyle textStyle, Color color) {
    return TextStyle(
      fontWeight: textStyle.fontWeight,
      color: textStyle.color.withOpacity(decorationOpacity),
      shadows: [
        Shadow(
          blurRadius: 20.0,
          color: color,
          offset: Offset(1.0, 3.0),
        ),
      ],
    );
  }

  static const double BarPreferHeight = 80;
  static const Size BarPreferSize =
      const Size(double.infinity, BarPreferHeight);
}

void systemSetup(BuildContext context) async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  if (Theme.of(context).brightness == Brightness.dark) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarColor: Constants.darkGrey,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarColor: Constants.lightGrey,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }
}

// ignore: camel_case_types
class halfCurve extends Curve {
  const halfCurve();

  @override
  double transform(double t) {
    // TODO: implement transform
    return t >= 1 / 2 ? 2 * t - 1 : 0.0;
  }
}

// ignore: camel_case_types
class reverseHalfCurve extends Curve {
  const reverseHalfCurve();

  @override
  double transform(double t) {
    assert(t >= 0 && t <= 1);
    return t >= 1 / 2 ? 0.0 : 1 - 2 * t;
  }
}

const _defaultAlertDialogTitle = Text('Tip');
const _defaultAlertDialogContent = Text('This feature is not available yet. ');

// ignore: non_constant_identifier_names
FeatureUnsupportedDialog(BuildContext context) async =>
    Future.microtask(() async => showDialog(
          context: context,
          builder: (BuildContext context) {
            // return object of type Dialog
            return AlertDialog(
              backgroundColor: Theme.of(context).backgroundColor,
              title: _defaultAlertDialogTitle,
              content: _defaultAlertDialogContent,
              actions: <Widget>[
                // usually buttons at the bottom of the dialog
                FlatButton(
                  child: Text(
                    "Close",
                    style: Theme.of(context).textTheme.body2,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        ));
