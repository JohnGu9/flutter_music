import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../component/TransparentPageRoute.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import 'BasicViewPage.dart';

import 'SongViewPage.dart';

pushAlbumViewPage(BuildContext context, AlbumInfo albumInfo,
    ImageProvider imageProvider) async {
  await SchedulerBinding.instance.endOfFrame;
  Future.microtask(
    () => Navigator.push(
      context,
      TransparentRoute(
        builder: (BuildContext context) => AlbumViewPage(
          album: albumInfo,
          image: imageProvider,
        ),
      ),
    ),
  );
}

class AlbumViewPage extends StatefulWidget {
  const AlbumViewPage({Key key, @required this.album, this.image})
      : super(key: key);
  final AlbumInfo album;
  final ImageProvider image;

  @override
  _AlbumViewPageState createState() => _AlbumViewPageState();
}

class _AlbumViewPageState extends State<AlbumViewPage> {
  ScrollController _scrollController;
  String _heroTag;
  Future _quit;

  Widget _listItemBuilder(BuildContext context, int index) {
    if (index >= Variable.albumIdToSongsMap[widget.album.id].length) {
      return null;
    }
    final SongInfo songInfo =
        Variable.albumIdToSongsMap[widget.album.id][index];
    return ListTile(
      title: AutoSizeText(
        songInfo.title,
        style: Theme.of(context).textTheme.body1,
        maxLines: 1,
      ),
      trailing: IconButton(
          icon: Icon(Icons.more_horiz),
          onPressed: () => pushSongViewPage(context, songInfo)),
      onTap: () => Variable.setCurrentSong(
          Variable.albumIdToSongsMap[widget.album.id], songInfo),
    );
  }

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

  Widget built;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scrollController = ScrollController();
    _heroTag = widget.album.hashCode.toString() + 'album';
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    built ??= builder(context);
    return built;
  }

  Widget builder(BuildContext context) {
    return BasicViewPage(
      onWillPop: quit,
      child: GeneralPanel(
        child: Hero(
          tag: _heroTag,
          flightShuttleBuilder:
              Constants.targetAndSourceFadeInOutFlightShuttleBuilder,
          child: Material(
            elevation: 0.0,
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
                  shape: const RoundedRectangleBorder(
                      borderRadius: Constants.borderRadius),
                  expandedHeight: MediaQuery.of(context).size.width / 1.15,
                  backgroundColor: Theme.of(context).backgroundColor,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 100.0),
                      child: AutoSizeText(
                        widget.album.title,
                        style: Constants.textStyleWithShadow(
                          Theme.of(context).textTheme.body1,
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : Colors.black,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    background: (widget.image == null)
                        ? Constants.emptyArtwork
                        : Image(
                            image: widget.image,
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topCenter,
                          ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(_listItemBuilder),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DecorationBar extends StatelessWidget implements PreferredSizeWidget {
  static const double height = 60;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // Where the linear gradient begins and ends
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Add one stop for each color. Stops should increase from 0 to 1
          stops: [0.0, 1.0],
          colors: Theme.of(context).brightness == Brightness.light
              ? [
                  // Colors are easy thanks to Flutter's Colors class.
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.5),
                ]
              : [
                  // Colors are easy thanks to Flutter's Colors class.
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.6),
                ],
        ),
      ),
    );
  }
}
