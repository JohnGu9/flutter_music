import 'dart:math';
import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/component/CustomValueNotifier.dart';
import 'package:flutter_app/data/Database.dart' as database;
import 'package:flutter_app/plugin/MediaMetadataRetriever.dart';
import 'package:flutter_app/ui/ExternalPage/Setting.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../component/AnimatedPopUpWidget.dart';
import '../../component/CustomReorderableList.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import '../../plugin/MediaPlayer.dart';
import 'AlbumViewItem.dart';
import 'ArtistViewItem.dart';
import 'SongTIleArtwork.dart';
import 'SongViewPage.dart';

class PlayList extends StatefulWidget {
  const PlayList({Key key}) : super(key: key);

  @override
  _PlayListState createState() => _PlayListState();
}

class _PlayListState extends State<PlayList>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static _load() async {
    // wait for MediaPlayer Loaded
    while (Variable.mediaPlayerInitialization == null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Variable.mediaPlayerInitialization;

    // Start Load PlayList
    final audioQuery = Variable.audioQuery;
    final List<SongInfo> allSongs = await audioQuery.getSongs();
    Variable.filePathToNotifierMap[null] = CustomValueNotifier(false);
    List<String> allSongsPath = List();
    allSongs.forEach((SongInfo songInfo) {
      if (int.parse(songInfo.duration) > Variable.durationThreshold.value) {
        Variable.filePathToSongMap[songInfo.filePath] = songInfo;
        Variable.filePathToNotifierMap[songInfo.filePath] =
            CustomValueNotifier(false);
        allSongsPath.add(songInfo.filePath);
      }
    });
    Variable.database = await openDatabase(
        path.join(await getDatabasesPath(), '${Constants.database}.db'));
    Variable.library = await database.LinkedList.easeLinkedList<String>(
        database: Constants.database,
        table: Constants.libraryTable,
        drop: false);
    Variable.favourite = await database.LinkedList.easeLinkedList<String>(
        database: Constants.database,
        table: Constants.favouriteTable,
        drop: false);

    Variable.library.sync(allSongsPath, shouldAdd: true);
    Variable.favourite.sync(allSongsPath, shouldAdd: false);

    Variable.libraryNotify.value = Variable.library.list;
    Variable.favouriteNotify.value = Variable.favourite.list;
    Variable.playListRegisters[Variable.libraryNotify.value] =
        PlayListRegister('Library', (int oldIndex, int newIndex) {
      Variable.library.reorder(oldIndex, newIndex);
      Variable.libraryNotify.notifyListeners();
    });
    Variable.playListRegisters[Variable.favouriteNotify.value] =
        PlayListRegister('Favourite', (int oldIndex, int newIndex) {
      Variable.favourite.reorder(oldIndex, newIndex);
      Variable.favouriteNotify.notifyListeners();
    });

    Variable.cacheRemotePicture = await database.ImageTable.easeTable(
        database: Constants.cacheDatabase,
        table: Constants.cacheRemotePictureTable,
        primaryKey: Variable.cacheRemotePicturePrimaryKey,
        keys: Variable.cacheRemotePictureKeys,
        drop: false);

    MediaMetadataRetriever.getRemotePictureCallback.addListener(() {
      if (MediaMetadataRetriever.remotePictureData != null) {
        /// update image
        Variable.filePathToImageMap[MediaMetadataRetriever.remotePicturePath]
            .value = MemoryImage(MediaMetadataRetriever.remotePictureData);
        Map<String, dynamic> map = Map();

        /// store image
        map[Variable.cacheRemotePicturePrimaryKey.keyName] =
            MediaMetadataRetriever.remotePicturePath;
        map[Variable.cacheRemotePictureKeys[0].keyName] =
            MediaMetadataRetriever.remotePictureData;
        Variable.cacheRemotePicture.setData(map);
      }

      /// updateNotification if in need
      if (MediaMetadataRetriever.remotePicturePath ==
          Variable.currentItem.value) {
        SongInfo songInfo =
            Variable.filePathToSongMap[Variable.currentItem.value];
        MemoryImage image =
            Variable.filePathToImageMap[songInfo.filePath].value;
        MediaPlayer.updateNotification(
            songInfo.title, songInfo.artist, songInfo.album, image?.bytes);
      }
    });

    /// network status check
    final connectivity = Connectivity();
    Variable.networkStatue.value = await connectivity.checkConnectivity();
    Connectivity().onConnectivityChanged.listen(
        (ConnectivityResult result) => Variable.networkStatue.value = result);

    Variable.networkStatue.addListener(() {
      if (Variable.filePathToPendingRequestMap
              .containsKey(Variable.currentItem.value) &&
          Variable.filePathToPendingRequestMap[Variable.currentItem.value]) {
        /// restart download remote image.
        /// [Variable.getArtworkAsync] can check network state and decide whether get remote artwork.
        Variable.getArtworkAsync(filePath: Variable.currentItem.value);
      }
    });
    MediaPlayer.volume = 0.5;
    Future.delayed(Constants.defaultDuration, () {
      if (Variable.currentItem.value == null &&
          Variable.libraryNotify.value.length != 0)
        Variable.setCurrentSong(
            Variable.libraryNotify.value, Variable.libraryNotify.value.first);
    });
  }

  List<Widget> _nestedAppBarBuilder(BuildContext context, _) {
    return [
      SliverAppBar(
        floating: true,
        pinned: false,
        elevation: 0.0,
        expandedHeight: 100,
        actions: <Widget>[
          Material(
            color: Colors.transparent,
            elevation: 0.0,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: IconButton(
              icon: Icon(Icons.trip_origin),
              onPressed: () => _test(context),
            ),
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: EdgeInsets.zero,
          title: Row(
            children: <Widget>[
              //const Icon(Icons.brightness_1),
              const Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0)),
              Padding(
                padding: Constants.AppBarTitlePadding,
                child: Text('Music', style: Theme.of(context).textTheme.title),
              ),
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
      SliverPersistentHeader(
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
      ),
    ];
  }

  void _test(BuildContext context) {
//    ExtendPlugin.AndroidChannel.invokeMethod('test',{'filePath':Variable.currentItem.value});
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Setting.pushPage(context, Offset(MediaQuery.of(context).size.width, 0.0));
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Variable.outerScrollController = ScrollController();
    Variable.tabController =
        TabController(vsync: this, length: 4, initialIndex: 2);
    Variable.playListInitialization ??= _load();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    Variable.tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NestedScrollView(
        controller: Variable.outerScrollController,
        headerSliverBuilder: _nestedAppBarBuilder,
        body: const MainTabView(),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // user returned to our app
      systemSetup(context);
    } else if (state == AppLifecycleState.inactive) {
      // app is inactive
    } else if (state == AppLifecycleState.paused) {
      // user is about quit our app temporally
    } else if (state == AppLifecycleState.suspending) {
      // app suspended (not used in iOS)
    }
  }
}

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverPersistentHeaderDelegate(this.tabBar);

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
                child: tabBar,
              )),
        ),
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 20;

  @override
  double get minExtent => tabBar.preferredSize.height + 20;

  @override
  bool shouldRebuild(_SliverPersistentHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != this.tabBar;
}

class MainTabView extends StatelessWidget {
  const MainTabView({Key key}) : super(key: key);

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
        valueListenable: Variable.favouriteNotify,
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
      Variable.setCurrentSong(
          Variable.favouriteNotify.value, songInfo.filePath);

  static Widget _itemBuilder(SongInfo songInfo) => FavouriteListItem(
        key: ValueKey(songInfo),
        songInfo: songInfo,
        onTap: _onItemTap,
      );

  _onReorder(int oldIndex, int newIndex) {
    Variable.favourite.reorder(oldIndex, newIndex);
    // sync currentListNotifier
    Variable.favouriteNotify.notifyListeners();
    if (Variable.favouriteNotify.value == Variable.currentList.value) {
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
                child: Constants.ListViewEndWidget,
              ),
        onDragStart: () async => Variable.panelAntiBlock.value = true,
        onDragEnd: () => Variable.panelAntiBlock.value = false,
        children: <Widget>[
          for (final String songPath in widget.list)
            _itemBuilder(Variable.filePathToSongMap[songPath]),
        ],
        onReorder: _onReorder,
      );
}

class FavouriteListHeader extends StatelessWidget {
  const FavouriteListHeader({Key key}) : super(key: key);

  _play(int playListSequenceStatus) async {
    Variable.playListSequence.state = playListSequenceStatus;
    if (Variable.currentList.value == Variable.favouriteNotify.value) {
      if (MediaPlayer.status != MediaPlayerStatus.started) {
        MediaPlayer.start();
      }
    } else {
      final int index =
          playListSequenceStatus == PlayListSequenceStatus.shuffle.index
              ? Random().nextInt(Variable.favouriteNotify.value.length - 1)
              : 0;
      MediaPlayer.status = MediaPlayerStatus.started;
      Variable.setCurrentSong(Variable.favouriteNotify.value,
          Variable.favouriteNotify.value[index]);
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

class FavouriteListItem extends StatelessWidget {
  const FavouriteListItem({Key key, this.songInfo, this.onTap})
      : super(key: key);
  final SongInfo songInfo;
  final Function(BuildContext, SongInfo) onTap;

  Widget _builder(BuildContext context, value, Widget child) {
    final color = value
        ? Theme.of(context).primaryColor
        : Theme.of(context).backgroundColor.withOpacity(0.0);
    return AnimatedContainer(
      duration: Constants.defaultDuration,
      color: color,
      child: ListTile(
        leading: AnimatedContainer(
          duration: Constants.defaultDuration,
          foregroundDecoration: BoxDecoration(
            color: value ? Colors.transparent : Colors.black38,
            borderRadius: Constants.borderRadius,
          ),
          child: SongTileArtwork(filePath: songInfo.filePath),
        ),
        title: Text(
          songInfo.title,
          style: Theme.of(context).textTheme.body1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          songInfo.artist == '<unknown>' ? songInfo.album : songInfo.artist,
          style: Theme.of(context).textTheme.body2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => onTap(context, songInfo),
        trailing: SongInfoButton(
          songInfo: songInfo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: Variable.filePathToNotifierMap[songInfo.filePath],
      builder: _builder,
    );
  }
}

class DefaultList extends StatelessWidget {
  const DefaultList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      // TODO: implement build
      ValueListenableBuilder(
        valueListenable: Variable.libraryNotify,
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
      Variable.setCurrentSong(Variable.libraryNotify.value, songInfo.filePath);

  static Widget _itemBuilder(SongInfo songInfo) => DefaultListItem(
        key: ValueKey(songInfo),
        songInfo: songInfo,
        onTap: _onItemTap,
      );

  _onReorder(int oldIndex, int newIndex) {
    Variable.library.reorder(oldIndex, newIndex);
    // sync currentListNotifier
    Variable.libraryNotify.notifyListeners();
    if (Variable.libraryNotify.value == Variable.currentList.value) {
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
                child: Constants.ListViewEndWidget),
        onDragStart: () async => Variable.panelAntiBlock.value = true,
        onDragEnd: () => Variable.panelAntiBlock.value = false,
        children: <Widget>[
          for (final String songPath in widget.list)
            _itemBuilder(Variable.filePathToSongMap[songPath]),
        ],
        onReorder: _onReorder,
      );
}

class DefaultListHeader extends StatelessWidget {
  const DefaultListHeader({Key key}) : super(key: key);

  _play(int playListSequenceStatus) async {
    Variable.playListSequence.state = playListSequenceStatus;
    if (Variable.currentList.value == Variable.libraryNotify.value) {
      if (MediaPlayer.status != MediaPlayerStatus.started) {
        MediaPlayer.start();
      }
    } else {
      final int index =
          playListSequenceStatus == PlayListSequenceStatus.shuffle.index
              ? Random().nextInt(Variable.libraryNotify.value.length - 1)
              : 0;
      MediaPlayer.status = MediaPlayerStatus.started;
      Variable.setCurrentSong(
          Variable.libraryNotify.value, Variable.libraryNotify.value[index]);
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
              'All Songs: ' + Variable.libraryNotify.value.length.toString(),
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

class DefaultListItem extends StatelessWidget {
  const DefaultListItem({Key key, this.songInfo, this.onTap}) : super(key: key);
  final SongInfo songInfo;
  final Function onTap;

  Widget _builder(BuildContext context, value, Widget child) {
    final color = value
        ? Theme.of(context).primaryColor
        : Theme.of(context).backgroundColor.withOpacity(0.0);
    return AnimatedContainer(
        duration: Constants.defaultDuration, color: color, child: child);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: Variable.filePathToNotifierMap[songInfo.filePath],
      builder: _builder,
      child: ListTile(
        title: Text(
          songInfo.title,
          style: Theme.of(context).textTheme.body1,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          songInfo.artist == '<unknown>' ? songInfo.album : songInfo.artist,
          style: Theme.of(context).textTheme.body2,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => onTap(context, songInfo),
        trailing: SongInfoButton(
          songInfo: songInfo,
        ),
      ),
    );
  }
}

class SongInfoButton extends StatelessWidget {
  const SongInfoButton({Key key, this.songInfo}) : super(key: key);
  final SongInfo songInfo;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () {
          RenderBox renderBox = context.findRenderObject();
          return SongViewPage.pushPage(
              context, songInfo, renderBox.localToGlobal(Offset.zero));
        });
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
    while (Variable.playListInitialization == null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Variable.playListInitialization;
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
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 72,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                title: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Albums Gallery',
                    style: Theme.of(context).textTheme.body1,
                  ),
                ),
              ),
            ),
            AnimationLimiter(
              child: SliverGrid(
                gridDelegate: Constants.gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  _albumItemBuilder,
                  childCount: Variable.albums.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: false,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: const Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Constants.ListViewEndWidget),
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

  static Widget _albumItemBuilder(BuildContext context, int index) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      columnCount: 2,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: AlbumViewItem(
            album: Variable.albums[index],
          ),
        ),
      ),
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
    while (Variable.playListInitialization == null) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Variable.playListInitialization;
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
        if (snapshot.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Error: ${snapshot.error}'),
          ));
        }
        return CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 72,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.zero,
                title: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Artists List',
                    style: Theme.of(context).textTheme.body1,
                  ),
                ),
              ),
            ),
            AnimationLimiter(
              child: SliverGrid(
                gridDelegate: Constants.gridDelegate,
                delegate: SliverChildBuilderDelegate(
                  _artistItemBuilder,
                  childCount: Variable.artists.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: false,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: const Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Constants.ListViewEndWidget),
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

  static Widget _artistItemBuilder(BuildContext context, int index) {
    return AnimationConfiguration.staggeredGrid(
      position: index,
      columnCount: 2,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: ArtistViewItem(
            artist: Variable.artists[index],
          ),
        ),
      ),
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
