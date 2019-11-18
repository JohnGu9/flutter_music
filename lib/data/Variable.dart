import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/component/AntiBlockingWidget.dart';
import 'package:flutter_app/data/CustomImageProvider.dart';
import 'package:flutter_app/data/Database.dart' as db;
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:share_extend/share_extend.dart';
import 'package:sqflite/sqlite_api.dart';

import '../component/CustomValueNotifier.dart';
import '../plugin/MediaMetadataRetriever.dart';
import 'Constants.dart';

class Variable {
  static final audioQuery = FlutterAudioQuery();

  static Database database;
  static db.LinkedList library;
  static db.LinkedList favourite;

  static db.ImageTable cacheRemotePicture;
  static const cacheRemotePicturePrimaryKey =
      db.DatabaseKey<String>(keyName: 'filePath');
  static const cacheRemotePictureKeys = [
    db.DatabaseKey<String>(keyName: 'img0')
  ];
  static final filePathToPendingRequestMap = Map<String, bool>();

  static final ValueNotifier<int> durationThreshold =
      ValueNotifier<int>(Constants.durationThreshold);

  static final CustomValueNotifier<List> currentList =
      CustomValueNotifier(null);
  static final CustomValueNotifier<String> currentItem =
      CustomValueNotifier(null);

  static final Map<List, PlayListRegister> playListRegisters = Map();
  static final CustomValueNotifier<List<RecentLog>> recentLogs =
      CustomValueNotifier(List());

  static final CustomValueNotifier<List<String>> libraryNotify =
      CustomValueNotifier(null);
  static final CustomValueNotifier<List<String>> favouriteNotify =
      CustomValueNotifier(null);

  static setCurrentSong(List<String> songList, String filePath) async {
    // Alarm: songInfo must be come from filePathToSongMap
    assert(filePathToSongMap.containsKey(filePath));
    // Prevent update currentItem while pageRoute is in transition.
    // Warning: if update currentItem while pageRoute is in transition, it will cause Hero widget break down.
    beforeSetCurrentSong();
    filePathToNotifierMap[currentItem.value].value = false;
    await pageRouteTransition();
    if (Variable.currentList.value != songList) {
      Variable.panelAntiBlock.value = true;
      await Future.delayed(AntiBlockDuration);
      Variable.currentList.value = songList;
      Variable.currentItem.value = filePath;
      Variable.panelAntiBlock.value = false;
      await Future.delayed(AntiBlockDuration);
    } else {
      Variable.currentItem.value = filePath;
    }
    filePathToNotifierMap[filePath].value = true;
  }

  static Function() beforeSetCurrentSong = () {};
  static Future<void> Function() pageRouteTransition = () async {};

  /// Get image async from [getArtworkAsync]
  static final Map<String, Future<ImageProvider>> futureImages =
      Map<String, Future<ImageProvider>>();

  /// Get data sync, but if data isn't ready from [getArtworkAsync], it will return null.
  static final Map<String, ValueNotifier<ImageProvider>> filePathToImageMap =
      Map<String, ValueNotifier<ImageProvider>>();

  static final Map<String, ImageProvider> filePathToLocalImageMap =
      Map<String, ImageProvider>();

  /// The options which image should attach to show
  static const String localImage = 'localImage';
  static const String remoteImage = 'remoteImage';
  static const String noneImage = 'remoteImage';

  /// decide which image should attach to show
  static final Map<String, String> filePathToAttachImageMap =
      Map<String, String>();

  /// This function must be called before get image from [filePathToImageMap] sync
  static Future<ImageProvider> getArtworkAsync({String filePath}) {
    if (filePath == null) {
      return null;
    }
    // If image has no cache yet, instance a future to cache the image data
    if (!futureImages.containsKey(filePath)) {
      filePathToImageMap[filePath] ??= ValueNotifier<ImageProvider>(null);
      futureImages[filePath] = Future<ImageProvider>(() async {
        ImageProvider image =
            await MediaMetadataRetriever.getEmbeddedPicture(filePath);
        if (image == null) {
          final data = await cacheRemotePicture.getData(filePath);
          if (data != null) {
            image = MemoryImage(data[cacheRemotePictureKeys[0].keyName]);
            MediaMetadataRetriever.getPalette(
                filePath, (image as MemoryImage).bytes);
          }
        } else {
          filePathToLocalImageMap[filePath] = image;
        }
        filePathToImageMap[filePath].value = image;

        /// query image from internet
        if (image == null) {
          SongInfo songInfo = filePathToSongMap[filePath];
          if (requestNetworkAccess()) {
            MediaMetadataRetriever.getRemotePicture(songInfo: songInfo);
          } else {
            filePathToPendingRequestMap[filePath] = true;
          }
        }
        return image;
      });
    }

    /// If request was pended before and network state allow to capture artwork online,
    /// restart download
    if (filePathToPendingRequestMap.containsKey(filePath) &&
        filePathToPendingRequestMap[filePath]) {
      SongInfo songInfo = filePathToSongMap[filePath];
      if (requestNetworkAccess()) {
        MediaMetadataRetriever.getRemotePicture(songInfo: songInfo);
        filePathToPendingRequestMap[filePath] = false;
      }
    }

    return Variable.futureImages[filePath];
  }

  static bool requestNetworkAccess() =>
      (wifiSwitch.value == true &&
          networkStatue.value == ConnectivityResult.wifi) ||
      (mobileDataSwitch.value == true &&
          networkStatue.value == ConnectivityResult.mobile);

  static Future mediaPlayerInitialization;
  static Future playListInitialization;

  static final filePathToSongMap = Map<String, SongInfo>();
  static final filePathToNotifierMap = Map<String, CustomValueNotifier>();

  static final albumIdToSongPathsMap =
      Map<String, CustomValueNotifier<List<String>>>();
  static final artistIdToSongPathsMap =
      Map<String, CustomValueNotifier<List<String>>>();
  static final artistIdToAlbumIdsMap =
      Map<String, CustomValueNotifier<List<String>>>();
  static List<AlbumInfo> albums;
  static List<ArtistInfo> artists;

  static Future albumToSongsMapLoading;

  static generalMapAlbumToSongs() async {
    await playListInitialization;
    albums = await audioQuery.getAlbums();
    // Sort albums
    final List<AlbumInfo> _unknownAlbums = List();
    albums = await Variable.audioQuery.getAlbums();
    for (int i = 0; i < albums.length;) {
      albums[i].title == Constants.unknown
          ? _unknownAlbums.add(albums.removeAt(i))
          : i++;
    }
    if (_unknownAlbums.length > 0) {
      albums.addAll(_unknownAlbums);
    }
    for (int i = 0; i < albums.length;) {
      final AlbumInfo albumInfo = albums[i];
      final List<SongInfo> songInfos =
          await audioQuery.getSongsFromAlbum(album: albumInfo);
      List<String> songs = List();
      for (int i = 0; i < songInfos.length; i++) {
        if (filePathToSongMap.containsKey(songInfos[i].filePath))
          songs.add(songInfos[i].filePath);
      }
      if (songInfos.length > 0) {
        albumIdToSongPathsMap[albumInfo.id] = CustomValueNotifier(null);
        albumIdToSongPathsMap[albumInfo.id].value = songs;
        AlbumArtworkProvider(albumInfo.id);
        playListRegisters[albumIdToSongPathsMap[albumInfo.id].value] =
            PlayListRegister(albumInfo.title, (int oldIndex, int newIndex) {
          reorder(
              albumIdToSongPathsMap[albumInfo.id].value, oldIndex, newIndex);
          albumIdToSongPathsMap[albumInfo.id].notifyListeners();
        });
        i++;
      } else {
        // Clear the empty album
        albums.remove(albumInfo);
      }
    }
  }

  static Future artistToSongsMapLoading;

  static generalMapArtistToSong() async {
    await playListInitialization;
    albumToSongsMapLoading ??= generalMapAlbumToSongs();
    await albumToSongsMapLoading;

    artists = await audioQuery.getArtists();
    print(artists);
    // Sort artists
    final List<ArtistInfo> _unknownArtists = List();
    for (int i = 0; i < Variable.artists.length;) {
      await SchedulerBinding.instance.endOfFrame;
      if (artists[i].name == Constants.unknown) {
        _unknownArtists.add(artists.removeAt(i));
      } else {
        i++;
      }
    }
    if (_unknownArtists.length > 0) {
      for (final artist in _unknownArtists) {
        artists.add(artist);
      }
    }

    for (int i = 0; i < artists.length;) {
      await SchedulerBinding.instance.endOfFrame;
      final ArtistInfo artistInfo = artists[i];
      final List<SongInfo> songInfos =
          await audioQuery.getSongsFromArtist(artist: artistInfo);
      List<String> songs = List();
      for (int i = 0; i < songInfos.length; i++) {
        if (Variable.filePathToSongMap.containsKey(songInfos[i].filePath))
          songs.add(songInfos[i].filePath);
      }
      if (songInfos.length > 0) {
        Variable.artistIdToSongPathsMap[artistInfo.id] =
            CustomValueNotifier(null);
        Variable.artistIdToSongPathsMap[artistInfo.id].value = songs;

        playListRegisters[
                Variable.artistIdToSongPathsMap[artistInfo.id].value] =
            PlayListRegister(artistInfo.name, (int oldIndex, int newIndex) {
          reorder(Variable.artistIdToSongPathsMap[artistInfo.id].value,
              oldIndex, newIndex);
          Variable.artistIdToSongPathsMap[artistInfo.id].notifyListeners();
        });

        final albums = await audioQuery.getAlbumsFromArtist(artist: artistInfo);
        List<String> albumIds = List();
        albums.forEach((AlbumInfo albumInfo) {
          if (Variable.albumIdToSongPathsMap.containsKey(albumInfo.id))
            albumIds.add(albumInfo.id);
        });

        if (albumIds.isNotEmpty) {
          Variable.artistIdToAlbumIdsMap[artistInfo.id] =
              CustomValueNotifier(null);
          Variable.artistIdToAlbumIdsMap[artistInfo.id].value = albumIds;
          ArtistArtworkProvider(artistInfo.id);
        }

        i++;
      } else {
        // Clear the empty artist
        artists.remove(artistInfo);
      }
    }
  }

  // load single image from songs list
  static Future<ImageProvider> getImageFromSongs(List<String> songs) async {
    for (final String songPath in songs) {
      await SchedulerBinding.instance.endOfFrame;
      final ImageProvider image =
          await Variable.getArtworkAsync(filePath: songPath);
      if (image != null) {
        return image;
      }
    }
    return null;
  }

  // load multi image from songs list
  static Future<List<ImageProvider>> getImagesFromSongs(
      List<String> songs) async {
    final list = List<ImageProvider>();
    for (final String songPath in songs) {
      await SchedulerBinding.instance.endOfFrame;
      final ImageProvider image =
          await Variable.getArtworkAsync(filePath: songPath);
      if (image != null) {
        list.add(image);
      }
    }
    return list;
  }

  static final CustomValueNotifier<bool> panelAntiBlock =
      CustomValueNotifier<bool>(true);

  static AnimationController playButtonController;
  static final PlayListSequence playListSequence = PlayListSequence();

  static TabController tabController;
  static ScrollController outerScrollController;
  static ScrollController innerScrollController;

  static shareSong(SongInfo songInfo) async {
    File testFile = new File(songInfo.filePath);
    if (await testFile.exists()) {
      ShareExtend.share(testFile.path, "file");
    } else {
      debugPrint("File doesn't exist");
    }
  }

  static const highQuality = 0;
  static const middleQuality = 1;
  static const lowQuality = 2;
  static final ValueNotifier<int> remoteImageQuality =
      ValueNotifier<int>(highQuality);

  static final ValueNotifier wifiSwitch = ValueNotifier<bool>(true);
  static final ValueNotifier mobileDataSwitch = ValueNotifier<bool>(false);
  static final ValueNotifier networkStatue =
      ValueNotifier<ConnectivityResult>(ConnectivityResult.none);

  static final ValueNotifier notificationPlayBackSwitch =
      ValueNotifier<bool>(true);
  static final ValueNotifier notificationProductNewsSwitch =
      ValueNotifier<bool>(false);

  static const autoTheme = 'Auto';
  static const lightTheme = 'Light';
  static const darkTheme = 'Dark';
  static final ValueNotifier<String> themeSwitch = ValueNotifier(autoTheme);
}

reorder(List list, int oldIndex, int newIndex) async => (oldIndex < newIndex)
    ? list.insert(newIndex - 1, list.removeAt(oldIndex))
    : list.insert(newIndex, list.removeAt(oldIndex));

bool _updating = false;

void onFavorite(String songPath) async {
  if (songPath == null || _updating) {
    return;
  }

  final currentListNotifier = Variable.currentList;
  final currentItemNotifier = Variable.currentItem;

  int index = Variable.favourite.indexOf(songPath);
  if (currentListNotifier.value == Variable.favourite.list) {
    if (currentItemNotifier.value == songPath) {
      // remove currentItem
      if (index == -1) {
        return;
      }
      final List<String> newList = List.from(Variable.favouriteNotify.value);
      currentListNotifier.value = newList;
      Variable.favourite.removeAt(index);
      Variable.favouriteNotify.notifyListeners();
      if (Variable.favouriteNotify.value.length == 0) {
        currentItemNotifier.value = null;
        currentListNotifier.value = Variable.favouriteNotify.value;
      } else {
        if (index == Variable.favouriteNotify.value.length) {
          // When delete the last song
          index -= 1;
        }
        await Future.delayed(const Duration(milliseconds: 50));
        currentItemNotifier.value = Variable.favourite[index];
        _updating = true;
        await Future.delayed(Constants.defaultDuration);
        currentListNotifier.value = Variable.favouriteNotify.value;
        await Future.delayed(const Duration(milliseconds: 50));
        _updating = false;
      }
    } else {
      if (index == -1) {
        Variable.favourite.insert(0, songPath);
      } else {
        Variable.favourite.removeAt(index);
      }
      // update both list
      Variable.favouriteNotify.notifyListeners();
      currentListNotifier.notifyListeners();
    }
  } else {
    if (index == -1) {
      Variable.favourite.insert(0, songPath);
    } else {
      Variable.favourite.removeAt(index);
    }
    // update favouriteList
    Variable.favouriteNotify.notifyListeners();
  }
}

enum PlayListSequenceStatus {
  repeat,
  shuffle,
  repeat_one,
}

class PlayListSequence {
  static final playListSequenceStatusLength = 3;
  final stateChangeNotifier = CustomValueNotifier<int>(0);

  set state(int value) => stateChangeNotifier.value = value;

  int get state => stateChangeNotifier.value;

  void previousState() {
    if (state == 0) {
      state = playListSequenceStatusLength - 1;
    } else {
      state = state - 1;
    }
  }

  void nextState() {
    state = state + 1;
    if (state == playListSequenceStatusLength) {
      state = 0;
    }
  }

  PlayListSequenceStatus getState() => PlayListSequenceStatus.values[state];

  IconData getIcon() {
    if (PlayListSequenceStatus.values[state] == PlayListSequenceStatus.repeat) {
      return Icons.repeat;
    } else if (PlayListSequenceStatus.values[state] ==
        PlayListSequenceStatus.repeat_one) {
      return Icons.repeat_one;
    } else if (PlayListSequenceStatus.values[state] ==
        PlayListSequenceStatus.shuffle) {
      return Icons.shuffle;
    }
    return Icons.error;
  }
}

class PlayListRegister {
  const PlayListRegister(this.title, this.onReorder,
      {this.subTitle, this.icon});

  final String title;
  final String subTitle;
  final Function(int, int) onReorder;
  final Icon icon;
}

class RecentLog {
  static final Map<String, List> _cacheX = Map();
  static final Map<List, RecentLog> _cacheY = Map();

  factory RecentLog({String filePath, List playList}) {
    if (_cacheX.containsKey(filePath) && _cacheY.containsKey(playList)) {
      return _cacheY[playList];
    } else {
      _cacheX[filePath] = playList;
      _cacheY[playList] =
          RecentLog.init(filePath: filePath, playList: playList);
      return _cacheY[playList];
    }
  }

  RecentLog.init({this.filePath, this.playList});

  final String filePath;
  final List playList;

  @override
  String toString() {
    final PlayListRegister playListRegister =
        Variable.playListRegisters[playList];
    return '\n{' +
        'filePath: ' +
        this.filePath +
        ' playList: ' +
        playListRegister.title +
        '}';
  }
}
