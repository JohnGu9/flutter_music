import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/data/CustomImageProvider.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../../data/Constants.dart';
import '../../data/Variable.dart';
import 'AlbumViewPage.dart';

const currentPage = 1;

// ignore: must_be_immutable
class AlbumViewItem extends StatelessWidget {
  AlbumViewItem({Key key, @required this.album})
      : albumArtworkProvider = AlbumArtworkProvider(album.id),
        super(key: key);

  final AlbumInfo album;
  AlbumArtworkProvider albumArtworkProvider;

  static const _innerScrollDuration = Duration(milliseconds: 335);

  _onTap(BuildContext context) async {
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
    AlbumViewPage.pushPage(context, album);
  }

  static Widget _builder(
      BuildContext context, ImageProvider value, Widget child) {
    return AnimatedSwitcher(
      duration: Constants.defaultDuration,
      layoutBuilder: Constants.expendLayoutBuilder,
      child: value == null
          ? Constants.emptyArtwork
          : Image(
              key: ValueKey(value),
              image: value,
              fit: BoxFit.cover,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: album.hashCode.toString() + 'album',
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape:
            const RoundedRectangleBorder(borderRadius: Constants.borderRadius),
        color: Theme.of(context).primaryColor,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ValueListenableBuilder(
                  valueListenable: albumArtworkProvider,
                  builder: _builder,
                ),
              ),
            ),
            ForegroundView(
              album: album,
              onTap: () => _onTap(context),
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
        onLongPress: () => Feedback.forLongPress(context),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  album.title,
                  style: TextStyle(
                      inherit: true,
                      fontSize: 17,
                      color: Theme.of(context)
                          .textTheme
                          .body1
                          .color
                          .withOpacity(0.9)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  album.artist,
                  style: TextStyle(
                      inherit: true,
                      fontSize: 15,
                      color: Theme.of(context)
                          .textTheme
                          .body1
                          .color
                          .withOpacity(0.6)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
