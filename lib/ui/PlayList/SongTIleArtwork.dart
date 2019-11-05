import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  ImageProvider image;

  _loadImageAsync() async {
    image = Variable.filePathToImageMap[widget.songInfo.filePath].value;
    await SchedulerBinding.instance.endOfFrame;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(SongTileArtwork oldWidget) {
    // TODO: implement didUpdateWidget
    if (widget.songInfo != oldWidget.songInfo) {
      Variable.filePathToImageMap[oldWidget.songInfo?.filePath]
          ?.removeListener(_loadImageAsync);
      image = Variable.filePathToImageMap[widget.songInfo.filePath].value;
      Variable.filePathToImageMap[widget.songInfo.filePath]
          .addListener(_loadImageAsync);
      setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Variable.getArtworkAsync(path: widget.songInfo.filePath);
    image = Variable.filePathToImageMap[widget.songInfo.filePath].value;
    Variable.filePathToImageMap[widget.songInfo.filePath]
        .addListener(_loadImageAsync);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Variable.filePathToImageMap[widget.songInfo.filePath]
        .removeListener(_loadImageAsync);
    super.dispose();
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
          child: image == null
              ? Constants.emptyArtwork
              : Image(
                  image: image,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }
}
