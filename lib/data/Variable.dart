import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_app/component/AntiBlockingWidget.dart';
import 'package:flutter_app/data/Database.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:share_extend/share_extend.dart';

import '../component/CustomValueNotifier.dart';
import '../plugin/MediaMetadataRetriever.dart';
import 'Constants.dart';

class Variable {
  static final audioQuery = FlutterAudioQuery();

  static LinkedList library;
  static LinkedList favourite;

  static final CustomValueNotifier<List> currentList =
      CustomValueNotifier(null);
  static final CustomValueNotifier<String> currentItem =
      CustomValueNotifier(null);

  static final CustomValueNotifier<List<String>> libraryNotify =
      CustomValueNotifier(null);
  static final CustomValueNotifier<List<String>> favouriteNotify =
      CustomValueNotifier(null);

  static setCurrentSong(List<String> songList, String songInfo) async {
    // Alarm: songInfo must be come from filePathToSongMap
    assert(filePathToSongMap.containsKey(songInfo));
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
      futureImages[path] = MediaMetadataRetriever.getEmbeddedPicture(path)
          .then((value) => filePathToImageMap[path] = value);
    }
    return Variable.futureImages[path];
  }

  static Future mediaPlayerInitialization;
  static Future playListInitialization;

  static final filePathToSongMap = Map<String, SongInfo>();
  static final albumIdToSongsMap = Map<String, List<String>>();
  static final albumIdToImageMap = Map<String, ImageProvider>();
  static final artistIdToSongsMap = Map<String, List<String>>();
  static final artistIdToImagesMap = Map<String, List<ImageProvider>>();
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
        songs.add(songInfos[i].filePath);
      }
      if (songInfos.length > 0) {
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
    await playListInitialization;
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
      final List<SongInfo> songInfos =
          await audioQuery.getSongsFromArtist(artist: artistInfo);
      List<String> songs = List();
      for (int i = 0; i < songInfos.length; i++) {
        songs.add(songInfos[i].filePath);
      }
      if (songInfos.length > 0) {
        Variable.artistIdToSongsMap[artistInfo.id] = songs;
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
          await Variable.getArtworkAsync(path: songPath);
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
          await Variable.getArtworkAsync(path: songPath);
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
