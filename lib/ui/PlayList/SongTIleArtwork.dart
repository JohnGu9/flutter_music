import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';

class SongTileArtwork extends StatefulWidget {
  const SongTileArtwork({Key key, @required this.songInfo}) : super(key: key);
  final SongInfo songInfo;

  @override
  _SongTileArtworkState createState() => _SongTileArtworkState();
}

class _SongTileArtworkState extends State<SongTileArtwork> {
  ImageProvider imageProvider;

  _loadImage() {
    if (Variable.filePathToImageMap.containsKey(widget.songInfo.filePath)) {
      imageProvider = Variable.filePathToImageMap[widget.songInfo.filePath];
    } else {
      _loadImageAsync();
    }
  }

  _loadImageAsync() async {
    imageProvider =
        await Variable.getArtworkAsync(path: widget.songInfo.filePath);
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadImage();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: Constants.borderRadius),
        child: AnimatedSwitcher(
          duration: Constants.defaultDuration,
          child: imageProvider == null
              ? Constants.emptyArtwork
              : Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}

