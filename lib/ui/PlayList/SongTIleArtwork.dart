import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/Constants.dart';
import '../../data/Variable.dart';

class SongTileArtwork extends StatefulWidget {
  const SongTileArtwork({Key key, @required this.filePath}) : super(key: key);
  final String filePath;

  @override
  _SongTileArtworkState createState() => _SongTileArtworkState();
}

class _SongTileArtworkState extends State<SongTileArtwork> {
  ImageProvider image;

  _loadImageAsync() async {
    image = Variable.filePathToImageMap[widget.filePath].value;
    await SchedulerBinding.instance.endOfFrame;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SongTileArtwork oldWidget) {
    // TODO: implement didUpdateWidget
    if (widget.filePath != oldWidget.filePath) {
      Variable.filePathToImageMap[oldWidget.filePath]
          ?.removeListener(_loadImageAsync);
      image = Variable.filePathToImageMap[widget.filePath].value;
      Variable.filePathToImageMap[widget.filePath].addListener(_loadImageAsync);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Variable.getArtworkAsync(filePath: widget.filePath);
    image = Variable.filePathToImageMap[widget.filePath].value;
    Variable.filePathToImageMap[widget.filePath].addListener(_loadImageAsync);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    Variable.filePathToImageMap[widget.filePath]
        .removeListener(_loadImageAsync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: Constants.borderRadius),
        child: AnimatedSwitcher(
          duration: Constants.defaultDuration,
          layoutBuilder: Constants.expendLayoutBuilder,
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
