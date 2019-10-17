import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'plugin/AndroidPlugin.dart';
import 'plugin/MediaPlayer.dart';

import 'data/Constants.dart';
import 'data/Variable.dart';
import 'ui/Panel/Panel.dart';
import 'ui/PlayList/PlayList.dart';

void main() {
  Variable.mediaPlayerLoading ??= mediaPlayerSetup();
  runApp(const MyApp());
}

bool _shouldUpdatePreparedListener = true;

mediaPlayerSetup() async {
  MediaPlayer.setOnStateChangeListener((state, preState) {
    state == MediaPlayerStatus.started
        ? Variable.playButtonController
            .animateTo(1.0, curve: Curves.fastOutSlowIn)
        : Variable.playButtonController
            .animateTo(0.0, curve: Curves.fastOutSlowIn);
  });

  final _currentItemChanged = () async {
    if (_shouldUpdatePreparedListener) {
      MediaPlayer.status == MediaPlayerStatus.started
          ? MediaPlayer.setOnPreparedListener(MediaPlayer.start)
          : MediaPlayer.removeOnPreparedListener();
    }
    MediaPlayer.setDataSource(Variable.currentItem.value?.filePath);
  };
  Variable.currentItem.addListener(_currentItemChanged);

  final _onCompletionListener = () {
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
        item.value = list.value[_randomNum];
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
        item.value = list.value[index];
        _shouldUpdatePreparedListener = true;
      }
    }
  };

  MediaPlayer.setOnCompletionListener(_onCompletionListener);

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
    SchedulerBinding.instance
        .scheduleTask(() => systemSetup(context), Priority.idle);
    return WillPopScope(
      onWillPop: () async {
        AndroidPlugin.moveTaskToBack();
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
