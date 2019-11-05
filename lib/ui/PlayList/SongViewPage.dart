import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../component/TransparentPageRoute.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import '../../plugin/MediaPlayer.dart';

pushSongViewPage(BuildContext context, SongInfo songInfo) async {
  await Variable.getArtworkAsync(path: songInfo.filePath);
  await SchedulerBinding.instance.endOfFrame;
  Future.microtask(
    () => Navigator.push(
      context,
      TransparentRoute(
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

  @override
  _SongViewPageState createState() => _SongViewPageState();
}

class _SongViewPageState extends State<SongViewPage> {
  ScrollController _scrollController;
  ImageProvider _image;
  String tag;
  Future _quit;

  quit() async {
    _quit ??= _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn);
    await _quit;
    if (Navigator.of(context).canPop()) {
      await SchedulerBinding.instance.endOfFrame;
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController = ScrollController();
    Future.delayed(
        TransparentRouteTransitionDuration,
        () => _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Constants.defaultDuration,
            curve: Curves.fastOutSlowIn));
    tag = widget.songInfo.hashCode.toString() + 'song';
    _image = Variable.filePathToImageMap[widget.songInfo.filePath].value;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _scrollController.dispose();
  }

  Widget built;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return built ??= WillPopScope(
      onWillPop: () async {
        await quit();
        return false;
      },
      child: Container(
        color: Colors.black38,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: Constants.borderRadius,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Hero(
                          tag: tag,
                          transitionOnUserGestures: true,
                          flightShuttleBuilder: Constants
                              .targetAndSourceFadeInOutFlightShuttleBuilder,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: Constants.borderRadius,
                            color: Theme.of(context)
                                .backgroundColor
                                .withOpacity(Constants.panelOpacity),
                            child: CustomScrollView(
                              controller: _scrollController,
                              slivers: <Widget>[
                                SliverAppBar(
                                  pinned: true,
                                  elevation: 4.0,
                                  automaticallyImplyLeading: false,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: Constants.borderRadius),
                                  expandedHeight:
                                      MediaQuery.of(context).size.width / 1.2,
                                  backgroundColor:
                                      Theme.of(context).backgroundColor,
                                  flexibleSpace: FlexibleSpaceBar(
                                    centerTitle: true,
                                    background: (_image == null)
                                        ? Constants.emptyArtwork
                                        : Image(
                                            image: _image,
                                            fit: BoxFit.fitWidth,
                                            alignment: Alignment.topCenter,
                                          ),
                                  ),
                                ),
                                SliverList(
                                  delegate: SliverChildListDelegate([
                                    const Center(
                                        child: const Icon(Icons.remove)),
                                    ListTile(
                                      title: AutoSizeText(
                                        widget.songInfo.title,
                                        style:
                                            Theme.of(context).textTheme.title,
                                        maxLines: 1,
                                      ),
                                      subtitle: Wrap(
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            widget.songInfo.artist,
                                            style: Theme.of(context)
                                                .textTheme
                                                .body1,
                                            maxLines: 1,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            widget.songInfo.album,
                                            style: Theme.of(context)
                                                .textTheme
                                                .body2,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                      trailing: ValueListenableBuilder(
                                        valueListenable: Variable.favouriteNotify,
                                        builder: (BuildContext context,
                                            List list, Widget child) {
                                          final bool contains =
                                              list.contains(widget.songInfo.filePath);
//                                           debugPrint('contains:'+contains.toString());
                                          return AnimatedSwitcher(
                                            duration:
                                                Constants.defaultDuration,
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
                                    ListTile(
                                      leading:
                                          const Icon(Icons.insert_drive_file),
                                      title: AutoSizeText(
                                        widget.songInfo.filePath,
                                        style:
                                            Theme.of(context).textTheme.body2,
                                        maxLines: 2,
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Wrap(
                                          direction: Axis.vertical,
                                          children: <Widget>[
                                            Text(
                                              'Duration: ' +
                                                  (int.parse(widget.songInfo
                                                              .duration) ~/
                                                          1000 ~/
                                                          60)
                                                      .toString() +
                                                  ' min ' +
                                                  (int.parse(widget.songInfo
                                                              .duration) ~/
                                                          1000 %
                                                          60)
                                                      .toString() +
                                                  ' sec ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2,
                                            ),
                                            Text(
                                              'File size: ' +
                                                  (int.parse(widget.songInfo
                                                              .fileSize) /
                                                          (1024 * 1024))
                                                      .toString()
                                                      .substring(0, 5) +
                                                  'MB',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .body2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: FlatButton(
                                              onPressed: () async {
                                                MediaPlayer.status =
                                                    MediaPlayerStatus.started;
                                                await Variable.setCurrentSong(
                                                  Variable.libraryNotify.value,
                                                  widget.songInfo.filePath,
                                                );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Column(
                                                  children: <Widget>[
                                                    const Divider(),
                                                    const Icon(Icons
                                                        .play_circle_filled),
                                                    const Divider(),
                                                    AutoSizeText(
                                                      'Play',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .body2,
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
                                                  Variable.shareSong(
                                                      widget.songInfo),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Column(
                                                  children: <Widget>[
                                                    const Divider(),
                                                    const Icon(Icons.share),
                                                    const Divider(),
                                                    AutoSizeText(
                                                      'Share',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .body2,
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
                                                  FeatureUnsupportedDialog(
                                                      context),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Column(
                                                  children: <Widget>[
                                                    const Divider(),
                                                    const Icon(Icons.delete),
                                                    const Divider(),
                                                    AutoSizeText(
                                                      'Remove',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .body2,
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
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Column(
                                                  children: <Widget>[
                                                    const Divider(),
                                                    const Icon(Icons.cancel),
                                                    const Divider(),
                                                    AutoSizeText(
                                                      'Cancel',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .body2,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: quit,
              child: Container(
                height: Constants.miniPanelHeight,
                color: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
