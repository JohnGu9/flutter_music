import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/component/CustomPageRoute.dart';
import 'package:flutter_app/component/CustomReorderableList.dart';
import 'package:flutter_app/data/Constants.dart';
import 'package:flutter_app/data/Variable.dart';
import 'package:flutter_app/plugin/MediaPlayer.dart';
import 'package:flutter_app/ui/PlayList/SongTIleArtwork.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../Panel/Panel.dart';

class CurrentPlayListGesture extends StatefulWidget {
  const CurrentPlayListGesture({Key key}) : super(key: key);

  @override
  _CurrentPlayListGestureState createState() => _CurrentPlayListGestureState();
}

class _CurrentPlayListGestureState extends State<CurrentPlayListGesture>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;
  VerticalDragGestureRecognizer _recognizer;

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    _controller.value += _convertToLogical(details.primaryDelta);
  }

  void _handleDragEnd(DragEndDetails details) async {
    assert(mounted);
    final velocity = _convertToLogical(details.primaryVelocity);
    if (velocity > 1) {
      await _controller.fling(velocity: velocity);
      Navigator.of(context).pop();
    } else
      _controller.animateTo(0.0,
          curve: Curves.bounceOut, duration: const Duration(milliseconds: 650));
  }

  void _handleDragCancel() {
    assert(mounted);
    _controller.animateBack(0.0);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _recognizer.addPointer(event);
  }

  double _convertToLogical(double value) => -value / context.size.height;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Constants.defaultDuration);
    _animation = Tween<Offset>(begin: Offset(0, 0), end: Offset(0, -1))
        .animate(_controller);
    _recognizer = VerticalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: SlideTransition(
        position: _animation,
        child: const CurrentPlayList(),
      ),
    );
  }
}

class CurrentPlayList extends StatelessWidget {
  const CurrentPlayList({Key key}) : super(key: key);

  static pushPage(BuildContext context) async {
    await Navigator.of(context).push(CustomPageRoute(
      builder: (BuildContext context) => const CurrentPlayListGesture(),
      transitionBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        Animation<Offset> _animation =
            Tween(begin: const Offset(0, -1), end: const Offset(0, 0)).animate(
                CurvedAnimation(
                    parent: animation, curve: Curves.fastOutSlowIn));
        return SlideTransition(position: _animation, child: child);
      },
    ));
  }

  static const RemainSpaceHeight = hidePanelMiniHeight;

  static Widget _titleBuilder(BuildContext context, currentList, Widget child) {
    final PlayListRegister playListRegister =
        Variable.playListRegisters[currentList];
    return Text(playListRegister.title,
        style: Theme.of(context).textTheme.title);
  }

  List<Widget> _headerSliverBuilder(BuildContext context, bool _) {
    return [
      SliverAppBar(
        floating: true,
        pinned: true,
        elevation: 4.0,
        expandedHeight: 100,
        automaticallyImplyLeading: false,
        actions: const <Widget>[
          const Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.library_music),
          )
        ],
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: EdgeInsets.zero,
          title: const TitleBar(),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // Where the linear gradient begins and ends
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Add one stop for each color. Stops should increase from 0 to 1
                stops: const [0.1, 0.9],
                colors: [
                  // Colors are easy thanks to Flutter's Colors class.
                  Color.alphaBlend(Colors.blueGrey.withOpacity(0.1),
                      Theme.of(context).backgroundColor),
                  Theme.of(context).backgroundColor,
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Theme.of(context).backgroundColor,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      backgroundColor: Colors.transparent,
      body: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height - hidePanelMiniHeight,
            child: Material(
              elevation: 8.0,
              color: Theme.of(context).backgroundColor.withOpacity(0.95),
              borderRadius: FullScreenPanelBackground.borderRadius,
              clipBehavior: Clip.antiAlias,
              child: Container(
                foregroundDecoration: BoxDecoration(
                    borderRadius: FullScreenPanelBackground.borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).backgroundColor.withOpacity(0.0),
                        Theme.of(context).backgroundColor.withOpacity(0.0),
                        Theme.of(context).backgroundColor,
                      ],
                      stops: const [0.0, 0.9, 1.0],
                    )),
                child: NestedScrollView(
                  headerSliverBuilder: _headerSliverBuilder,
                  body: const Content(),
                ),
              ),
            ),
          ),
          Expanded(
            child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop()),
          ),
        ],
      ),
    );
  }
}

class Content extends StatefulWidget {
  const Content({Key key}) : super(key: key);
  static final ValueNotifier<int> page = ValueNotifier(0);

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> {
  PageController _pageController;

  _onPageChanged(int page) => Content.page.value = page;

  _pageChanged() {
    if (_pageController.page.round() != Content.page.value) {
      _pageController.animateToPage(Content.page.value,
          duration: Constants.defaultDuration, curve: Curves.fastOutSlowIn);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pageController = PageController(initialPage: Content.page.value);
    Content.page.addListener(_pageChanged);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Content.page.removeListener(_pageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return PageView(
      physics: const BouncingScrollPhysics(),
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: <Widget>[
        const CurrentPage(),
        const RecentPage(),
      ],
    );
  }
}

class CurrentPage extends StatelessWidget {
  const CurrentPage({Key key}) : super(key: key);

  static void _onItemTap(BuildContext context, SongInfo songInfo) =>
      Variable.setCurrentSong(Variable.currentList.value, songInfo.filePath);

  static Widget _itemBuilder(SongInfo songInfo) => ListItem(
        key: ValueKey(songInfo),
        songInfo: songInfo,
        onTap: _onItemTap,
      );

  static _onReorder(int oldIndex, int newIndex) {
    final PlayListRegister playListRegister =
        Variable.playListRegisters[Variable.currentList.value];
    playListRegister.onReorder(oldIndex, newIndex);
    Variable.currentList.notifyListeners();
  }

  static Widget _builder(BuildContext context, currentList, Widget child) {
    return CustomReorderableListView(
      children: [
        for (final String songPath in currentList)
          _itemBuilder(Variable.filePathToSongMap[songPath]),
      ],
      onReorder: _onReorder,
      end: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
        child: Constants.ListViewEndWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: Variable.currentList,
      builder: _builder,
    );
  }
}

class RecentPage extends StatelessWidget {
  const RecentPage({Key key}) : super(key: key);

  Widget _itemBuilder(BuildContext context, int index) {
    if (index >= Variable.recentLogs.value.length) {
      return null;
    } else {
      final recentLog = Variable.recentLogs.value[index];
      final songInfo = Variable.filePathToSongMap[recentLog.filePath];
      return ListTile(
        title: Text(songInfo.title),
        subtitle: Text(Variable.playListRegisters[recentLog.playList].title),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (Variable.recentLogs.value.isNotEmpty) {
      return ListView.builder(
        itemBuilder: _itemBuilder,
      );
    }
    return Center(
      child: Container(
        child: Text('Recent'),
      ),
    );
  }
}

class TitleBar extends StatelessWidget {
  const TitleBar({Key key}) : super(key: key);

  static Widget _titleBuilder(BuildContext context, currentList, Widget child) {
    final PlayListRegister playListRegister =
        Variable.playListRegisters[currentList];
    return Text(
      playListRegister.title,
      style: playListRegister.title.length < 10
          ? Theme.of(context).textTheme.title
          : Theme.of(context).textTheme.body2,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static const minOpacity = 0.3;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          children: <Widget>[
            const Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0)),
            InkWell(
              onTap: () => Content.page.value = 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 3),
                child: ValueListenableBuilder(
                  valueListenable: Content.page,
                  builder: (BuildContext context, page, Widget child) {
                    bool isCurrent = page == 0;
                    return AnimatedOpacity(
                        opacity: isCurrent ? 1.0 : minOpacity,
                        duration: Constants.defaultDuration,
                        child: child);
                  },
                  child: Padding(
                    padding: Constants.AppBarTitlePadding,
                    child: ValueListenableBuilder(
                      valueListenable: Variable.currentList,
                      builder: _titleBuilder,
                    ),
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () => Content.page.value = 1,
              child: ValueListenableBuilder(
                valueListenable: Content.page,
                builder: (BuildContext context, page, Widget child) {
                  bool isCurrent = page == 1;
                  return AnimatedOpacity(
                      opacity: isCurrent ? 1.0 : minOpacity,
                      duration: Constants.defaultDuration,
                      child: child);
                },
                child: Padding(
                  padding: Constants.AppBarTitlePadding,
                  child:
                      Text('Recent', style: Theme.of(context).textTheme.title),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ignore: must_be_immutable
class ListItem extends StatefulWidget {
  ListItem({Key key, this.songInfo, this.onTap}) : super(key: key);
  final SongInfo songInfo;
  final Function(BuildContext, SongInfo) onTap;
  ValueListenable listenable;

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  Widget _builder(BuildContext context, value, Widget child) {
    final color = value
        ? Theme.of(context).primaryColor
        : Theme.of(context).backgroundColor.withOpacity(0.0);
    return AnimatedContainer(
      duration: Constants.defaultDuration,
      color: color,
      child: ListTile(
        leading: AnimatedPadding(
          duration: Constants.defaultDuration,
          curve: Curves.fastOutSlowIn,
          padding: value ? EdgeInsets.zero : const EdgeInsets.all(2.0),
          child: AnimatedContainer(
            duration: Constants.defaultDuration,
            foregroundDecoration: BoxDecoration(
              color: value ? Colors.transparent : Colors.black38,
              borderRadius: Constants.borderRadius,
            ),
            child: SongTileArtwork(filePath: widget.songInfo.filePath),
          ),
        ),
        title: Text(
          widget.songInfo.title,
          style: Theme.of(context).textTheme.body1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          widget.songInfo.artist == '<unknown>'
              ? widget.songInfo.album
              : widget.songInfo.artist,
          style: Theme.of(context).textTheme.body2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => widget.onTap(context, widget.songInfo),
        trailing: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: MediaPlayer.onPlayAndPause,
            child: AnimatedSwitcher(
              duration: Constants.defaultDuration,
              switchOutCurve: Curves.fastOutSlowIn,
              child: value
                  ? AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: Variable.playButtonController)
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );
  }

  _onValueChange() => setState(() {});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.listenable =
        Variable.filePathToNotifierMap[widget.songInfo.filePath];
    widget.listenable.addListener(_onValueChange);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Constants.defaultDuration);
      await SchedulerBinding.instance.endOfFrame;
      if (widget.listenable.value) {
        final offset =
            Variable.currentList.value.indexOf(widget.songInfo.filePath) /
                Variable.currentList.value.length;
        if (offset > 5 / Variable.currentList.value.length)
          PrimaryScrollController.of(context).animateTo(offset,
              duration: Constants.defaultDuration, curve: Curves.fastOutSlowIn);
      }
    });
  }

  @override
  void didUpdateWidget(ListItem oldWidget) {
    // TODO: implement didUpdateWidget
    if (oldWidget.songInfo != widget.songInfo) {
      oldWidget.listenable.removeListener(_onValueChange);
      widget.listenable.addListener(_onValueChange);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    widget.listenable.removeListener(_onValueChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return _builder(context, widget.listenable.value, null);
  }
}
