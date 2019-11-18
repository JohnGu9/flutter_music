import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/data/CustomImageProvider.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../../component/CustomPageRoute.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import 'BasicViewPage.dart';
import 'SongViewPage.dart';

class AlbumViewPage extends StatefulWidget {
  const AlbumViewPage(
      {Key key, @required this.album, this.albumArtworkProvider})
      : super(key: key);
  final AlbumInfo album;
  final AlbumArtworkProvider albumArtworkProvider;

  /// This page feature certain transition animation
  /// Push router action with fixed animation are integrated in [AlbumViewPage]
  static pushPage(BuildContext context, AlbumInfo albumInfo) async {
    await SchedulerBinding.instance.endOfFrame;
    Future.microtask(
      () => Navigator.push(
        context,
        CustomPageRoute(
          builder: (BuildContext context) => AlbumViewPage(
            album: albumInfo,
            albumArtworkProvider: AlbumArtworkProvider(albumInfo.id),
          ),
        ),
      ),
    );
  }

  @override
  _AlbumViewPageState createState() => _AlbumViewPageState();
}

class _AlbumViewPageState extends State<AlbumViewPage> {
  ScrollController _scrollController;
  String _heroTag;
  Future _quit;

  Widget _listItemBuilder(BuildContext context, int index) {
    if (index >= Variable.albumIdToSongPathsMap[widget.album.id].value.length) {
      return null;
    }
    final String songInfo =
        Variable.albumIdToSongPathsMap[widget.album.id].value[index];
    return ListTile(
      title: AutoSizeText(
        Variable.filePathToSongMap[songInfo].title,
        style: Theme.of(context).textTheme.body1,
        maxLines: 1,
      ),
      trailing: IconButton(
          icon: Icon(Icons.more_horiz),
          onPressed: () =>
              pushSongViewPage(context, Variable.filePathToSongMap[songInfo])),
      onTap: () => Variable.setCurrentSong(
          Variable.albumIdToSongPathsMap[widget.album.id].value, songInfo),
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

  Widget _builder(BuildContext context, value, Widget child) {
    return AnimatedSwitcher(
      duration: Constants.defaultDuration,
      layoutBuilder: Constants.expendLayoutBuilder,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: (value == null)
            ? Constants.emptyArtwork
            : Image(
              key: ValueKey(value),
              height: 200,
              width: 200,
              image: value,
              fit: BoxFit.cover,
            ),
      ),
    );
  }

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return builder(context);
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
            color: Colors.transparent,
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
                    pinned: true,
                    elevation: 4.0,
                    automaticallyImplyLeading: false,
                    shape: const RoundedRectangleBorder(
                        borderRadius: Constants.borderRadius),
                    expandedHeight: MediaQuery.of(context).size.width / 1.15,
                    backgroundColor: Theme.of(context).backgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      background: ValueListenableBuilder(
                        valueListenable: widget.albumArtworkProvider,
                        builder: _builder,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.0)
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      child: ListTile(
                        leading: const Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: const Icon(Icons.album),
                        ),
                        title: SelectableText(
                          widget.album.title,
                          style: Theme.of(context).textTheme.body1,
                        ),
                        subtitle: SelectableText(
                          widget.album.artist,
                          style: Theme.of(context).textTheme.body2,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(_listItemBuilder),
                  ),
                  const SliverToBoxAdapter(
                    child: const Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Constants.ListViewEndWidget,
                    ),
                  ),
                ],
              ),
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
