import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/data/CustomImageProvider.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../../data/Constants.dart';
import '../../data/Variable.dart';
import 'ArtistViewPage.dart';

const currentPage = 0;

// ignore: must_be_immutable
class ArtistViewItem extends StatelessWidget {
  ArtistViewItem({Key key, this.artist})
      : artistArtworkProvider = ArtistArtworkProvider(artist.id),
        super(key: key);
  final ArtistInfo artist;
  ArtistArtworkProvider artistArtworkProvider;

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
    ArtistViewPage.pushPage(context, artist);
  }

  Widget _builder(BuildContext context, _images, Widget child) {
    return (artistArtworkProvider.imageMap.length >= 2)
        ? AnimatedSwitcher(
            duration: Constants.defaultDuration,
            layoutBuilder: Constants.expendLayoutBuilder,
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
            layoutBuilder: Constants.expendLayoutBuilder,
            child: _images.length == 0
                ? Constants.emptyPersonPicture
                : Image(
                    image: _images[0],
                    fit: BoxFit.cover,
                  ),
          );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: artist.hashCode.toString() + 'artist',
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
                child: ValueListenableBuilder(
                  valueListenable: artistArtworkProvider,
                  builder: _builder,
                ),
              ),
            ),
            ForegroundView(
              artist: artist,
              onTap: () => _onTap(context),
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
