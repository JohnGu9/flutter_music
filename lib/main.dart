import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import 'data/Constants.dart';
import 'data/Variable.dart';
import 'plugin/ExtendPlugin.dart';
import 'plugin/MediaPlayer.dart';
import 'ui/Panel/Panel.dart';
import 'ui/PlayList/PlayList.dart';

void main() => runApp(const MyApp());

bool _shouldUpdatePreparedListener = true;

mediaPlayerSetup() async {
  Variable.notificationPlayBackSwitch.addListener(() async {
    await MediaPlayer.notificationSwitch(
        Variable.notificationPlayBackSwitch.value);
    if (Variable.notificationPlayBackSwitch.value &&
        Variable.currentItem.value != null) {
      await Variable.getArtworkAsync(filePath: Variable.currentItem.value);
      SongInfo songInfo =
          Variable.filePathToSongMap[Variable.currentItem.value];
      MemoryImage image = Variable.filePathToImageMap[songInfo.filePath].value;
      MediaPlayer.updateNotification(
          songInfo.title, songInfo.artist, songInfo.album, image?.bytes);
    } else {
      MediaPlayer.cancelNotification();
    }
  });

  MediaPlayer.onPlayAndPause = () {
    if (MediaPlayer.status == MediaPlayerStatus.started) {
      MediaPlayer.pause();
    } else {
      MediaPlayer.start();
      final RecentLog recentLog = RecentLog(
          filePath: Variable.currentItem.value,
          playList: Variable.currentList.value);
      if (Variable.recentLogs.value.contains(recentLog)) {
        Variable.recentLogs.value
            .removeAt(Variable.recentLogs.value.indexOf(recentLog));
      }

      Variable.recentLogs.value.insert(0, recentLog);

      if (Variable.recentLogs.value.length > 10)
        Variable.recentLogs.value.removeLast();
      print(Variable.recentLogs.value);
    }
  };

  /// Prevent update currentItem while pageRoute is in transition.
  /// Warning: if update currentItem while pageRoute is in transition, it will cause [Hero] widget break down.
  Variable.pageRouteTransition =
      () async => await MiniPanel.pageRoute.transitionInProgress();

  Variable.beforeSetCurrentSong = () {
    if (_shouldUpdatePreparedListener) {
      MediaPlayer.status == MediaPlayerStatus.started
          ? MediaPlayer.setOnPreparedListener(MediaPlayer.onPlayAndPause)
          : MediaPlayer.removeOnPreparedListener();
    }
  };

  Variable.currentItem.addListener(_currentItemChanged);

  MediaPlayer.setOnStateChangeListener((state, preState) {
    switch (state) {
      case MediaPlayerStatus.started:
        Variable.playButtonController
            .animateTo(1.0, curve: Curves.fastOutSlowIn);
        break;
      case MediaPlayerStatus.preparing:
      case MediaPlayerStatus.prepared:
        // TODO: Handle this case.
        Future.delayed(const Duration(milliseconds: 200), () {
          if (MediaPlayer.status != MediaPlayerStatus.started)
            Variable.playButtonController
                .animateTo(0.0, curve: Curves.fastOutSlowIn);
        });
        break;
      default:
        Variable.playButtonController
            .animateTo(0.0, curve: Curves.fastOutSlowIn);
        break;
    }
  });

  MediaPlayer.setOnCompletionListener(_onCompletionListener);

  MediaPlayer.onPrevious = () {
    debugPrint('onPrevious');
    final list = Variable.currentList;
    final item = Variable.currentItem;
    if (list.value == null ||
        list.value.length <= 1 ||
        item.value == null ||
        !list.value.contains(item.value)) {
      debugPrint('onPrevious failed');
      return;
    }
    int index = list.value.indexOf(item.value) - 1;
    if (index < 0) {
      index = list.value.length - 1;
    }
    Variable.setCurrentSong(list.value, list.value[index]);
  };
  MediaPlayer.onNext = () {
    final list = Variable.currentList;
    final item = Variable.currentItem;
    if (list.value == null ||
        list.value.length <= 1 ||
        item.value == null ||
        !list.value.contains(item.value)) {
      return;
    }
    int index = list.value.indexOf(item.value) + 1;
    if (index >= list.value.length) {
      index = 0;
    }
    Variable.setCurrentSong(list.value, list.value[index]);
  };

  return;
}

_currentItemChanged() async {
  String path = Variable.currentItem.value;
  MediaPlayer.setDataSource(path);
  await Variable.getArtworkAsync(filePath: path);
  SongInfo songInfo = Variable.filePathToSongMap[Variable.currentItem.value];
  MemoryImage image = Variable.filePathToImageMap[songInfo.filePath].value;
  MediaPlayer.updateNotification(
      songInfo.title, songInfo.artist, songInfo.album, image?.bytes);
}

_onCompletionListener() async {
  final state = Variable.playListSequence.getState();
  if (state == PlayListSequenceStatus.shuffle) {
    final list = Variable.currentList;
    final item = Variable.currentItem;
    if (list.value == null ||
        list.value.length == 0 ||
        item.value == null ||
        !list.value.contains(item.value)) {
      return;
    }
    if (list.value.length == 1) {
      MediaPlayer.start();
    } else {
      _shouldUpdatePreparedListener = false;
      MediaPlayer.setOnPreparedListener(MediaPlayer.start);
      Random _random = Random();
      int _randomNum;

      int _currentIndex = list.value.indexOf(item.value);
      do {
        _randomNum = _random.nextInt(list.value.length - 1);
      } while (_randomNum == _currentIndex);
      await Variable.setCurrentSong(list.value, list.value[_randomNum]);
      _shouldUpdatePreparedListener = true;
    }
  } else if (state == PlayListSequenceStatus.repeat_one) {
    MediaPlayer.start();
  } else {
    // skipNext

    final list = Variable.currentList;
    final item = Variable.currentItem;
    if (list.value == null ||
        list.value.length == 0 ||
        item.value == null ||
        !list.value.contains(item.value)) {
      return;
    }

    if (list.value.length == 1) {
      MediaPlayer.start();
    } else {
      int index = list.value.indexOf(item.value) + 1;
      _shouldUpdatePreparedListener = false;
      MediaPlayer.setOnPreparedListener(MediaPlayer.start);
      if (index >= list.value.length) {
        index = 0;
      }
      await Variable.setCurrentSong(list.value, list.value[index]);
      _shouldUpdatePreparedListener = true;
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  ThemeData light;
  ThemeData dark;

  _onChangeTheme() => setState(_changeTheme);

  _changeTheme() {
    if (Variable.themeSwitch.value == Variable.lightTheme) {
      light = Constants.customLightTheme;
      dark = null;
    } else if (Variable.themeSwitch.value == Variable.darkTheme) {
      light = Constants.customDarkTheme;
      dark = null;
    } else {
      light = Constants.customLightTheme;
      dark = Constants.customDarkTheme;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Variable.mediaPlayerInitialization ??= mediaPlayerSetup();
    Variable.playButtonController =
        AnimationController(vsync: this, duration: Constants.defaultDuration);
    _changeTheme();
    Variable.themeSwitch.addListener(_onChangeTheme);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Variable.playButtonController.dispose();
    Variable.themeSwitch.removeListener(_onChangeTheme);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.MaterialAppTitle,
      theme: light,
      darkTheme: dark,
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    systemSetup(context);
    return WillPopScope(
      onWillPop: () async {
        ExtendPlugin.moveTaskToBack();
        return false;
      },
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: Stack(
          children: const <Widget>[
            const PlayList(),
            const MiniPanel(),
          ],
        ),
      ),
    );
  }
}
