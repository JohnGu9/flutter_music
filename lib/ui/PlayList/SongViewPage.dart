import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/plugin/MediaMetadataRetriever.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../../component/CustomPageRoute.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import '../../plugin/MediaPlayer.dart';
import 'BasicViewPage.dart';

pushSongViewPage(BuildContext context, SongInfo songInfo) async {
  Variable.getArtworkAsync(filePath: songInfo.filePath);
  await SchedulerBinding.instance.endOfFrame;
  Future.microtask(
    () => Navigator.push(
      context,
      CustomPageRoute(
        builder: (BuildContext context) => SongViewPage(
          songInfo: songInfo,
        ),
      ),
    ),
  );
}

class SongViewPage extends StatefulWidget {
  const SongViewPage({Key key, @required this.songInfo}) : super(key: key);
  final SongInfo songInfo;

  static pushPage(
      BuildContext context, SongInfo songInfo, Offset startPoint) async {
    Variable.getArtworkAsync(filePath: songInfo.filePath);
    final route = CustomPageRoute(
      builder: (BuildContext context) => SongViewPage(
        songInfo: songInfo,
      ),
      transitionBuilder: CustomPageRoute.clipOvalTransition(startPoint,
          backdropShadow: false),
      transitionDuration: const Duration(milliseconds: 700),
    );
    await SchedulerBinding.instance.endOfFrame;
    Navigator.push(context, route);
  }

  static _SongViewPageState of(BuildContext context) =>
      context.ancestorStateOfType(const TypeMatcher<_SongViewPageState>());

  @override
  _SongViewPageState createState() => _SongViewPageState();
}

class _SongViewPageState extends State<SongViewPage> {
  ScrollController _scrollController;
  Future _quit;

  static const transparent = const AlwaysStoppedAnimation<double>(0.85);

  quit() async {
    _quit ??= _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn);
    if (Navigator.of(context).canPop()) {
      await SchedulerBinding.instance.endOfFrame;
      Navigator.pop(context);
    }
  }

  Widget _builder(BuildContext context, value, Widget child) {
    return AnimatedSwitcher(
      duration: Constants.defaultDuration,
      layoutBuilder: Constants.expendLayoutBuilder,
      child: (value == null)
          ? Constants.emptyArtwork
          : Image(
              key: ValueKey(value),
              image: value,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
    );
  }

  scroll() =>
      _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: Constants.defaultDuration, curve: Curves.fastOutSlowIn);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return BasicViewPage(
      onWillPop: quit,
      child: GeneralPanel(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: Constants.borderRadius,
            color: Theme.of(context)
                .primaryColor
                .withOpacity(Constants.panelOpacity),
          ),
          foregroundDecoration: BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.0),
              Theme.of(context).primaryColor.withOpacity(1.0),
            ],
            stops: const [0.9, 1.0],
          )),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              SliverAppBar(
                pinned: false,
                elevation: 4.0,
                automaticallyImplyLeading: false,
                shape: RoundedRectangleBorder(
                    borderRadius: Constants.borderRadius),
                expandedHeight: MediaQuery.of(context).size.width / 1.2,
                backgroundColor: Theme.of(context).backgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: ValueListenableBuilder(
                    valueListenable:
                        Variable.filePathToImageMap[widget.songInfo.filePath],
                    builder: _builder,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  const Center(child: const Icon(Icons.remove)),
                  ListTile(
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SelectableText(
                        widget.songInfo.title,
                        style: Theme.of(context).textTheme.title,
                      ),
                    ),
                    subtitle: FadeTransition(
                      opacity: transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              const Padding(
                                padding: const EdgeInsets.only(
                                    top: 4.0, right: 8.0, bottom: 3.0),
                                child: const Icon(Icons.person),
                              ),
                              Expanded(
                                child: SelectableText(
                                  widget.songInfo.artist,
                                  style: Theme.of(context).textTheme.body2,
                                  scrollPhysics: NeverScrollableScrollPhysics(),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              const Padding(
                                padding: const EdgeInsets.only(
                                    top: 3.0, right: 8.0, bottom: 4.0),
                                child: const Icon(Icons.album),
                              ),
                              Expanded(
                                child: SelectableText(
                                  widget.songInfo.album,
                                  style: Theme.of(context).textTheme.body2,
                                  scrollPhysics: NeverScrollableScrollPhysics(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: ValueListenableBuilder(
                      valueListenable: Variable.favouriteNotify,
                      builder: (BuildContext context, List list, Widget child) {
                        final bool contains =
                            list.contains(widget.songInfo.filePath);
                        return AnimatedSwitcher(
                          duration: Constants.defaultDuration,
                          child: IconButton(
                            key: ValueKey(contains),
                            icon: Icon(contains
                                ? Icons.favorite
                                : Icons.favorite_border),
                            onPressed: () =>
                                onFavorite(widget.songInfo.filePath),
                          ),
                        );
                      },
                    ),
                  ),
                  FadeTransition(
                    opacity: transparent,
                    child: ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: SelectableText(
                        widget.songInfo.filePath,
                        style: Theme.of(context).textTheme.body2,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          direction: Axis.vertical,
                          children: <Widget>[
                            Text(
                              'Duration: ' +
                                  (int.parse(widget.songInfo.duration) ~/
                                          1000 ~/
                                          60)
                                      .toString() +
                                  ' min ' +
                                  (int.parse(widget.songInfo.duration) ~/
                                          1000 %
                                          60)
                                      .toString() +
                                  ' sec ',
                              style: Theme.of(context).textTheme.body2,
                            ),
                            Text(
                              'File size: ' +
                                  (int.parse(widget.songInfo.fileSize) /
                                          (1024 * 1024))
                                      .toString()
                                      .substring(0, 5) +
                                  'MB',
                              style: Theme.of(context).textTheme.body2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SearchBar(
                    songInfo: widget.songInfo,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: FlatButton(
                            onPressed: () async {
                              MediaPlayer.status = MediaPlayerStatus.started;
                              await Variable.setCurrentSong(
                                Variable.libraryNotify.value,
                                widget.songInfo.filePath,
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                children: <Widget>[
                                  const Divider(),
                                  const Icon(Icons.play_circle_filled),
                                  const Divider(),
                                  AutoSizeText(
                                    'Play',
                                    style: Theme.of(context).textTheme.body2,
                                    maxLines: 1,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FlatButton(
                            onPressed: () =>
                                Variable.shareSong(widget.songInfo),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                children: <Widget>[
                                  const Divider(),
                                  const Icon(Icons.share),
                                  const Divider(),
                                  AutoSizeText(
                                    'Share',
                                    style: Theme.of(context).textTheme.body2,
                                    maxLines: 1,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FlatButton(
                            onPressed: () => FeatureUnsupportedDialog(context),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                children: <Widget>[
                                  const Divider(),
                                  const Icon(Icons.delete),
                                  const Divider(),
                                  AutoSizeText(
                                    'Remove',
                                    style: Theme.of(context).textTheme.body2,
                                    maxLines: 1,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FlatButton(
                            onPressed: quit,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                children: <Widget>[
                                  const Divider(),
                                  const Icon(Icons.cancel),
                                  const Divider(),
                                  AutoSizeText(
                                    'Cancel',
                                    style: Theme.of(context).textTheme.body2,
                                    maxLines: 1,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  const SearchBar({Key key, this.songInfo}) : super(key: key);
  final SongInfo songInfo;

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  TextEditingController _titleController;
  TextEditingController _artistController;
  TextEditingController _albumController;
  ValueNotifier _isSearching;
  AnimationController _controller;

  static const String doc0 =
      'Adjust infomation to get more accurate artwork from network. \nTip: Title and Album should not be empty at the same time. But delete either Title infomation or Album infomation can do fuzzy search. ';

  _onChanged(value) {
    setState(() {
      Variable.remoteImageQuality.value = value;
    });
  }

  Widget _builder(BuildContext context, value, Widget child) {
    if (!Variable.filePathToLocalImageMap
        .containsKey(widget.songInfo.filePath)) {
      return Column(
        children: <Widget>[
          ListTile(
            title: Text(
              'Remote Artwork Search',
              style: Theme.of(context).textTheme.body1,
            ),
            leading: Icon(Icons.cloud_download),
            trailing: child,
            onTap: () => _controller.value == 0.0
                ? _controller.animateTo(1.0, curve: Curves.fastOutSlowIn)
                : _controller.animateBack(0.0, curve: Curves.fastOutSlowIn),
          ),
          SizeTransition(
            axis: Axis.vertical,
            sizeFactor: _controller,
            axisAlignment: 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: <Widget>[
                  FadeTransition(
                    opacity: AlwaysStoppedAnimation(0.7),
                    child: ListTile(
                      title:
                          Text(doc0, style: Theme.of(context).textTheme.body2),
                      trailing: Icon(Icons.question_answer),
                    ),
                  ),
                  const Divider(
                    height: 5,
                  ),
                  ListTile(
                    leading: Icon(Icons.image),
                    title: Text('Quality'),
                    dense: false,
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                          child: RadioListTile<int>(
                              title: Text('Full'),
                              dense: true,
                              value: Variable.highQuality,
                              groupValue: Variable.remoteImageQuality.value,
                              onChanged: _onChanged)),
                      Expanded(
                        child: RadioListTile<int>(
                            title: Text('Mid'),
                            dense: true,
                            value: Variable.middleQuality,
                            groupValue: Variable.remoteImageQuality.value,
                            onChanged: _onChanged),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                            title: Text('Low'),
                            dense: true,
                            value: Variable.lowQuality,
                            groupValue: Variable.remoteImageQuality.value,
                            onChanged: _onChanged),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(Icons.title),
                      ),
                      SizedBox(width: 70, child: Text('Title: ')),
                      Expanded(child: TextField(controller: _titleController)),
                      IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => _titleController.clear())
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(Icons.person),
                      ),
                      SizedBox(width: 70, child: Text('Artist: ')),
                      Expanded(child: TextField(controller: _artistController)),
                      IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => _artistController.clear())
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      const Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(Icons.album),
                      ),
                      SizedBox(width: 70, child: Text('Album: ')),
                      Expanded(child: TextField(controller: _albumController)),
                      IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => _albumController.clear())
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox();
  }

  searchCallback() {
    if (MediaMetadataRetriever.remotePicturePath == widget.songInfo.filePath) {
      MediaMetadataRetriever.getRemotePictureCallback
          .removeListener(searchCallback);
      _isSearching.value = false;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _titleController = TextEditingController(
        text: widget.songInfo.title == Constants.unknown
            ? null
            : widget.songInfo.title);
    _artistController = TextEditingController(
        text: widget.songInfo.artist == Constants.unknown
            ? null
            : widget.songInfo.artist);
    _albumController = TextEditingController(
        text: widget.songInfo.album == Constants.unknown
            ? null
            : widget.songInfo.album);
    _isSearching = ValueNotifier(false);
    _controller =
        AnimationController(vsync: this, duration: Constants.defaultDuration);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _isSearching.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: Variable.filePathToImageMap[widget.songInfo.filePath],
      builder: _builder,
      child: ValueListenableBuilder(
        valueListenable: _isSearching,
        builder: (BuildContext context, value, Widget child) {
          return value
              ? Padding(
                  padding: EdgeInsets.all(15.0),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CircularProgressIndicator(),
                  ),
                )
              : child;
        },
        child: IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            if (_titleController.text.length == 0 &&
                _albumController.text.length == 0) {
              return;
            }
            MediaMetadataRetriever.getRemotePictureCallback
                .addListener(searchCallback);
            _isSearching.value = true;
            MediaMetadataRetriever.getRemotePicture(
              filePath: widget.songInfo.filePath,
              title: _titleController.text,
              artist: _artistController.text,
              album: _albumController.text,
            );
          },
        ),
      ),
    );
  }
}
