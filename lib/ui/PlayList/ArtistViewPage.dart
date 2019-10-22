import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../component/TransparentPageRoute.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import 'BasicViewPage.dart';

import 'AlbumViewPage.dart';
import 'SongTIleArtwork.dart';
import 'SongViewPage.dart';
import 'AlbumViewItem.dart';

pushArtistViewPage(BuildContext context, ArtistInfo artistInfo) async {
  await SchedulerBinding.instance.endOfFrame;
  Future.microtask(
        () =>
        Navigator.push(
          context,
          TransparentRoute(
            builder: (BuildContext context) =>
                ArtistViewPage(
                  artist: artistInfo,
                ),
          ),
        ),
  );
}

class ArtistViewPage extends StatefulWidget {
  const ArtistViewPage({Key key, this.artist}) : super(key: key);
  final ArtistInfo artist;

  @override
  _ArtistViewPageState createState() => _ArtistViewPageState();
}

class _ArtistViewPageState extends State<ArtistViewPage> {
  List<AlbumInfo> albums;
  Map<AlbumInfo, ImageProvider> imagesMap;
  ScrollController _scrollController;
  PageController _pageController;
  ValueNotifier<int> _currentPage;
  Future _quit;
  bool _dirty;

  Widget _sliverAppBar;
  Widget _sliverPersistentHeader;

  List<Widget> _headerSliverBuilder(BuildContext context, _) {
    _sliverAppBar ??= SliverAppBar(
      floating: false,
      pinned: true,
      elevation: 4.0,
      automaticallyImplyLeading: false,
      expandedHeight: MediaQuery
          .of(context)
          .size
          .width / 1.2,
      backgroundColor: Theme
          .of(context)
          .backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        centerTitle: true,
        title: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width/2),
          child: AutoSizeText(
            widget.artist.name,
            style: Constants.textStyleWithShadow(
              Theme
                  .of(context)
                  .textTheme
                  .body1,
              Theme
                  .of(context)
                  .brightness == Brightness.light
                  ? Colors.white
                  : Colors.black,
            ),
            maxLines: 1,
          ),
        ),
        background: Constants.emptyPersonPicture,
      ),
    );
    _sliverPersistentHeader ??= SliverPersistentHeader(
      floating: true,
      pinned: true,
      delegate: _SliverPersistentHeaderDelegate(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ValueListenableBuilder(
            valueListenable: _currentPage,
            builder: _valueListenableBuilder,
          ),
        ),
      ),
    );
    return [
      _sliverAppBar,
      _sliverPersistentHeader,
    ];
  }

  Widget _valueListenableBuilder(BuildContext context, int page, Widget child) {
    Color color = Theme
        .of(context)
        .brightness == Brightness.light
        ? Constants.darkGrey
        : Constants.lightGrey;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedContainer(
          duration: Constants.defaultDuration,
          height: 5,
          width: 5,
          color: page == 0 ? color : color.withOpacity(0.3),
        ),
        const VerticalDivider(),
        AnimatedContainer(
          duration: Constants.defaultDuration,
          height: 5,
          width: 5,
          color: page == 1 ? color : color.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _itemBuilder(BuildContext context, int index) {
    if (index >= Variable.artistIdToSongsMap[widget.artist.id].length) {
      return null;
    }
    final SongInfo songInfo =
    Variable.artistIdToSongsMap[widget.artist.id][index];
    return ListTile(
      leading: SongTileArtwork(
        songInfo: songInfo,
      ),
      title: AutoSizeText(
        songInfo.title,
        style: Theme
            .of(context)
            .textTheme
            .body1,
        maxLines: 1,
      ),
      subtitle: AutoSizeText(
        songInfo.album,
        style: Theme
            .of(context)
            .textTheme
            .body2,
        maxLines: 1,
      ),
      trailing: IconButton(
          icon: Icon(Icons.more_horiz),
          onPressed: () => pushSongViewPage(context, songInfo)),
      onTap: () =>
          Variable.setCurrentSong(
              Variable.artistIdToSongsMap[widget.artist.id], songInfo),
    );
  }

  Widget _gridItemBuilder(BuildContext context, int index) {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: Constants.borderRadius,
      ),
      color: Theme
          .of(context)
          .primaryColor,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          imagesMap[albums[index]] == null
              ? Constants.emptyArtwork
              : Image(
            image: imagesMap[albums[index]],
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
          ForegroundView(album: albums[index], onTap: () =>
            pushAlbumViewPage(context, albums[index], imagesMap[albums[index]])
          ,),
        ],
      ),
    );
  }

  _loadAlbum() async {
    Variable.albumToSongsMapLoading ??= Variable.generalMapAlbumToSongs();
    await Variable.albumToSongsMapLoading;
    albums =
    await Variable.audioQuery.getAlbumsFromArtist(artist: widget.artist);
    imagesMap = Map();
    for (int i = 0; i < albums.length;) {
      await SchedulerBinding.instance.endOfFrame;
      final songs = Variable.albumIdToSongsMap[albums[i].id];
      if (songs == null) {
        albums.removeAt(i);
      } else {
        imagesMap[albums[i]] = await Variable.getImageFromSongs(songs);
        i++;
      }
    }
    for (final AlbumInfo albumInfo in albums) {
      await SchedulerBinding.instance.endOfFrame;
      final songs = Variable.albumIdToSongsMap[albumInfo.id];
      // load first available image
      imagesMap[albumInfo] =
      songs == null ? null : await Variable.getImageFromSongs(songs);
    }
    setState(() => _dirty = true);
  }

  quit() async {
    _quit ??= Future.wait([
      _scrollController.animateTo(_scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn),
      _pageController.animateToPage(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn)
    ]);
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
    _pageController = PageController();
    _currentPage = ValueNotifier(0);
    _dirty = false;
    _loadAlbum();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    Future.delayed(TransparentRouteTransitionDuration, _currentPage.dispose);
  }

  Widget built;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (_dirty) {
      built = builder(context);
    } else {
      built ??= builder(context);
    }
    return built;
  }

  Widget builder(BuildContext context) {
    return BasicViewPage(
      onWillPop: quit,
      child: GeneralPanel(
        child: Hero(
          tag: widget.artist.hashCode.toString() + 'artist',
          flightShuttleBuilder: Constants
              .targetAndSourceFadeInOutFlightShuttleBuilder,
          child: Material(
            elevation: 0.0,
            borderRadius: Constants.borderRadius,
            color: Theme
                .of(context)
                .backgroundColor
                .withOpacity(Constants.panelOpacity),
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: _headerSliverBuilder,
              body: PageView(
                controller: _pageController,
                onPageChanged: (int page) =>
                _currentPage.value = page,
                children: <Widget>[
                  ListView.builder(
                    itemBuilder: _itemBuilder,
                  ),
                  GridView.builder(
                    gridDelegate: Constants.gridDelegate,
                    itemBuilder: _gridItemBuilder,
                    itemCount: albums?.length ?? 0,
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

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverPersistentHeaderDelegate(this.child);

  @override
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) {
    return Material(
        color: Theme
            .of(context)
            .backgroundColor,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Constants.radius, bottomRight: Constants.radius)),
        child: child);
  }

  @override
  double get maxExtent => 20;

  @override
  double get minExtent => 0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
