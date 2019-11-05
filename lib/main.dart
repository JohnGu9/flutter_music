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

void main() async {
  Variable.mediaPlayerInitialization = mediaPlayerSetup();
  runApp(const MyApp());
}

bool _shouldUpdatePreparedListener = true;

mediaPlayerSetup() async {
  /// Prevent update currentItem while pageRoute is in transition.
  /// Warning: if update currentItem while pageRoute is in transition, it will cause [Hero] widget break down.
  Variable.pageRouteTransition =
      () async => await MiniPanel.pageRoute.transitionInProgress();

  Variable.beforeSetCurrentSong = () {
    if (_shouldUpdatePreparedListener) {
      MediaPlayer.status == MediaPlayerStatus.started
          ? MediaPlayer.setOnPreparedListener(MediaPlayer.start)
          : MediaPlayer.removeOnPreparedListener();
    }
  };

  Variable.currentItem.addListener(_currentItemChanged);

  MediaPlayer.setOnStateChangeListener((state, preState) {
    state == MediaPlayerStatus.started
        ? Variable.playButtonController
            .animateTo(1.0, curve: Curves.fastOutSlowIn)
        : Variable.playButtonController
            .animateTo(0.0, curve: Curves.fastOutSlowIn);
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
  await Variable.getArtworkAsync(path: path);
  SongInfo songInfo = Variable.filePathToSongMap[path];
  MemoryImage image = Variable.filePathToImageMap[path].value;
  await MediaPlayer.updateNotification(
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Variable.playButtonController =
        AnimationController(vsync: this, duration: Constants.defaultDuration);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Variable.playButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.MaterialAppTitle,
      theme: Constants.customLightTheme,
      darkTheme: Constants.customDarkTheme,
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
