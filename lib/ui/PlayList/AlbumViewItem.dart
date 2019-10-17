import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';

import 'AlbumViewPage.dart';

const currentPage = 1;

class AlbumViewItem extends StatefulWidget {
  AlbumViewItem({Key key, @required this.album}) : super(key: key);
  final AlbumInfo album;

  @override
  _AlbumViewItemState createState() => _AlbumViewItemState();
}

class _AlbumViewItemState extends State<AlbumViewItem> {
  String tag;
  ImageProvider _image;
  bool _loaded = false;

  _loadImages() async {
    await SchedulerBinding.instance.endOfFrame;
    _image = await Variable.getImageFromAlbums(widget.album);
    await SchedulerBinding.instance.endOfFrame;
    setState(() => _loaded = true);
  }

  static const _innerScrollDuration = Duration(milliseconds: 335);

  _onTap() async {
    if (Variable.innerScrollController != null) {
      RenderBox renderBox = context.findRenderObject();
      Offset position = renderBox.localToGlobal(Offset.zero);
      final topBound = position.dy - 80;
      if (topBound < 0) {
        await Variable.innerScrollController.animateTo(
            Variable.innerScrollController.position.pixels + topBound,
            duration: _innerScrollDuration,
            curve: Curves.fastOutSlowIn);
      }
      double buttonBound = MediaQuery.of(context).size.height -
          Constants.miniPanelHeight -
          position.dy -
          renderBox.size.height;
      if (buttonBound < 0) {
        await Variable.innerScrollController.animateTo(
            max(
                Variable.innerScrollController.position.pixels -
                    buttonBound -
                    (Variable.outerScrollController.position.maxScrollExtent -
                        Variable.outerScrollController.position.pixels),
                0),
            duration: _innerScrollDuration,
            curve: Curves.fastOutSlowIn);
      }
    }
    pushAlbumViewPage(context, widget.album, _image);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tag = widget.album.hashCode.toString() + 'album';
    _loadImages();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: tag,
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: const RoundedRectangleBorder(
          borderRadius: Constants.borderRadius,
        ),
        color: Theme.of(context).primaryColor,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: (Variable.albumIdToSongsMap[widget.album.id] == null ||
                      !_loaded)
                  ? const AnimatedSwitcher(
                      duration: Constants.defaultDuration,
                      child: const SizedBox(),
                    )
                  : AnimatedSwitcher(
                      duration: Constants.defaultDuration,
                      child: _image == null
                          ? Constants.emptyArtwork
                          : Image(
                              image: _image,
                              fit: BoxFit.cover,
                            ),
                    ),
            ),
            ForegroundView(
              album: widget.album,
              onTap: _onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class ForegroundView extends StatelessWidget {
  const ForegroundView({Key key, this.album, this.onTap}) : super(key: key);
  final AlbumInfo album;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Material(
      elevation: 0.0,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AspectRatio(
            aspectRatio: 1 / (Constants.gridDelegateHeight - 1),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 4.0),
                child: FadeTransition(
                  opacity: const AlwaysStoppedAnimation<double>(
                      Constants.textOpacity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 10,
                        child: AutoSizeText(
                          album.title,
                          style: Theme.of(context).textTheme.title,
                          maxLines: 1,
                        ),
                      ),
                      Expanded(
                        flex: 9,
                        child: AutoSizeText(
                          album.artist,
                          style: Theme.of(context).textTheme.body1,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
