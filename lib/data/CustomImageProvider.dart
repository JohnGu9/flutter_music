import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/plugin/MediaMetadataRetriever.dart';
import 'package:flutter_app/plugin/MediaPlayer.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import 'Variable.dart';

enum ArtworkAttributes {
  embedded,
  networkCache,
  network,
}

enum NetworkStatue {
  pended,
  downloading,
  downloaded,
}

class ArtworkProvider extends ChangeNotifier
    implements ValueListenable<ImageProvider> {
  static final Map<String, ArtworkProvider> _cache = Map();
  static final Map<String, ImageProvider> _generalResource = Map();

  static networkServiceInitialize() async {
    MediaMetadataRetriever.getRemotePictureCallback.addListener(() {
      ArtworkProvider artworkProvider =
          ArtworkProvider(filePath: MediaMetadataRetriever.remotePicturePath);
      if (MediaMetadataRetriever.remotePictureData != null) {
        /// update image
        artworkProvider.receiveDownload(
            MemoryImage(MediaMetadataRetriever.remotePictureData));

        /// store image
        Map<String, dynamic> map = Map();
        map[Variable.cacheRemotePicturePrimaryKey.keyName] =
            MediaMetadataRetriever.remotePicturePath;
        map[Variable.cacheRemotePictureKeys[0].keyName] =
            MediaMetadataRetriever.remotePictureData;
        Variable.cacheRemotePicture.setData(map);
      }

      /// updateNotification if in need
      if (artworkProvider.filePath == Variable.currentItem.value) {
        SongInfo songInfo =
            Variable.filePathToSongMap[Variable.currentItem.value];
        MemoryImage image = artworkProvider.value;
        MediaPlayer.updateNotification(
            songInfo.title, songInfo.artist, songInfo.album, image?.bytes);
      }
    });

    Variable.networkStatue.addListener(() {
      final filePath = Variable.currentItem?.value;
      if (filePath != null)
        ArtworkProvider(filePath: filePath).resumeDownload();
    });
  }

  factory ArtworkProvider({String filePath, SongInfo songInfo}) {
    filePath ??= songInfo.filePath;
    assert(filePath != null);
    _cache[filePath] ??= ArtworkProvider.init(filePath);
    return _cache[filePath];
  }

  ArtworkProvider.init(this.filePath) {
    Future(() async {
      /// From original file
      final ImageProvider image =
          await MediaMetadataRetriever.getEmbeddedPicture(filePath);
      if (image != null) {
        artworkAttributes = ArtworkAttributes.embedded;
        value = image;
      } else {
        /// From Database
        final data = await Variable.cacheRemotePicture.getData(filePath);
        if (data != null) {
          artworkAttributes = ArtworkAttributes.networkCache;
          value = MemoryImage(data[Variable.cacheRemotePictureKeys[0].keyName]);
          MediaMetadataRetriever.getPalette(
              filePath, (value as MemoryImage).bytes);
        } else {
          /// From Network
          if (Variable.requestNetworkAccess()) {
            networkStatue.value = NetworkStatue.downloading;
            MediaMetadataRetriever.getRemotePicture(
                songInfo: Variable.filePathToSongMap[filePath]);
          } else {
            networkStatue.value = NetworkStatue.pended;
          }
        }
      }
    });
  }

  resumeDownload() {
    if (networkStatue.value == NetworkStatue.pended &&
        Variable.requestNetworkAccess()) {
      networkStatue.value = NetworkStatue.downloading;
      MediaMetadataRetriever.getRemotePicture(
          songInfo: Variable.filePathToSongMap[filePath]);
    }
  }

  receiveDownload(ImageProvider imageProvider) {
    networkStatue.value = NetworkStatue.downloaded;
    value = imageProvider;
  }

  final String filePath;
  ArtworkAttributes artworkAttributes;
  final ValueNotifier<NetworkStatue> networkStatue = ValueNotifier(null);

  @override
  // TODO: implement value
  ImageProvider get value => _generalResource[filePath];

  set value(ImageProvider provider) {
    if (provider != _generalResource[filePath]) {
      _generalResource[filePath] = provider;
      notifyListeners();
    }
  }
}

class AlbumArtworkProvider extends ChangeNotifier
    implements ValueListenable<ImageProvider> {
  static final Map<String, AlbumArtworkProvider> _cache = Map();
  final String id;

  factory AlbumArtworkProvider(String id) {
    if (_cache.containsKey(id)) {
      return _cache[id];
    } else {
      _cache[id] = AlbumArtworkProvider.init(id);
      return _cache[id];
    }
  }

  AlbumArtworkProvider.init(this.id) {
    _subscribe(_search(id));
  }

  ValueListenable _search(String id) {
    final list = Variable.albumIdToSongPathsMap[id].value;
    assert(list.length != 0);
    for (final String songPath in list) {
      Variable.getArtworkAsync(filePath: songPath);
      final value = Variable.filePathToImageMap[songPath]?.value;
      if (value != null) {
        this.value = value;
        return Variable.filePathToImageMap[songPath];
      }
    }
    value = null;
    return Variable.filePathToImageMap[list.first];
  }

  _subscribe(ValueListenable notifier) {
    Function f;
    f = () {
      if (notifier.value != null) {
        value = notifier.value;
      } else {
        notifier.removeListener(f);
        _subscribe(_search(id));
      }
    };
    notifier.addListener(f);
  }

  @override
  ImageProvider get value => _value;
  ImageProvider _value;

  set value(ImageProvider newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  @override
  String toString() => super.toString();

  @override
  notifyListeners() => super.notifyListeners();
}

class ArtistArtworkProvider extends ChangeNotifier
    implements ValueListenable<List<ImageProvider>> {
  static final Map<String, ArtistArtworkProvider> _cache = Map();

  factory ArtistArtworkProvider(String id) {
    if (_cache.containsKey(id)) {
      return _cache[id];
    } else {
      _cache[id] = ArtistArtworkProvider.init(id);
      return _cache[id];
    }
  }

  ArtistArtworkProvider.init(String id) {
    imageMap = Map();
    final albumIdList = Variable.artistIdToAlbumIdsMap[id].value;
    if (albumIdList.isNotEmpty) {
      /// listen [AlbumArtworkProvider]
      for (final albumId in albumIdList) {
        final AlbumArtworkProvider albumArtworkProvider =
            AlbumArtworkProvider(albumId);
        if (albumArtworkProvider.value != null)
          imageMap[albumId] = albumArtworkProvider.value;
        albumArtworkProvider.addListener(() {
          if (albumArtworkProvider.value != null) {
            imageMap[albumId] = albumArtworkProvider.value;
          } else {
            imageMap.remove(albumId);
          }
          notifyListeners();
        });
      }
    }
    if (albumIdList.isEmpty || imageMap.length < 4) {
      /// listen multi songs
      List songsInAlbum = List<String>();
      if (albumIdList.isNotEmpty) {
        for (final albumId in albumIdList) {
          songsInAlbum.addAll(Variable.albumIdToSongPathsMap[albumId].value);
        }
      }

      final songList = Variable.artistIdToSongPathsMap[id].value;
      for (final songPath in songList) {
        if (!songsInAlbum.contains(songPath)) {
          Variable.getArtworkAsync(filePath: songPath);
          final notifier = Variable.filePathToImageMap[songPath];
          if (notifier.value != null) {
            imageMap[songPath] = notifier.value;
          }
          notifier.addListener(() {
            if (notifier.value != null) {
              imageMap[songPath] = notifier.value;
            } else {
              imageMap.remove(songPath);
            }
            notifyListeners();
          });
        }
      }
    }
  }

  Map<dynamic, ImageProvider> imageMap;

  @override
  List<ImageProvider> get value => imageMap.values.toList(growable: false);

  @override
  String toString() => super.toString();

  @override
  notifyListeners() {
    super.notifyListeners();
  }
}
