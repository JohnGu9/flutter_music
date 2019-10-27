import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import 'ArtistViewPage.dart';

const currentPage = 0;

class ArtistViewItem extends StatefulWidget {
  const ArtistViewItem({Key key, this.artist}) : super(key: key);
  final ArtistInfo artist;

  @override
  _ArtistViewItemState createState() => _ArtistViewItemState();
}

class _ArtistViewItemState extends State<ArtistViewItem> {
  List<ImageProvider> _images;
  bool _loaded = false;
  String heroTag;

  _loadImage() {
    if (Variable.artistIdToImagesMap.containsKey(widget.artist.id)) {
      _images = Variable.artistIdToImagesMap[widget.artist.id];
      _loaded = true;
    } else {
      _loadImagesAsync();
    }
  }

  _loadImagesAsync() async {
    await SchedulerBinding.instance.endOfFrame;
    _images = List();
    final albums =
        await Variable.audioQuery.getAlbumsFromArtist(artist: widget.artist);
    final allSongs = List<SongInfo>.from(Variable.artistIdToSongsMap[widget.artist.id]);
    bool loadMore = true;

    for (final album in albums) {
      await SchedulerBinding.instance.endOfFrame;
      final songs = Variable.albumIdToSongsMap[album.id];
      if (songs == null) {
        continue;
      }
      allSongs.removeWhere((item) => songs.contains(item));
      final ImageProvider image = await Variable.getImageFromSongs(songs);
      if (image != null) {
        _images.add(image);
        // only load four available images
        if (_images.length >= 4) {
          // cancel load more images mission
          loadMore = false;
          break;
        }
      }
    }
    if (loadMore) {
      _images.addAll(await Variable.getImagesFromSongs(allSongs));
    }

    Variable.artistIdToImagesMap[widget.artist.id] = _images;
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
    pushArtistViewPage(context, widget.artist);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadImage();
    heroTag = widget.artist.hashCode.toString() + 'artist';
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: heroTag,
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
              child: AspectRatio(
                aspectRatio: 1,
                child: (!_loaded)
                    ? const AnimatedSwitcher(
                        duration: Constants.defaultDuration,
                        child: const SizedBox(),
                      )
                    : (_images.length >= 2)
                        ? AnimatedSwitcher(
                            duration: Constants.defaultDuration,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Transform(
                                  transform: Matrix4.identity()..scale(0.5),
                                  alignment: Alignment.bottomLeft,
                                  child: _images.length >= 4
                                      ? Image(
                                          image: _images[3],
                                          fit: BoxFit.cover,
                                        )
                                      : Constants.emptyArtwork,
                                ),
                                Transform(
                                  transform: Matrix4.identity()..scale(0.5),
                                  alignment: Alignment.topRight,
                                  child: _images.length >= 3
                                      ? Image(
                                          image: _images[2],
                                          fit: BoxFit.cover,
                                        )
                                      : Constants.emptyArtwork,
                                ),
                                Transform(
                                  transform: Matrix4.identity()..scale(0.5),
                                  alignment: Alignment.bottomRight,
                                  child: _images.length >= 2
                                      ? Image(
                                          image: _images[1],
                                          fit: BoxFit.cover,
                                        )
                                      : Constants.emptyArtwork,
                                ),
                                Transform(
                                  transform: Matrix4.identity()..scale(0.5),
                                  alignment: Alignment.topLeft,
                                  child: _images.length >= 1
                                      ? Image(
                                          image: _images[0],
                                          fit: BoxFit.cover,
                                        )
                                      : Constants.emptyArtwork,
                                ),
                              ],
                            ),
                          )
                        : AnimatedSwitcher(
                            duration: Constants.defaultDuration,
                            child: _images.length == 0
                                ? Constants.emptyPersonPicture
                                : Image(
                                    image: _images[0],
                                    fit: BoxFit.contain,
                                  ),
                          ),
              ),
            ),
            ForegroundView(
              artist: widget.artist,
              onTap: _onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class ForegroundView extends StatelessWidget {
  const ForegroundView({Key key, this.artist, this.onTap}) : super(key: key);
  final ArtistInfo artist;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Material(
      elevation: 0.0,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => Feedback.forLongPress(context),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AspectRatio(
            aspectRatio: 1 / (Constants.gridDelegateHeight - 1),
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: FadeTransition(
                  opacity: const AlwaysStoppedAnimation<double>(
                      Constants.textOpacity),
                  child: AutoSizeText(
                    artist.name,
                    style: Theme.of(context).textTheme.body1,
                    maxLines: 2,
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
