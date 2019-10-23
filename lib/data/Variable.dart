import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/component/AntiBlockingWidget.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:share_extend/share_extend.dart';

import '../component/CustomValueNotifier.dart';
import '../plugin/MediaMetadataRetriever.dart';
import 'Constants.dart';

class Variable {
  // Controller
  static final audioQuery = FlutterAudioQuery();

//  static final database = _dbInit();
//
//  static Future<Database> _dbInit() async => openDatabase(
//        // Set the path to the database.
//        join(await getDatabasesPath(), 'johngu.db'),
//        // When the database is first created, create a table to store dogs.
//        onCreate: (db, version) {
//          // Run the CREATE TABLE statement on the database.
//          return db.execute(
//            "CREATE TABLE library(id INTEGER PRIMARY KEY, filePath TEXT)",
//          );
//        },
//        // Set the version. This executes the onCreate function and provides a
//        // path to perform database upgrades and downgrades.
//        version: 1,
//      );

  // Data
  static final CustomValueNotifier<List> currentList =
      CustomValueNotifier(null);
  static final CustomValueNotifier<SongInfo> currentItem =
      CustomValueNotifier(null);

  static final CustomValueNotifier<List<SongInfo>> defaultList =
      CustomValueNotifier(null);
  static final CustomValueNotifier<List<SongInfo>> favouriteList =
      CustomValueNotifier(null);

  static setCurrentSong(List<SongInfo> songList, SongInfo songInfo) async {
    // Alarm: songInfo must be come from filePathToSongMap
    assert(filePathToSongMap.containsValue(songInfo));
    // Prevent update currentItem while pageRoute is in transition.
    // Warning: if update currentItem while pageRoute is in transition, it will cause Hero widget break down.
    beforeSetCurrentSong();
    await pageRouteTransition();
    if (Variable.currentList.value != songList) {
      Variable.panelAntiBlock.value = true;
      await Future.delayed(AntiBlockDuration);
      Variable.currentList.value = songList;
      Variable.currentItem.value = songInfo;
      Variable.panelAntiBlock.value = false;
      await Future.delayed(AntiBlockDuration);
    } else {
      Variable.currentItem.value = songInfo;
    }
  }

  static Function() beforeSetCurrentSong = () {};
  static Future<void> Function() pageRouteTransition = () async {};

  static final Map<String, Future<ImageProvider>> futureImages =
      Map<String, Future<ImageProvider>>(); // Get image async
  static final Map<String, ImageProvider> filePathToImageMap = Map<String,
      ImageProvider>(); // Get data sync, but if data isn't ready, it will return null.

  // This function must be called before get image from filePathToImageMap(above) sync
  static Future<ImageProvider> getArtworkAsync({String path}) async {
    if (path == null) {
      return null;
    }
    // If image has no cache yet, instance a future to cache the image data
    if (!futureImages.containsKey(path)) {
      futureImages[path] = Future<ImageProvider>(() async {
        Future<ImageProvider> res =
            MediaMetadataRetriever.getEmbeddedPicture(path);
        // cache image data
        filePathToImageMap[path] = await res;
        return filePathToImageMap[path];
      });
    }
    return Variable.futureImages[path];
  }

  static Future mediaPlayerLoading;
  static Future playListLoading;

  static final filePathToSongMap = Map<String, SongInfo>();
  static final albumIdToSongsMap = Map<String, List<SongInfo>>();
  static final albumIdToImageMap = Map<String, ImageProvider>();
  static final artistIdToSongsMap = Map<String, List<SongInfo>>();
  static final artistIdToImagesMap = Map<String, List<ImageProvider>>();
  static List<AlbumInfo> albums;
  static List<ArtistInfo> artists;

  static Future albumToSongsMapLoading;

  static generalMapAlbumToSongs() async {
    await playListLoading;
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
      final List<SongInfo> songs =
          await audioQuery.getSongsFromAlbum(album: albumInfo);
      for (int i = 0; i < songs.length; i++) {
        songs[i] = filePathToSongMap[songs[i].filePath];
      }
      if (songs.length > 0) {
        albumIdToSongsMap[albumInfo.id] = songs;
        i++;
      } else {
        // Clear the empty album
        albums.remove(albumInfo);
      }
    }
  }

  static Future artistToSongsMapLoading;

  static generalMapArtistToSong() async {
    await playListLoading;
    artists = await audioQuery.getArtists();
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
      final List<SongInfo> songs =
          await audioQuery.getSongsFromArtist(artist: artistInfo);
      for (int i = 0; i < songs.length; i++) {
        songs[i] = Variable.filePathToSongMap[songs[i].filePath];
      }
      if (songs.length > 0) {
        Variable.artistIdToSongsMap[artistInfo.id] = songs;
        i++;
      } else {
        // Clear the empty artist
        artists.remove(artistInfo);
      }
    }
  }

  // load single image from songs list
  static Future<ImageProvider> getImageFromSongs(List<SongInfo> songs) async {
    for (final SongInfo songInfo in songs) {
      await SchedulerBinding.instance.endOfFrame;
      final ImageProvider image =
          await Variable.getArtworkAsync(path: songInfo.filePath);
      if (image != null) {
        return image;
      }
    }
    return null;
  }

  // load multi image from songs list
  static Future<List<ImageProvider>> getImagesFromSongs(
      List<SongInfo> songs) async {
    final list = List<ImageProvider>();
    for (final SongInfo songInfo in songs) {
      await SchedulerBinding.instance.endOfFrame;
      final ImageProvider image =
          await Variable.getArtworkAsync(path: songInfo.filePath);
      if (image != null) {
        list.add(image);
      }
    }
    return list;
  }

  static Future<ImageProvider> getImageFromAlbums(AlbumInfo album) async {
    if (Variable.albumIdToImageMap.containsKey(album.id)) {
      return Variable.albumIdToImageMap[album.id];
    }
    // must be use before albumToSongMap loaded
    albumToSongsMapLoading ??= generalMapAlbumToSongs();
    await albumToSongsMapLoading;
    final songs = Variable.albumIdToSongsMap[album.id];
    // get single image
    final ImageProvider image = await getImageFromSongs(songs);
    Variable.albumIdToImageMap[album.id] = image;
    return image;
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
}

bool _updating = false;

void onFavorite(SongInfo songInfo) async {
  if (songInfo == null || _updating) {
    return;
  }

  final favouriteList = Variable.favouriteList;
  final currentListNotifier = Variable.currentList;
  final currentItemNotifier = Variable.currentItem;

  int index = favouriteList.value.indexOf(songInfo);
  if (currentListNotifier.value == favouriteList.value) {
    if (currentItemNotifier.value == songInfo) {
      // remove currentItem
      if (index == -1) {
        return;
      }
      final List<SongInfo> newList = List.from(favouriteList.value);
      newList.removeAt(index);
      favouriteList.value = newList;
      if (newList.length == 0) {
        currentItemNotifier.value = null;
        currentListNotifier.value = newList;
      } else {
        if (index == newList.length) {
          // When delete the last song
          index -= 1;
        }
        currentItemNotifier.value = newList[index];
        _updating = true;
        await Future.delayed(Constants.defaultDuration);
        currentListNotifier.value = newList;
        await Future.delayed(Duration(milliseconds: 50));
        _updating = false;
      }
    } else {
      if (index == -1) {
        favouriteList.value.insert(0, songInfo);
      } else {
        favouriteList.value.removeAt(index);
      }
      // update both list
      favouriteList.notifyListeners();
      currentListNotifier.notifyListeners();
    }
  } else {
    if (index == -1) {
      favouriteList.value.insert(0, songInfo);
    } else {
      favouriteList.value.removeAt(index);
    }
    // update favouriteList
    favouriteList.notifyListeners();
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
