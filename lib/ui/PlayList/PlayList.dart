import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../../component/AnimatedPopUpWidget.dart';
import '../../component/CustomReorderableList.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import '../../plugin/MediaPlayer.dart';
import 'AlbumViewItem.dart';
import 'ArtistViewItem.dart';
import 'SongTIleArtwork.dart';
import 'SongViewPage.dart';

_menuButtonSheet(BuildContext context, SongInfo songInfo) {
  // cache widget
  final built = _menuButtonSheetBuilder(context, songInfo);
  Future.microtask(() => showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: const BorderRadius.only(
                topLeft: Constants.radius, topRight: Constants.radius)),
        context: context,
        builder: (BuildContext context) => built,
      ));
}

_menuButtonSheetBuilder(BuildContext context, SongInfo songInfo) {
  return Material(
    color: Theme.of(context).backgroundColor,
    borderRadius: Constants.borderRadius,
    child: Wrap(
      children: <Widget>[
        const Center(child: const Icon(Icons.remove)),
        // Info
        ListTile(
          title: AutoSizeText(
            songInfo.title,
            style: Theme.of(context).textTheme.title,
            maxLines: 1,
          ),
          subtitle: Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: <Widget>[
              Text(
                songInfo.artist,
                style: Theme.of(context).textTheme.body1,
                maxLines: 1,
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                songInfo.album,
                style: Theme.of(context).textTheme.body2,
                maxLines: 1,
              ),
            ],
          ),
          trailing: ValueListenableBuilder(
              valueListenable: Variable.favouriteList,
              builder: (BuildContext context, List list, Widget child) {
                final bool contains = list.contains(songInfo);
                // debugPrint('contains:'+contains.toString());
                final built = AnimatedSwitcher(
                  duration: Constants.defaultShortDuration,
                  child: IconButton(
                    key: ValueKey(contains),
                    icon:
                        Icon(contains ? Icons.favorite : Icons.favorite_border),
                    onPressed: () => onFavorite(songInfo),
                  ),
                );
                return built;
              }),
        ),
        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: AutoSizeText(
            songInfo.filePath,
            style: Theme.of(context).textTheme.body2,
            maxLines: 2,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              direction: Axis.vertical,
              children: <Widget>[
                Text(
                  'Duration: ' +
                      (int.parse(songInfo.duration) ~/ 1000 ~/ 60).toString() +
                      ' min ' +
                      (int.parse(songInfo.duration) ~/ 1000 % 60).toString() +
                      ' sec ',
                  style: Theme.of(context).textTheme.body2,
                ),
                Text(
                  'File size: ' +
                      (int.parse(songInfo.fileSize) / (1024 * 1024))
                          .toString()
                          .substring(0, 5) +
                      'MB',
                  style: Theme.of(context).textTheme.body2,
                ),
              ],
            ),
          ),
        ),

        // actions
        ListTile(
          leading: const Icon(Icons.share),
          title: const Text('Share'),
          onTap: () => Variable.shareSong(songInfo),
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: const Text('Remove'),
          onTap: () => FeatureUnsupportedDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.cancel),
          title: const Text('Cancel'),
          onTap: () => Navigator.of(context).pop(),
        ),
        const Divider(),
      ],
    ),
  );
}

class PlayList extends StatefulWidget {
  const PlayList({Key key}) : super(key: key);

  @override
  _PlayListState createState() => _PlayListState();
}

class _PlayListState extends State<PlayList>
    with SingleTickerProviderStateMixin {
  static _load() async {
    // wait for MediaPlayer Loaded
    while (Variable.mediaPlayerLoading == null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Variable.mediaPlayerLoading;

    // Start Load PlayList
    final defaultListNotifier = Variable.defaultList;
    final favoriteListNotifier = Variable.favouriteList;
    if (defaultListNotifier.value != null ||
        favoriteListNotifier.value != null) {
      return;
    }
    final audioQuery = Variable.audioQuery;
    defaultListNotifier.value = await audioQuery.getSongs();
    favoriteListNotifier.value = List();
    defaultListNotifier.value.forEach((SongInfo songInfo) {
      Variable.filePathToSongMap[songInfo.filePath] = songInfo;
    });
    MediaPlayer.volume = 0.5;
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
      item.value = list.value[index];
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
      item.value = list.value[index];
    };
    await Future.delayed(const Duration(milliseconds: 100));
    Variable.panelAntiBlock.value = false;
  }

  Widget _sliverPersistentHeader;

  List<Widget> _nestedAppBarBuilder(BuildContext context, _) {
    _sliverPersistentHeader ??= SliverPersistentHeader(
      floating: false,
      pinned: true,
      delegate: _SliverPersistentHeaderDelegate(
        TabBar(
          controller: Variable.tabController,
          indicatorColor: Theme.of(context).indicatorColor,
          tabs: const <Tab>[
            const Tab(
              icon: const Icon(Icons.person),
            ),
            const Tab(
              icon: const Icon(Icons.album),
            ),
            const Tab(
              icon: const Icon(Icons.view_list),
            ),
            const Tab(
              icon: const Icon(Icons.favorite),
            ),
          ],
        ),
      ),
    );
    return [
      SliverAppBar(
        floating: true,
        pinned: false,
        elevation: 0.0,
        expandedHeight: 100,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.trip_origin),
            onPressed: () => _test(context),
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: EdgeInsets.zero,
          title: Row(
            children: <Widget>[
              //const Icon(Icons.brightness_1),
              const Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0)),
              Text('Music', style: Theme.of(context).textTheme.title),
            ],
          ),
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // Where the linear gradient begins and ends
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Add one stop for each color. Stops should increase from 0 to 1
                stops: [0.1, 0.9],
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
        backgroundColor: Theme.of(context).backgroundColor.withOpacity(0.9),
      ),
      _sliverPersistentHeader,
    ];
  }

  void _test(BuildContext context) {
    Variable.innerScrollController?.animateTo(
        Variable.innerScrollController.position.maxScrollExtent,
        duration: Constants.defaultDuration,
        curve: Curves.fastOutSlowIn);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Variable.outerScrollController = ScrollController();
    Variable.tabController =
        TabController(vsync: this, length: 4, initialIndex: 2);
    Variable.playListLoading ??= _load();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    Variable.tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    systemSetup(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        controller: Variable.outerScrollController,
        headerSliverBuilder: _nestedAppBarBuilder,
        body: const MainTabView(),
      ),
    );
  }
}

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverPersistentHeaderDelegate(this._tabBar);

  Widget _valueListenableBuilder(
      BuildContext context, bool isIgnore, Widget child) {
    return IgnorePointer(
      ignoring: isIgnore,
      child: child,
    );
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ValueListenableBuilder(
      valueListenable: Variable.panelAntiBlock,
      builder: _valueListenableBuilder,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Material(
              color: Theme.of(context)
                  .backgroundColor
                  .withOpacity(Constants.panelOpacity),
              child: SafeArea(
                top: true,
                bottom: false,
                child: _tabBar,
              )),
        ),
      ),
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height + 20;

  @override
  double get minExtent => _tabBar.preferredSize.height + 20;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class MainTabView extends StatelessWidget {
  const MainTabView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    // catch the innerScrollController from NestScrollView
    Variable.innerScrollController = PrimaryScrollController.of(context);
    return RepaintBoundary(
      child: TabBarView(
        controller: Variable.tabController,
        children: const [
          const ArtistList(
            key: PageStorageKey('ArtistList'),
          ),
          const AlbumList(
            key: PageStorageKey('AlbumList'),
          ),
          const DefaultList(
            key: PageStorageKey('DefaultList'),
          ),
          const FavouriteList(
            key: PageStorageKey('FavouriteList'),
          ),
        ],
      ),
    );
  }
}

class FavouriteList extends StatefulWidget {
  const FavouriteList({Key key}) : super(key: key);

  @override
  _FavouriteListState createState() => _FavouriteListState();
}

class _FavouriteListState extends State<FavouriteList> {
  @override
  Widget build(BuildContext context) =>
      // TODO: implement build
      ValueListenableBuilder(
        valueListenable: Variable.favouriteList,
        builder: (BuildContext context, List list, Widget child) {
          return (list == null) ? child : FavoriteListBuilder(list: list);
        },
        child: const Center(
          child: const CircularProgressIndicator(),
        ),
      );
}

class FavoriteListBuilder extends StatefulWidget {
  const FavoriteListBuilder({Key key, this.list}) : super(key: key);
  final List list;

  @override
  _FavoriteListBuilderState createState() => _FavoriteListBuilderState();
}

class _FavoriteListBuilderState extends State<FavoriteListBuilder> {
  static void _onItemTap(BuildContext context, SongInfo songInfo) =>
      Variable.setCurrentSong(Variable.favouriteList.value, songInfo);

  static Widget _itemBuilder(BuildContext context, SongInfo songInfo) {
    return ListTile(
      key: ValueKey(songInfo),
      leading: SongTileArtwork(
        songInfo: songInfo,
      ),
      title: AutoSizeText(
        songInfo.title,
        style: Theme.of(context).textTheme.body1,
        maxLines: 1,
      ),
      subtitle: AutoSizeText(
        songInfo.artist == '<unknown>' ? songInfo.album : songInfo.artist,
        style: Theme.of(context).textTheme.body2,
        maxLines: 1,
      ),
      onTap: () => _onItemTap(context, songInfo),
      trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => pushSongViewPage(context, songInfo)),
    );
  }

  _onReorder(int oldIndex, int newIndex) {
    final list = Variable.favouriteList.value;
    if (oldIndex < newIndex) {
      list.insert(newIndex, list[oldIndex]);
      list.removeAt(oldIndex);
    } else {
      var song = list.removeAt(oldIndex);
      list.insert(newIndex, song);
    }
    // sync currentListNotifier
    Variable.favouriteList.notifyListeners();
    if (list == Variable.currentList.value) {
      Variable.currentList.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) =>
      // TODO: implement build
      CustomReorderableListView(
        header: widget.list.length == 0 ? null : FavouriteListHeader(),
        end: widget.list.length == 0
            ? const Padding(
                padding: const EdgeInsets.only(top: 120.0, bottom: 120.0),
                child: Center(child: FadeInWidget(child: Icon(Icons.search))),
              )
            : const Padding(
                padding: const EdgeInsets.only(bottom: 120.0),
                child: Center(child: Icon(Icons.filter_list)),
              ),
        onDragStart: () => Variable.panelAntiBlock.value = true,
        onDragEnd: () => Variable.panelAntiBlock.value = false,
        children: <Widget>[
          for (final songInfo in widget.list) _itemBuilder(context, songInfo),
        ],
        onReorder: _onReorder,
      );
}

class FavouriteListHeader extends StatelessWidget {
  const FavouriteListHeader({Key key}) : super(key: key);

  _play(int playListSequenceStatus) async {
    Variable.playListSequence.state = playListSequenceStatus;
    if (Variable.currentList.value == Variable.favouriteList.value) {
      if (MediaPlayer.status != MediaPlayerStatus.started) {
        MediaPlayer.start();
      }
    } else {
      final int index =
          playListSequenceStatus == PlayListSequenceStatus.shuffle.index
              ? Random().nextInt(Variable.favouriteList.value.length - 1)
              : 0;
      MediaPlayer.status = MediaPlayerStatus.started;
      Variable.setCurrentSong(
          Variable.favouriteList.value, Variable.favouriteList.value[index]);
    }
  }

  _playRepeat() async => _play(PlayListSequenceStatus.repeat.index);

  _playShuffle() async => _play(PlayListSequenceStatus.shuffle.index);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        FadeInWidget(
          delay: const Duration(milliseconds: 300),
          duration: Constants.defaultLongDuration,
          child: ListTile(
            leading: Text(
              'Favorite',
              style: Theme.of(context).textTheme.body1,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.play_circle_filled),
                  onPressed: _playRepeat,
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  onPressed: _playShuffle,
                ),
              ],
            ),
          ),
        ),
        const Divider(
          color: Colors.black12,
        ),
      ],
    );
  }
}

class DefaultList extends StatelessWidget {
  const DefaultList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      // TODO: implement build
      ValueListenableBuilder(
        valueListenable: Variable.defaultList,
        builder: (BuildContext context, List list, Widget child) {
          return (list == null) ? child : DefaultListBuilder(list: list);
        },
        child: const Center(
          child: const CircularProgressIndicator(),
        ),
      );
}

class DefaultListBuilder extends StatefulWidget {
  const DefaultListBuilder({Key key, this.list}) : super(key: key);
  final list;

  @override
  _DefaultListBuilderState createState() => _DefaultListBuilderState();
}

class _DefaultListBuilderState extends State<DefaultListBuilder> {
  static void _onItemTap(BuildContext context, SongInfo songInfo) =>
      Variable.setCurrentSong(Variable.defaultList.value, songInfo);

  static Widget _itemBuilder(BuildContext context, SongInfo songInfo) {
    return ListTile(
      key: ValueKey(songInfo),
      title: AutoSizeText(
        songInfo.title,
        style: Theme.of(context).textTheme.body1,
        maxLines: 1,
      ),
      subtitle: AutoSizeText(
        songInfo.artist == '<unknown>' ? songInfo.album : songInfo.artist,
        style: Theme.of(context).textTheme.body2,
        maxLines: 1,
      ),
      onTap: () => _onItemTap(context, songInfo),
      trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => pushSongViewPage(context, songInfo)),
    );
  }

  _onReorder(int oldIndex, int newIndex) {
    final list = Variable.defaultList.value;
    if (oldIndex < newIndex) {
      list.insert(newIndex, list[oldIndex]);
      list.removeAt(oldIndex);
    } else {
      var song = list.removeAt(oldIndex);
      list.insert(newIndex, song);
    }
    // sync currentListNotifier
    Variable.defaultList.notifyListeners();
    if (list == Variable.currentList.value) {
      Variable.currentList.notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) =>
      // TODO: implement build
      CustomReorderableListView(
        header: widget.list.length == 0
            ? const Material()
            : const DefaultListHeader(),
        end: widget.list.length == 0
            ? const Padding(
                padding: const EdgeInsets.only(top: 120.0, bottom: 120.0),
                child: Center(child: FadeInWidget(child: Icon(Icons.search))))
            : const Padding(
                padding: const EdgeInsets.only(bottom: 120.0),
                child: Center(child: Icon(Icons.filter_list))),
        onDragStart: () => Variable.panelAntiBlock.value = true,
        onDragEnd: () => Variable.panelAntiBlock.value = false,
        children: <Widget>[
          for (final songInfo in widget.list) _itemBuilder(context, songInfo),
        ],
        onReorder: _onReorder,
      );
}

class DefaultListHeader extends StatelessWidget {
  const DefaultListHeader({Key key}) : super(key: key);

  _play(int playListSequenceStatus) async {
    Variable.playListSequence.state = playListSequenceStatus;
    if (Variable.currentList.value == Variable.defaultList.value) {
      if (MediaPlayer.status != MediaPlayerStatus.started) {
        MediaPlayer.start();
      }
    } else {
      final int index =
          playListSequenceStatus == PlayListSequenceStatus.shuffle.index
              ? Random().nextInt(Variable.defaultList.value.length - 1)
              : 0;
      MediaPlayer.status = MediaPlayerStatus.started;
      Variable.setCurrentSong(
          Variable.defaultList.value, Variable.defaultList.value[index]);
    }
  }

  _playRepeat() async => _play(PlayListSequenceStatus.repeat.index);

  _playShuffle() async => _play(PlayListSequenceStatus.shuffle.index);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        FadeInWidget(
          delay: const Duration(milliseconds: 300),
          duration: Constants.defaultLongDuration,
          child: ListTile(
            leading: Text(
              'Library',
              style: Theme.of(context).textTheme.body1,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.play_circle_filled),
                  onPressed: _playRepeat,
                ),
                IconButton(
                  icon: const Icon(Icons.shuffle),
                  onPressed: _playShuffle,
                ),
              ],
            ),
            trailing: Text(
              'All Songs: ' + Variable.defaultList.value.length.toString(),
              style: Theme.of(context).textTheme.body2,
              maxLines: 1,
            ),
          ),
        ),
        const Divider(
          color: Colors.black12,
        ),
      ],
    );
  }
}

class AlbumList extends StatefulWidget {
  const AlbumList({Key key}) : super(key: key);

  @override
  _AlbumListState createState() => _AlbumListState();
}

class _AlbumListState extends State<AlbumList> {
  static Future loading;

  static _load() async {
    while (Variable.playListLoading == null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Variable.playListLoading;
    await Future.delayed(Constants.defaultLoadingDelay);
    Variable.albumToSongsMapLoading ??= Variable.generalMapAlbumToSongs();
    await Variable.albumToSongsMapLoading;
    return;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loading ??= _load();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Widget _futureBuilder(BuildContext context, AsyncSnapshot snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.active:
      case ConnectionState.waiting:
        return const Center(child: const CircularProgressIndicator());
      case ConnectionState.done:
        if (snapshot.hasError)
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Error: ${snapshot.error}'),
          ));
        return CustomScrollView(
          cacheExtent: 100,
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 72,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                title: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: FadeInWidget(
                    child: Text(
                      'Albums Gallery',
                      style: Theme.of(context).textTheme.body1,
                    ),
                  ),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: Constants.gridDelegate,
              delegate: SliverChildBuilderDelegate(
                _albumItemBuilder,
                childCount: Variable.albums.length,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
              ),
            ),
            const SliverToBoxAdapter(
              child: const Padding(
                padding: const EdgeInsets.all(12.0),
                child: const Center(
                  child: const Icon(Icons.filter_list),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: const Divider(
                height: Constants.miniPanelHeight,
              ),
            ),
          ],
        );
    }
    return null;
  }

  Widget _albumItemBuilder(BuildContext context, int index) {
    return AlbumViewItem(
      album: Variable.albums[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FutureBuilder(
      future: loading,
      builder: _futureBuilder,
    );
  }
}

class ArtistList extends StatefulWidget {
  const ArtistList({Key key}) : super(key: key);

  @override
  _ArtistListState createState() => _ArtistListState();
}

class _ArtistListState extends State<ArtistList> {
  static Future loading;

  static _load() async {
    while (Variable.playListLoading == null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Variable.playListLoading;
    await Future.delayed(Constants.defaultLoadingDelay);
    Variable.artistToSongsMapLoading ??= Variable.generalMapArtistToSong();
    await Variable.artistToSongsMapLoading;
    return;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loading ??= _load();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  Widget _futureBuilder(BuildContext context, AsyncSnapshot snapshot) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.active:
      case ConnectionState.waiting:
        return const Center(child: const CircularProgressIndicator());
      case ConnectionState.done:
        if (snapshot.hasError)
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Error: ${snapshot.error}'),
          ));
        return CustomScrollView(
          cacheExtent: 100,
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 72,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                title: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: FadeInWidget(
                    child: Text(
                      'Artists List',
                      style: Theme.of(context).textTheme.body1,
                    ),
                  ),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: Constants.gridDelegate,
              delegate: SliverChildBuilderDelegate(
                _artistItemBuilder,
                childCount: Variable.artists.length,
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
              ),
            ),
            const SliverToBoxAdapter(
              child: const Padding(
                padding: const EdgeInsets.all(12.0),
                child: const Center(
                  child: const Icon(Icons.filter_list),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: const Divider(
                height: Constants.miniPanelHeight,
              ),
            ),
          ],
        );
    }
    return null;
  }

  Widget _artistItemBuilder(BuildContext context, int index) {
    return ArtistViewItem(
      artist: Variable.artists[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FutureBuilder(
      future: loading,
      builder: _futureBuilder,
    );
  }
}

class StandardListTile extends StatefulWidget {
  const StandardListTile({Key key, this.songInfo, this.child})
      : super(key: key);
  final SongInfo songInfo;
  final Widget child;

  @override
  _StandardListTileState createState() => _StandardListTileState();
}

class _StandardListTileState extends State<StandardListTile> {
  static void _onItemTap(BuildContext context, SongInfo songInfo) {
    Variable.currentList.value = Variable.defaultList.value;
    Variable.currentItem.value = songInfo;
  }

  Widget built;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    built ??= ListTile(
      key: ValueKey(widget.songInfo),
      title: Text(
        widget.songInfo.title,
        style: Theme.of(context).textTheme.body1,
        maxLines: 2,
      ),
      subtitle: Text(
        widget.songInfo.artist == Constants.unknown
            ? widget.songInfo.album
            : widget.songInfo.artist,
        style: Theme.of(context).textTheme.body2,
        maxLines: 2,
      ),
      onTap: () => _onItemTap(context, widget.songInfo),
      trailing: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => _menuButtonSheet(context, widget.songInfo)),
    );
    return built;
  }
}
