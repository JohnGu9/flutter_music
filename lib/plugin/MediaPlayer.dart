import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show MethodCall, MethodChannel;
import 'package:flutter_app/component/CustomValueNotifier.dart';

// MediaPlayer Status
enum MediaPlayerStatus {
  idle,
  end,
  error,
  preparing,
  prepared,
  started,
  paused,
  stopped,
  playbackCompleted,
}

class MediaPlayer {
  // ignore: non_constant_identifier_names
  static final MediaPlayerChannel = const MethodChannel('MP')
    ..setMethodCallHandler(methodCallHandler);

  // Java invokeMethod
  static Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Dart':
        debugPrint('Dart is available. ');
        return null;

      case 'onPrevious':
        onPrevious();
        return null;

      case 'onNext':
        onNext();
        return null;

      case 'stateManager':
        switch (methodCall.arguments) {
          case 'idle':
            _stateUpdate(MediaPlayerStatus.idle);
            break;
          case 'started':
            _stateUpdate(MediaPlayerStatus.started);
            break;
          case 'paused':
            _stateUpdate(MediaPlayerStatus.paused);
            break;
          case 'stopped':
            _stateUpdate(MediaPlayerStatus.stopped);
            break;
          case 'preparing':
            _stateUpdate(MediaPlayerStatus.preparing);
            return null;
            break;
          case 'end':
            debugPrint('MediaPlayer end');
            _stateUpdate(MediaPlayerStatus.end);
        }
        return null;

      case 'onPreparedListener':
        _stateUpdate(MediaPlayerStatus.prepared);
        currentDurationNotifier.value = methodCall.arguments;
        currentPositionNotifier.value = 0;
        onPositionChangeListener(currentPosition, currentDuration);
        onPreparedNotifier.notifyListeners();
        return null;

      case 'onErrorListener':
        debugPrint('Warning: onErrorListener');
        _stateUpdate(MediaPlayerStatus.error);
        List<int> errorList = methodCall.arguments;
        onErrorListener(errorList[0], errorList[1]);
        return null;

      case 'onSeekCompleteListener':
        int position = methodCall.arguments;
        currentPositionNotifier.value = position;
        onPositionChangeListener(currentPosition, currentDuration);
        onSeekCompleteNotifier.notifyListeners();
        return null;

      case 'onCompletionListener':
        _stateUpdate(MediaPlayerStatus.playbackCompleted);
        onCompletionNotifier.notifyListeners();
        return null;

      case 'onBufferingUpdateListener':
        onBufferingUpdateListener(methodCall.arguments);
        return null;

      default:
        return null;
    }
  }

  static onPlayAndPause() => status == MediaPlayerStatus.started
      ? MediaPlayer.pause()
      : MediaPlayer.start();

  static onSkipPrevious() => onPrevious();

  static onSkipNext() => onNext();
  static void Function() onPrevious = () {};
  static void Function() onNext = () {};

  static final ValueNotifier<int> currentDurationNotifier =
      ValueNotifier<int>(1);

  static int get currentDuration => currentDurationNotifier.value;

  static final ValueNotifier<int> currentPositionNotifier =
      ValueNotifier<int>(0);

  static int get currentPosition => currentPositionNotifier.value;

  static Function() onPreparedListener = defaultPreparedListener;
  static Function(int what, int extra) onErrorListener =
      // Default CallBack
      (int what, int extra) async => MediaPlayer.reset();

  static Function() onSeekCompleteListener = () {};
  static Function() onCompletionListener = () {};
  static Function(int i) onBufferingUpdateListener = (int i) {};
  static Function(MediaPlayerStatus state, MediaPlayerStatus preState)
      onStateChangeListener = // Default CallBack
      (MediaPlayerStatus state, MediaPlayerStatus preState) =>
          debugPrint('MediaPlayerStatus' + state.toString());

  static final CustomValueNotifier<MediaPlayerStatus> statusNotifier =
      CustomValueNotifier(MediaPlayerStatus.idle);

  static MediaPlayerStatus get status => statusNotifier.value;

  static set status(value) => statusNotifier.value = value;

  static void _stateUpdate(MediaPlayerStatus s /*new state*/) async {
    MediaPlayerStatus _preState = status;
    status = s;
    onStateChangeListener(status, _preState);

    // setup onPositionChangeListener
    if (status == MediaPlayerStatus.started) {
      positionUpdateTimer =
          Timer.periodic(positionUpdateTimeInterval, (timer) async {
        currentPositionNotifier.value =
            await MediaPlayerChannel.invokeMethod('getCurrentPosition');
        onPositionChangeListener(
            MediaPlayer.currentPosition, MediaPlayer.currentDuration);
      });
    } else {
      if (positionUpdateTimer != null && positionUpdateTimer.isActive) {
        // release positionUpdateTimer
        positionUpdateTimer.cancel();
      }
    }
  }

  static const Duration positionUpdateTimeInterval =
      Duration(milliseconds: 1000);
  static Function(int position, int duration) onPositionChangeListener =
      (int position, int duration) => null;

//          debugPrint(position.toString());

  static Timer positionUpdateTimer;

  static final onPreparedNotifier = CustomValueNotifier(null)
    ..addListener(() => onPreparedListener());

  static void setOnPreparedListener(Function() fun) =>
      // This class always listen OnPrepared to maintain status machine. So no need to invoke method setOnPreparedListener.
      onPreparedListener = fun;

  static Function() defaultPreparedListener = () {};

  static void removeOnPreparedListener() =>
      // This class always listen OnPrepared to maintain status machine. So no need to invoke method setOnPreparedListener.
      onPreparedListener = defaultPreparedListener;

  static void setOnErrorListener(Function(int what, int extra) fun) =>
      // This class always listen OnError to maintain status machine. So no need to invoke method setOnErrorListener.
      onErrorListener = fun;

  static final onCompletionNotifier = CustomValueNotifier(null)
    ..addListener(() => onCompletionListener());

  static void setOnCompletionListener(Function() fun) =>
      // This class always listen OnCompletion to maintain status machine. So no need to invoke method setOnCompletionListener.
      onCompletionListener = fun;

  static final onSeekCompleteNotifier = CustomValueNotifier(null)
    ..addListener(() => onSeekCompleteListener());

  static void setOnSeekCompleteListener(Function() fun) =>
      onSeekCompleteListener = fun;

  static void setOnBufferingUpdateListener(Function(int i) fun) =>
      onBufferingUpdateListener = fun;

  static void setOnStateChangeListener(
          Function(MediaPlayerStatus state, MediaPlayerStatus preState) fun) =>
      onStateChangeListener = fun;

  static void setOnPositionChangeListener(
          Function(int position, int duration) fun) =>
      onPositionChangeListener = fun;

  // app will auto setup mediaPlayer in the beginning, it shouldn't init again while app start
  static void init() =>
      MediaPlayerChannel.invokeMethod('init').catchError((error) {
        debugPrint('onConstructors');
        debugPrint(error.toString());
      });

  static String currentMedia;

  static void setDataSource(String path) async {
    // setDataSource will auto reset MediaPlayer
    if (path == null) {
      return;
    }
    currentMedia = path;
    MediaPlayerChannel.invokeMethod('setDataSource', {'path': path})
        .catchError((error) {
      _stateUpdate(MediaPlayerStatus.error);
      debugPrint('onSetDataSource');
      debugPrint(error.toString());
    });
  }

  static Future<bool> start() async {
    // If start failed, return false
    // If start success, return true
    for (int i = 0; status == MediaPlayerStatus.preparing && i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (status != MediaPlayerStatus.prepared &&
        status != MediaPlayerStatus.started &&
        status != MediaPlayerStatus.paused &&
        status != MediaPlayerStatus.playbackCompleted) {
      debugPrint('current state: ' + status.toString());
      debugPrint('invalid start');
      return false;
    }
    await MediaPlayerChannel.invokeMethod('start').catchError((error) {
      debugPrint('onPlay');
      debugPrint(error.toString());
    });
    return true;
  }

  static void pause() async =>
      MediaPlayerChannel.invokeMethod('pause').catchError((error) {
        debugPrint('onPause');
        debugPrint(error.toString());
      });

  static void stop() async =>
      MediaPlayerChannel.invokeMethod('stop').catchError((error) {
        debugPrint('onStop');
        debugPrint(error.toString());
      });

  static void release() async =>
      MediaPlayerChannel.invokeMethod('release').catchError((error) {
        debugPrint('onRelease');
        debugPrint(error.toString());
      });

  static void reset() async =>
      MediaPlayerChannel.invokeMethod('reset').catchError((error) {
        debugPrint('onReset');
        debugPrint(error.toString());
      });

  static Future<bool> isAvailable() async =>
      await MediaPlayerChannel.invokeMethod('isAvailable');

  static Future<int> getCurrentPosition() async =>
      await MediaPlayerChannel.invokeMethod('getCurrentPosition');

  static Future<int> getDuration() async =>
      await MediaPlayerChannel.invokeMethod('getDuration');

  static void seekTo(int position) async =>
      await MediaPlayerChannel.invokeMethod('seekTo', {'position': position});

  static void setLooping(bool loop) async =>
      await MediaPlayerChannel.invokeMethod('setLooping', {'loop': loop});

  static Future<bool> isLooping() async =>
      await MediaPlayerChannel.invokeMethod('isLooping');

  static final ValueNotifier<double> volumeNotifier = ValueNotifier<double>(0.0)
    ..addListener(() => setVolume(volume));

  static set volume(double value) => volumeNotifier.value = value;

  static double get volume => volumeNotifier.value;

  static void setVolume(double _volume) async =>
      await MediaPlayerChannel.invokeMethod('setVolume', {'volume': _volume});

  static updateNotification(
      String title, String artist, String album, Uint8List artwork) async {
    await MediaPlayerChannel.invokeMethod('updateNotification',
        {'title': title, 'artist': artist, 'album': album, 'artwork': artwork});
  }
}
