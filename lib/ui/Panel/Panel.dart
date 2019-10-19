import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

import '../../component/AntiBlockingWidget.dart';
import '../../component/CustomCupertinoPageRoute.dart';
import '../../component/CustomPageView.dart';
import '../../component/CustomValueNotifier.dart';
import '../../component/PockWidget.dart';
import '../../data/Constants.dart';
import '../../data/Variable.dart';
import '../../plugin/MediaPlayer.dart';

const double _kImageWidth = 300;
const double _kImageHeight = 300;

class HeroArtwork extends StatelessWidget {
  const HeroArtwork({Key key, this.songInfo, this.onTap}) : super(key: key);
  final SongInfo songInfo;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: songInfo.hashCode.toString() + 'cover',
      transitionOnUserGestures: true,
      child: ArtWork(
        songInfo: songInfo,
        onTap: onTap,
      ),
    );
  }
}

class ArtWork extends StatefulWidget {
  const ArtWork({Key key, this.songInfo, this.onTap}) : super(key: key);
  final songInfo;
  final onTap;

  @override
  _ArtWorkState createState() => _ArtWorkState();
}

class _ArtWorkState extends State<ArtWork> {
  ImageProvider image;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadImage();
  }

  _loadImage() {
    if (widget.songInfo == null) {
      return;
    }
    Variable.filePathToImageMap.containsKey(widget.songInfo.filePath)
        ? image = Variable.filePathToImageMap[widget.songInfo.filePath]
        : _loadImageAsync();
  }

  _loadImageAsync() async {
    image = await Variable.getArtworkAsync(path: widget.songInfo.filePath);
    await SchedulerBinding.instance.endOfFrame;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Material(
      elevation: 4,
      color: Theme.of(context).primaryColor,
      borderRadius: Constants.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? InkWell(
              onTap: widget.onTap,
              child: const FittedBox(
                fit: BoxFit.contain,
                child: const ScaleTransition(
                  scale: const AlwaysStoppedAnimation<double>(0.5),
                  child: const Icon(Icons.music_note),
                ),
              ),
            )
          : Ink.image(
              image: image,
              fit: BoxFit.cover,
              height: _kImageHeight,
              width: _kImageWidth,
              child: InkWell(
                onTap: widget.onTap,
              ),
            ),
    );
  }
}

class HeroTitle extends StatelessWidget {
  const HeroTitle({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final songInfo = SongInfoInherited.of(context).songInfo;
    return Hero(
      tag: songInfo.hashCode.toString() + 'title',
      transitionOnUserGestures: true,
      flightShuttleBuilder: Constants.fromHeroPriorityFlightShuttleBuilder,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            songInfo == null ? Constants.defaultMusicTitle : songInfo.title,
            style: Theme.of(context).textTheme.title,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class HeroArtist extends StatelessWidget {
  const HeroArtist({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final songInfo = SongInfoInherited.of(context).songInfo;
    return Hero(
      tag: songInfo.hashCode.toString() + 'artist',
      transitionOnUserGestures: true,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            songInfo == null
                ? Constants.defaultMusicArtist
                : (songInfo.artist == '<unknown>'
                    ? songInfo.album
                    : songInfo.artist),
            style: Theme.of(context).textTheme.body2,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

void onRepeat() {
  Variable.playListSequence.nextState();
}


class MiniPanel extends StatelessWidget {
  const MiniPanel({Key key}) : super(key: key);

  static Widget _routeBuilder(BuildContext context) => const FullScreenPanel();

  static Future _generalPushRoute(BuildContext context) async {
    await SchedulerBinding.instance.endOfFrame;
    return await Future.microtask(
      () => Navigator.push(
        context,
        CustomCupertinoPageRoute(builder: _routeBuilder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return PockWidget(
      flingCallBack: (Velocity velocity) {
        if (velocity.pixelsPerSecond.dy.abs() >= 1000) {
          _generalPushRoute(context);
        }
      },
      onTap: () => _generalPushRoute(context),
      child: const ArtworkViewWithAntiBlocking(),
    );
  }
}

class ArtworkViewWithAntiBlocking extends StatelessWidget {
  const ArtworkViewWithAntiBlocking({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AntiBlockingWidget(
      listenable: Variable.panelAntiBlock,
      offset: const Offset(0, Constants.miniPanelHeight + 50),
      child: const MiniPanelArtworkView(),
    );
  }
}

class MiniPanelArtworkView extends StatelessWidget {
  const MiniPanelArtworkView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    // This widget just for layout
    return const Align(
      alignment: Alignment.bottomCenter,
      child: const SizedBox(
        height: Constants.miniPanelHeight,
        child: const ArtworkViewForMiniPanel(),
      ),
    );
  }
}

class ArtworkViewForMiniPanel extends StatefulWidget {
  const ArtworkViewForMiniPanel({Key key}) : super(key: key);

  @override
  _ArtworkViewForMiniPanelState createState() =>
      _ArtworkViewForMiniPanelState();
}

class _ArtworkViewForMiniPanelState extends State<ArtworkViewForMiniPanel> {
  PageController pageController;
  final ValueNotifier<bool> pageControllerIsAnimating =
      ValueNotifier<bool>(false);
  Function() syncItem;
  Function(int) onPageChange;
  CustomValueNotifier<List> _list;
  CustomValueNotifier<SongInfo> _item;

  static Widget _pageViewItemBuilder(BuildContext context, int index) {
    return MiniPanelPageViewItem(
      songInfo: Variable.currentList.value[index],
    );
  }

  _onValueListenableBuild(BuildContext context) {
    _item?.removeListener(syncItem);
    _list = Variable.currentList;
    _item = Variable.currentItem;
    pageController?.dispose();

    if (_item?.value != null && _list.value.contains(_item.value)) {
      final index = _list.value.indexOf(_item.value);
      pageController = PageController(initialPage: index);
    } else {
      pageController = PageController();
    }

    syncItem ??= () {
      if (_item?.value == null || !_list.value.contains(_item.value)) {
        return;
      }
      final int index = _list.value.indexOf(_item.value);
      final double gap = pageController.page - index;
      if (gap.abs() > 0.5) {
        if (pageControllerIsAnimating.value) {
          pageController
              .animateToPage(_list.value.indexOf(_item.value),
                  duration: Constants.defaultDuration, curve: Curves.decelerate)
              .then((value) {
            try {
              if (pageController?.page == _list.value.indexOf(_item.value)) {
                pageControllerIsAnimating.value = false;
              }
            } catch (e) {
              pageControllerIsAnimating.value = false;
            }
          });
          pageControllerIsAnimating.value = true;
        } else {
          pageController
              .animateToPage(_list.value.indexOf(_item.value),
                  duration: Constants.defaultDuration,
                  curve: Curves.fastOutSlowIn)
              .then((value) {
            try {
              if (pageController?.page == _list.value.indexOf(_item.value)) {
                pageControllerIsAnimating.value = false;
              }
            } catch (e) {
              pageControllerIsAnimating.value = false;
            }
          });
          pageControllerIsAnimating.value = true;
        }
      } else {
        if (pageControllerIsAnimating.value) {
          pageController
              .animateToPage(index,
                  duration: Constants.defaultShortDuration,
                  curve: Curves.decelerate)
              .then((value) {
            try {
              if (pageController?.page == _list.value.indexOf(_item.value)) {
                pageControllerIsAnimating.value = false;
              }
            } catch (e) {
              pageControllerIsAnimating.value = false;
            }
          });
        }
      }
    };

    onPageChange ??= (int index) {
      if (!pageControllerIsAnimating.value) {
        _item.value = _list.value[index];
      }
    };

    _item?.addListener(syncItem);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _item?.addListener(syncItem);
    pageController?.dispose();
    pageControllerIsAnimating?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final _pageView = ValueListenableBuilder(
      valueListenable: Variable.currentList,
      builder: (BuildContext context, List list, Widget child) {
        _onValueListenableBuild(context);
        return (Variable.currentItem.value == null ||
                list == null ||
                list.length == 0)
            ? CustomPageView(
                key: const ValueKey(false),
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                children: <Widget>[
                  const MiniPanelPageViewItem(),
                ],
              )
            : CustomPageView.builder(
                key: ValueKey(Variable.currentList.state),
                onPageChanged: onPageChange,
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: _pageViewItemBuilder,
                itemCount: list.length,
              );
      },
    );
    return ValueListenableBuilder(
      valueListenable: pageControllerIsAnimating,
      builder: (BuildContext context, bool isAnimating, Widget child) {
        return AbsorbPointer(
          absorbing: isAnimating,
          child: child,
        );
      },
      child: _pageView,
    );
  }
}

class MiniPanelPageViewItem extends StatelessWidget {
  const MiniPanelPageViewItem({Key key, this.songInfo}) : super(key: key);
  final SongInfo songInfo;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding:
          const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 10.0, top: 3.0),
      child: RepaintBoundary(
        child: SongInfoInherited(
          songInfo: songInfo,
          child: Stack(
            children: <Widget>[
              const MiniPanelPageViewItemBackground(),
              const MiniPanelPageViewItemContent(),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniPanelPageViewItemBackground extends StatelessWidget {
  const MiniPanelPageViewItemBackground({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: SongInfoInherited.of(context).songInfo.hashCode.toString() +
          'background',
      transitionOnUserGestures: true,
      flightShuttleBuilder: Constants.targetFadeInOutFlightShuttleBuilder,
      child: Material(
        color: Colors.transparent,
        elevation: 4.0,
        borderRadius: Constants.borderRadius,
        child: SizedBox.expand(
          child: ClipRRect(
            borderRadius: Constants.borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Material(
                elevation: 0.0,
                color: Theme.of(context)
                    .primaryColor
                    .withOpacity(Constants.panelOpacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MiniPanelPageViewItemContent extends StatelessWidget {
  const MiniPanelPageViewItemContent({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: HeroArtwork(
              songInfo: SongInfoInherited.of(context).songInfo,
              onTap: () {},
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 20, width: 50),
              const SizedBox(height: 20, child: HeroTitle()),
              const SizedBox(height: 15, child: HeroArtist()),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                      width: 0.0, child: const HeroInvalidLeftText()),
                  Hero(
                      tag: SongInfoInherited.of(context)
                              .songInfo
                              .hashCode
                              .toString() +
                          'slider',
                      transitionOnUserGestures: true,
                      child: const Material(
                          color: Colors.transparent,
                          child: const SizedBox(height: 20, width: 50))),
                  const SizedBox(
                      width: 0.0, child: const HeroInvalidRightText()),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 65,
          width: 0,
          child: Hero(
              tag: SongInfoInherited.of(context).songInfo.hashCode.toString() +
                  'skip_previous',
              transitionOnUserGestures: true,
              flightShuttleBuilder:
                  Constants.targetPriorityFlightShuttleBuilder,
              child: const Material()),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: SizedBox(
            height: 65,
            width: 65,
            child: Hero(
                tag:
                    SongInfoInherited.of(context).songInfo.hashCode.toString() +
                        'play',
                transitionOnUserGestures: true,
                child: const HeroPlayButton()),
          ),
        ),
        SizedBox(
          height: 65,
          width: 0,
          child: Hero(
              tag: SongInfoInherited.of(context).songInfo.hashCode.toString() +
                  'skip_next',
              transitionOnUserGestures: true,
              flightShuttleBuilder:
                  Constants.targetPriorityFlightShuttleBuilder,
              child: const Material()),
        ),
      ],
    );
  }
}

const _kEdgeTouchPretestWidth = 30.0;

class FullScreenPanel extends StatelessWidget {
  const FullScreenPanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Stack(
      fit: StackFit.expand,
      children: const <Widget>[
        const HidePanel(),
        const ForePanel(),
      ],
    );
  }
}

class ForePanel extends StatefulWidget {
  const ForePanel({Key key}) : super(key: key);

  @override
  _ForePanelState createState() => _ForePanelState();
}

class _ForePanelState extends State<ForePanel>
    with SingleTickerProviderStateMixin {
  static final ValueNotifier<Offset> offsetController =
      ValueNotifier<Offset>(Offset.zero);
  static Offset _startOffset;
  static Offset _startPoint;

  AnimationController _controller;
  Animation _offsetAnimation;

  Widget _builder(BuildContext context, Offset offset, Widget child) {
    return Transform.translate(offset: offset, child: child);
  }

  _onVerticalDragStart(DragStartDetails details) {
    _controller.stop();
    _startOffset = offsetController.value;
    _startPoint = details.globalPosition;
  }

  static const _minHide = _kHidePanelMiniHeight - _kHidePanelFullHeight;
  static const _maxHide = 0;
  static const _midHide = (_minHide + _maxHide) / 2;

  static const _openOffset = Offset(0, _minHide);
  static const _closeOffset = Offset.zero;

  _onVerticalDragUpdate(DragUpdateDetails details) {
    double newy = _startOffset.dy + details.globalPosition.dy - _startPoint.dy;
    if (newy < _minHide) {
      newy = _minHide;
    } else if (newy > _maxHide) {
      newy = 0;
    }
    offsetController.value = Offset(0, newy);
  }

  _onVerticalDragEnd(DragEndDetails details) async {
    final dy = details.velocity.pixelsPerSecond.dy;
    if (dy.abs() > 100) {
      dy < 0 ? _open(dy.abs() / 100) : _close(dy.abs() / 100);
    } else if (offsetController.value != Offset.zero) {
      offsetController.value.dy < _midHide ? _open(1) : _close(1);
    }
  }

  _open(double velocity) {
    _offsetAnimation = Tween<Offset>(
            begin: offsetController.value, end: _openOffset)
        .animate(_controller)
          ..addListener(() => offsetController.value = _offsetAnimation.value);
    _controller.reset();
    _controller.fling(velocity: velocity);
  }

  _close(double velocity) {
    _offsetAnimation = Tween<Offset>(
            begin: offsetController.value, end: _closeOffset)
        .animate(_controller)
          ..addListener(() => offsetController.value = _offsetAnimation.value);
    _controller.reset();
    _controller.fling(velocity: velocity);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    offsetController.value = _closeOffset;
    _controller = AnimationController(
      vsync: this,
      duration: Constants.defaultDuration,
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: ValueListenableBuilder(
        valueListenable: offsetController,
        builder: _builder,
        child: const Align(
          alignment: Alignment.topCenter,
          child: const ForePanelContent(),
        ),
      ),
    );
  }
}

class ForePanelContent extends StatelessWidget {
  const ForePanelContent({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SizedBox(
      height: MediaQuery.of(context).size.height - _kHidePanelMiniHeight,
      child: Stack(
        fit: StackFit.expand,
        children: const <Widget>[
          const FullScreenPanelBackground(),
          const FullScreenPanelContent(),
          // Edge touch pretest
          const PositionedDirectional(
            start: 0.0,
            width: _kEdgeTouchPretestWidth,
            top: 0.0,
            bottom: 0.0,
            child: Listener(
              onPointerDown: null,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          const PositionedDirectional(
            width: _kEdgeTouchPretestWidth,
            end: 0.0,
            top: 0.0,
            bottom: 0.0,
            child: Listener(
              onPointerDown: null,
              behavior: HitTestBehavior.opaque,
            ),
          ),
        ],
      ),
    );
  }
}

const double _kHidePanelFullHeight = 170;
const double _kHidePanelMiniHeight = 60;

class HidePanel extends StatelessWidget {
  const HidePanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 0.0,
        borderRadius: const BorderRadius.only(
            topRight: Constants.radius, topLeft: Constants.radius),
        color: Theme.of(context).backgroundColor,
        child: Container(
          decoration: const BoxDecoration(
              gradient: const LinearGradient(
            // Where the linear gradient begins and ends
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Add one stop for each color. Stops should increase from 0 to 1
            stops: const [0.0, 0.3, 0.9],
            colors: const [
              Colors.black12,
              Colors.black12,
              Colors.transparent,
            ],
          )),
          child: const SizedBox(
            height: _kHidePanelFullHeight,
            child: const HidePanelContent(),
          ),
        ),
      ),
    );
  }
}

class HidePanelContent extends StatelessWidget {
  const HidePanelContent({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        const HidePanelExtendContent(),
        const HidePanelBasicContent(),
      ],
    );
  }
}

class HidePanelBasicContent extends StatelessWidget {
  const HidePanelBasicContent({Key key}) : super(key: key);

  Widget _builder(BuildContext context, SongInfo songInfo, Widget child) {
    return SongInfoInherited(
      songInfo: songInfo,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: Variable.currentItem,
      builder: _builder,
      child: SizedBox(
        height: _kHidePanelMiniHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            const SizedBox(width: 50, child: const RepeatButton()),
            const SizedBox(width: 50, child: const FavoriteButton()),
          ],
        ),
      ),
    );
  }
}

class HidePanelExtendContent extends StatelessWidget {
  const HidePanelExtendContent({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SizedBox(
      height: _kHidePanelFullHeight - _kHidePanelMiniHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: const Align(
              alignment: Alignment.topCenter,
              child: Icon(Icons.expand_more),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              const VerticalDivider(),
              const Material(
                  color: Colors.transparent,
                  elevation: 0.0,
                  child: const Icon(Icons.volume_down)),
              const VolumeSlider(),
              const Material(
                  color: Colors.transparent,
                  elevation: 0.0,
                  child: const Icon(Icons.volume_up)),
              const VerticalDivider(),
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenPanelBackground extends StatefulWidget {
  const FullScreenPanelBackground({Key key}) : super(key: key);

  @override
  _FullScreenPanelBackgroundState createState() =>
      _FullScreenPanelBackgroundState();
}

class _FullScreenPanelBackgroundState extends State<FullScreenPanelBackground> {
  SongInfo songInfo;
  final _valueListenable = Variable.currentItem;

  _onInitState() {
    songInfo = _valueListenable.value;
    if (songInfo != null) {
      ImageSwitcherWidget.imageNotifier.value =
          Variable.filePathToImageMap[songInfo.filePath];
    }
  }

  _loadImage() => setState(() {
        songInfo = _valueListenable.value;
        _loadImageAsync();
      });

  void _loadImageAsync() async {
    await Future.delayed(const Duration(milliseconds: 150));
    await Future.wait([
      Variable.getArtworkAsync(path: songInfo?.filePath),
      Future.delayed(const Duration(milliseconds: 50)),
    ]);
    await SchedulerBinding.instance.endOfFrame;
    ImageSwitcherWidget.imageNotifier.value = songInfo == null
        ? null
        : Variable.filePathToImageMap[songInfo.filePath];
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _onInitState();
    _valueListenable.addListener(_loadImage);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _valueListenable.removeListener(_loadImage);
  }

  static const borderRadius = const BorderRadius.only(
      bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15));

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: songInfo.hashCode.toString() + 'background',
      transitionOnUserGestures: true,
      flightShuttleBuilder: Constants.targetFadeInOutFlightShuttleBuilder,
      child: Material(
        elevation: 4.0,
        color: Theme.of(context).backgroundColor,
        clipBehavior: Clip.antiAlias,
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: const <Widget>[
            const ImageSwitcherWidget(),
            const BlurWidget(),
          ],
        ),
      ),
    );
  }
}

class ImageSwitcherWidget extends StatelessWidget {
  const ImageSwitcherWidget({Key key}) : super(key: key);
  static final CustomValueNotifier<ImageProvider> imageNotifier =
      CustomValueNotifier<ImageProvider>(null);

  static Widget _builder(
      BuildContext context, ImageProvider image, Widget child) {
    return AnimatedSwitcher(
      duration: Constants.defaultDuration,
      child: SizedBox.expand(
        key: ValueKey(image),
        child: image == null
            ? const SizedBox()
            : Image(
                image: image,
                width: 5,
                height: 5,
                filterQuality: FilterQuality.none,
                fit: BoxFit.cover,
                color: const Color.fromRGBO(255, 255, 255, 0.2),
                colorBlendMode: BlendMode.modulate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: imageNotifier,
      builder: _builder,
    );
  }
}

class BlurWidget extends StatelessWidget {
  const BlurWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ClipRRect(
      borderRadius: _FullScreenPanelBackgroundState.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: const Material(
          color: Colors.transparent,
        ),
      ),
    );
  }
}

class FullScreenPanelContent extends StatelessWidget {
  const FullScreenPanelContent({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const <Widget>[
          const FullScreenPanelArtworkPageView(),
          const FullScreenPanelController(),
        ],
      ),
    );
  }
}

class FullScreenPanelArtworkPageView extends StatelessWidget {
  const FullScreenPanelArtworkPageView({Key key}) : super(key: key);

// This widget is for ArtworkPageView layout
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.width * 1.1,
      ),
      child: const ArtworkPageViewForFullScreenPanel(),
    );
  }
}

class ArtworkPageViewForFullScreenPanel extends StatefulWidget {
  const ArtworkPageViewForFullScreenPanel({Key key}) : super(key: key);

  @override
  _ArtworkPageViewForFullScreenPanelState createState() =>
      _ArtworkPageViewForFullScreenPanelState();
}

class _ArtworkPageViewForFullScreenPanelState
    extends State<ArtworkPageViewForFullScreenPanel> {
  final ValueNotifier<bool> pageControllerIsAnimating =
      ValueNotifier<bool>(false);
  PageController pageController;
  Function() syncItem;
  Function(int) onPageChange;
  CustomValueNotifier _list;
  CustomValueNotifier _item;

  _onValueListenableBuild(BuildContext context) {
    _item?.removeListener(syncItem);
    _list = Variable.currentList;
    _item = Variable.currentItem;
    pageController?.dispose();

    if (_item?.value != null && _list.value.contains(_item.value)) {
      final index = _list.value.indexOf(_item.value);
      pageController = PageController(initialPage: index);
      //debugPrint('initialPage: ' + index.toString());
    } else {
      pageController = PageController();
      //debugPrint('initialPage: null');
    }

    syncItem ??= () async {
      if (_item?.value == null || !_list.value.contains(_item.value)) {
        debugPrint('list dont contains item');
        return;
      }
      final int index = _list.value.indexOf(_item.value);
      // debugPrint('index: ' + index.toString());

      if ((pageController.page - index).abs() > 0.5) {
        debugPrint('pageControllerIsAnimating');
        if (pageControllerIsAnimating.value) {
          pageController
              .animateToPage(index,
                  duration: Constants.defaultDuration, curve: Curves.decelerate)
              .then((value) {
            try {
              if (pageController?.page == _list.value.indexOf(_item.value)) {
                pageControllerIsAnimating.value = false;
              }
            } catch (e) {
              pageControllerIsAnimating.value = false;
            }
          });
          pageControllerIsAnimating.value = true;
        } else {
          pageController
              .animateToPage(index,
                  duration: Constants.defaultDuration,
                  curve: Curves.fastOutSlowIn)
              .then((value) {
            try {
              if (pageController?.page == _list.value.indexOf(_item.value)) {
                pageControllerIsAnimating.value = false;
              }
            } catch (e) {
              pageControllerIsAnimating.value = false;
            }

            // debugPrint('pageController.page == index?: ' + (pageController.page == index).toString());
          });
          pageControllerIsAnimating.value = true;
        }
      } else {
        if (pageControllerIsAnimating.value) {
          pageController
              .animateToPage(index,
                  duration: Constants.defaultShortDuration,
                  curve: Curves.decelerate)
              .then((value) {
            try {
              if (pageController?.page == _list.value.indexOf(_item.value)) {
                pageControllerIsAnimating.value = false;
              }
            } catch (e) {
              pageControllerIsAnimating.value = false;
            }
          });
        }
      }
    };

    onPageChange ??= (int index) {
      if (!pageControllerIsAnimating.value) {
        _item.value = _list.value[index];
      }
    };

    _item?.addListener(syncItem);
  }

  static Widget _pageViewItemBuilder(BuildContext context, int index) {
    return FullScreenPanelPageViewItem(
        songInfo: Variable.currentList.value[index]);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _item?.removeListener(syncItem);
    pageController?.dispose();
    pageControllerIsAnimating?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final _pageView = ValueListenableBuilder(
      valueListenable: Variable.currentList,
      builder: (BuildContext context, List list, Widget child) {
        _onValueListenableBuild(context);
        return (Variable.currentItem.value == null ||
                list == null ||
                list.length == 0)
            ? CustomPageView(
                key: const ValueKey(false),
                physics: const BouncingScrollPhysics(),
                controller: pageController,
                children: <Widget>[const FullScreenPanelPageViewItem()],
              )
            : CustomPageView.builder(
                key: ValueKey(Variable.currentList.state),
                onPageChanged: onPageChange,
                controller: pageController,
                physics: const BouncingScrollPhysics(),
                itemBuilder: _pageViewItemBuilder,
                itemCount: list.length,
              );
      },
    );
    return ValueListenableBuilder(
      valueListenable: pageControllerIsAnimating,
      builder: (BuildContext context, bool isAnimating, Widget child) {
        return AbsorbPointer(
          absorbing: isAnimating,
          child: child,
        );
      },
      child: RepaintBoundary(child: _pageView),
    );
  }
}

class FullScreenPanelPageViewItem extends StatefulWidget {
  const FullScreenPanelPageViewItem({Key key, this.songInfo}) : super(key: key);
  final SongInfo songInfo;

  @override
  _FullScreenPanelPageViewItemState createState() =>
      _FullScreenPanelPageViewItemState();
}

class _FullScreenPanelPageViewItemState
    extends State<FullScreenPanelPageViewItem>
    with AutomaticKeepAliveClientMixin<FullScreenPanelPageViewItem> {
  Widget _artwork;

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _artwork = HeroArtwork(
      songInfo: widget.songInfo,
      onTap: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SongInfoInherited(
        songInfo: widget.songInfo,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: _artwork,
              ),
            ),
            const SizedBox(height: 30, child: const HeroTitle()),
            const SizedBox(height: 20, child: const HeroArtist()),
          ],
        ),
      ),
    );
  }
}

class FullScreenPanelController extends StatelessWidget {
  const FullScreenPanelController({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: const Material(
        elevation: 0.0,
        color: Colors.transparent,
        child: const FullScreenPanelControllerLayout(),
      ),
    );
  }
}

class FullScreenPanelControllerLayout extends StatelessWidget {
  const FullScreenPanelControllerLayout({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: Variable.currentItem,
      builder: (BuildContext context, SongInfo songInfo, Widget child) {
        return SongInfoInherited(
          songInfo: songInfo,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                children: const <Widget>[
                  const VerticalDivider(),
                  const HeroLeftText(),
                  const Expanded(child: const AnimatedProgressSlider()),
                  const HeroRightText(),
                  const VerticalDivider(),
                ],
              ),
              SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const VerticalDivider(
                      width: 5,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 70),
                      child: Hero(
                          tag: songInfo.hashCode.toString() + 'skip_previous',
                          transitionOnUserGestures: true,
                          flightShuttleBuilder:
                              Constants.targetPriorityFlightShuttleBuilder,
                          child: const SkipPreviousButton()),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 100),
                      child: Hero(
                          tag: songInfo.hashCode.toString() + 'play',
                          transitionOnUserGestures: true,
                          child: const HeroPlayButton()),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 70),
                      child: Hero(
                          tag: songInfo.hashCode.toString() + 'skip_next',
                          transitionOnUserGestures: true,
                          flightShuttleBuilder:
                              Constants.targetPriorityFlightShuttleBuilder,
                          child: const SkipNextButton()),
                    ),
                    const VerticalDivider(
                      width: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SongInfoInherited extends InheritedWidget {
  const SongInfoInherited({Key key, this.songInfo, this.child})
      : super(key: key);
  final SongInfo songInfo;
  final Widget child;

  static SongInfoInherited of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(SongInfoInherited);
  }

  @override
  bool updateShouldNotify(SongInfoInherited oldWidget) =>
      // TODO: implement updateShouldNotify
      oldWidget.songInfo != this.songInfo;
}

class HeroInvalidLeftText extends StatelessWidget {
  const HeroInvalidLeftText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: SongInfoInherited.of(context).songInfo.hashCode.toString() + 'left',
      transitionOnUserGestures: true,
      flightShuttleBuilder: Constants.targetPriorityFlightShuttleBuilder,
      child: const Material(),
    );
  }
}

class HeroLeftText extends StatelessWidget {
  const HeroLeftText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: SongInfoInherited.of(context).songInfo.hashCode.toString() + 'left',
      transitionOnUserGestures: true,
      flightShuttleBuilder: Constants.targetPriorityFlightShuttleBuilder,
      child: const FittedBox(
        fit: BoxFit.contain,
        child: const Material(
          elevation: 0.0,
          color: Colors.transparent,
          child: const LeftText(),
        ),
      ),
    );
  }
}

class LeftText extends StatelessWidget {
  const LeftText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: MediaPlayer.currentPositionNotifier,
      builder: (BuildContext context, int position, Widget child) {
        int mtTime = position ~/ 1000;
        return Text(
          (mtTime ~/ 60).toString().padLeft(2, '0') +
              ':' +
              (mtTime % 60).toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.body2,
        );
      },
    );
  }
}

class HeroInvalidRightText extends StatelessWidget {
  const HeroInvalidRightText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: SongInfoInherited.of(context).songInfo.hashCode.toString() + 'right',
      transitionOnUserGestures: true,
      flightShuttleBuilder: Constants.targetPriorityFlightShuttleBuilder,
      child: const Material(),
    );
  }
}

class HeroRightText extends StatelessWidget {
  const HeroRightText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Hero(
      tag: SongInfoInherited.of(context).songInfo.hashCode.toString() + 'right',
      transitionOnUserGestures: true,
      flightShuttleBuilder: Constants.targetPriorityFlightShuttleBuilder,
      child: const FittedBox(
        fit: BoxFit.contain,
        child: const Material(
          elevation: 0.0,
          color: Colors.transparent,
          child: const RightText(),
        ),
      ),
    );
  }
}

class RightText extends StatelessWidget {
  const RightText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: MediaPlayer.currentPositionNotifier,
      builder: (BuildContext context, int position, Widget child) {
        int leftTime = (MediaPlayer.currentDuration - position) ~/ 1000;
        return Text(
          (leftTime ~/ 60).toString().padLeft(2, '0') +
              ':' +
              (leftTime % 60).toString().padLeft(2, '0'),
          style: Theme.of(context).textTheme.body2,
        );
      },
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: const InkWell(
        onTap: onRepeat,
        child: const Padding(
          padding: const EdgeInsets.all(15),
          child: const SizedBox.expand(
            child: const FittedBox(
              fit: BoxFit.contain,
              child: const RepeatButtonIcon(),
            ),
          ),
        ),
      ),
    );
  }
}

class RepeatButtonIcon extends StatelessWidget {
  const RepeatButtonIcon({Key key}) : super(key: key);

  Widget getIcon(PlayListSequenceStatus state) {
    switch (state) {
      case PlayListSequenceStatus.repeat:
        return const Icon(
          Icons.repeat,
          key: ValueKey(1),
        );
      case PlayListSequenceStatus.shuffle:
        return const Icon(
          Icons.shuffle,
          key: ValueKey(2),
        );
      case PlayListSequenceStatus.repeat_one:
        return const Icon(
          Icons.repeat_one,
          key: ValueKey(3),
        );
      default:
        return const Icon(Icons.repeat);
    }
  }

  Widget _valueListenableBuilder(
          BuildContext context, int state, Widget child) =>
      AnimatedSwitcher(
        duration: Constants.defaultDuration,
        child: getIcon(PlayListSequenceStatus.values[state]),
      );

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ValueListenableBuilder(
      valueListenable: Variable.playListSequence.stateChangeNotifier,
      builder: _valueListenableBuilder,
    );
  }
}

class SkipPreviousButton extends StatelessWidget {
  const SkipPreviousButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: const InkWell(
        onTap: MediaPlayer.onSkipPrevious,
        child: const Padding(
          padding: const EdgeInsets.all(20),
          child: const SizedBox.expand(
            child: const FittedBox(
              fit: BoxFit.contain,
              child: const Icon(Icons.skip_previous),
            ),
          ),
        ),
      ),
    );
  }
}

class PreviousButton extends StatelessWidget {
  const PreviousButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: const InkWell(
        onTap: MediaPlayer.onSkipPrevious,
        child: const Padding(
          padding: const EdgeInsets.all(20),
          child: const SizedBox.expand(
            child: const FittedBox(
              fit: BoxFit.contain,
              child: const Icon(Icons.skip_previous),
            ),
          ),
        ),
      ),
    );
  }
}

class HeroPlayButton extends StatelessWidget {
  const HeroPlayButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: const InkWell(
        onTap: MediaPlayer.onPlay,
        child: const Padding(
          padding: const EdgeInsets.all(20),
          child: const SizedBox.expand(
            child: const FittedBox(
              fit: BoxFit.contain,
              child: const PlayButtonIcon(),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: const InkWell(
        onTap: MediaPlayer.onPlay,
        child: const Padding(
          padding: const EdgeInsets.all(20),
          child: const SizedBox.expand(
            child: const FittedBox(
              fit: BoxFit.contain,
              child: const PlayButtonIcon(),
            ),
          ),
        ),
      ),
    );
  }
}

class PlayButtonIcon extends StatelessWidget {
  const PlayButtonIcon({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: Variable.playButtonController);
  }
}

class SkipNextButton extends StatelessWidget {
  const SkipNextButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: const InkWell(
        onTap: MediaPlayer.onSkipNext,
        child: const Padding(
          padding: const EdgeInsets.all(20),
          child: const SizedBox.expand(
            child: const FittedBox(
              fit: BoxFit.contain,
              child: const Icon(Icons.skip_next),
            ),
          ),
        ),
      ),
    );
  }
}

class NextButton extends StatelessWidget {
  const NextButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: const InkWell(
        onTap: MediaPlayer.onSkipNext,
        child: const Padding(
          padding: const EdgeInsets.all(20),
          child: const SizedBox.expand(
            child: const FittedBox(
              fit: BoxFit.contain,
              child: const Icon(Icons.skip_next),
            ),
          ),
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const Material(
      elevation: 0.0,
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: const FavoriteButtonBody(),
    );
  }
}

class FavoriteButtonBody extends StatelessWidget {
  const FavoriteButtonBody({Key key}) : super(key: key);

  Widget _valueListenableBuilder(
      BuildContext context, List list, Widget child) {
    if (list == null) {
      return AnimatedSwitcher(
          key: ValueKey(SongInfoInherited.of(context)?.songInfo),
          duration: Constants.defaultDuration,
          child: const Icon(Icons.favorite_border, key: ValueKey(false)));
    }
    return AnimatedSwitcher(
      key: ValueKey(SongInfoInherited.of(context)?.songInfo),
      duration: Constants.defaultDuration,
      child: list.contains(Variable.currentItem.value)
          ? const Icon(Icons.favorite, key: ValueKey(true))
          : const Icon(Icons.favorite_border, key: ValueKey(false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return InkWell(
      onTap: () =>
//        debugPrint(SongInfoInherited.of(context)?.songInfo.toString());
          onFavorite(SongInfoInherited.of(context)?.songInfo),
      child: Padding(
        padding: EdgeInsets.all(15),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.contain,
            child: ValueListenableBuilder(
              valueListenable: Variable.favouriteList,
              builder: _valueListenableBuilder,
            ),
          ),
        ),
      ),
    );
  }
}

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({Key key}) : super(key: key);

  @override
  _VolumeSliderState createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider>
    with SingleTickerProviderStateMixin {
  ValueNotifier<double> _controller;
  bool _sliderShouldChange = true;
  static const int volumeSteps = 100;

  _controllerListener() => setState(() {});

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = ValueNotifier(MediaPlayer.volume)
      ..addListener(_controllerListener);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    super.dispose();
  }

  _onChangeStart(double value) {
    if (_sliderShouldChange) {
      _controller.value = value;
      MediaPlayer.volume = value;
    }
  }

  _onChanged(double value) {
    if (_sliderShouldChange) {
      MediaPlayer.volume = value;
      _controller.value = value;
    }
  }

  _onChangeEnd(double value) {
    if (_sliderShouldChange) {
      MediaPlayer.volume = value;
      _controller.value = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return RepaintBoundary(
      child: Slider(
        inactiveColor: Theme.of(context).brightness == Brightness.light
            ? Constants.darkGrey.withOpacity(0.5)
            : Constants.lightGrey.withOpacity(0.5),
        activeColor: Theme.of(context).brightness == Brightness.light
            ? Constants.darkGrey
            : Constants.lightGrey,
        label: (_controller.value * 100).toInt().toString() + '%',
        value: _controller.value,
        onChangeStart: _onChangeStart,
        onChanged: _onChanged,
        onChangeEnd: _onChangeEnd,
      ),
    );
  }
}

class AnimatedProgressSlider extends StatelessWidget {
  const AnimatedProgressSlider({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return IgnorePointer(
      ignoring: SongInfoInherited.of(context).songInfo == null,
      child: Hero(
        tag: SongInfoInherited.of(context).songInfo.hashCode.toString() +
            'slider',
        flightShuttleBuilder: Constants.targetPriorityFlightShuttleBuilder,
        transitionOnUserGestures: true,
        child: const RepaintBoundary(
          child: const Material(
            elevation: 0.0,
            color: Colors.transparent,
            child: const ProgressSlider(),
          ),
        ),
      ),
    );
  }
}

class ProgressSlider extends StatefulWidget {
  const ProgressSlider({Key key}) : super(key: key);

  @override
  _ProgressSliderState createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  bool _sliderShouldChange = true;

  _updateSlider() => _sliderShouldChange
      ? _controller.animateTo(
          MediaPlayer.currentPosition / MediaPlayer.currentDuration,
          curve: Curves.fastOutSlowIn)
      : null;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
        value: MediaPlayer.currentPosition / MediaPlayer.currentDuration)
      ..addListener(() async => setState(() {}));
    MediaPlayer.currentPositionNotifier.addListener(_updateSlider);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    MediaPlayer.currentPositionNotifier.removeListener(_updateSlider);
    _controller.dispose();
    super.dispose();
  }

  _onChangeStart(double value) {
    _sliderShouldChange = false;
    _controller.value = value;
  }

  _onChanged(double value) => _controller.value = value;

  _onChangeEnd(double value) {
    _sliderShouldChange = true;
    if ((MediaPlayer.currentPosition / MediaPlayer.currentDuration - value)
            .abs() <
        0.05) {
      return;
    }
    if (MediaPlayer.status == MediaPlayerStatus.prepared ||
        MediaPlayer.status == MediaPlayerStatus.started ||
        MediaPlayer.status == MediaPlayerStatus.paused ||
        MediaPlayer.status == MediaPlayerStatus.playbackCompleted) {
      MediaPlayer.seekTo((value * MediaPlayer.currentDuration).toInt());
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Slider(
      inactiveColor: Theme.of(context).brightness == Brightness.light
          ? Constants.darkGrey.withOpacity(0.5)
          : Constants.lightGrey.withOpacity(0.5),
      activeColor: Theme.of(context).brightness == Brightness.light
          ? Constants.darkGrey
          : Constants.lightGrey,
      label: ((_controller.value * MediaPlayer.currentDuration / 1000) ~/ 60)
              .toString()
              .padLeft(2, '0') +
          ':' +
          ((_controller.value * MediaPlayer.currentDuration / 1000) % 60)
              .toInt()
              .toString()
              .padLeft(2, '0'),
      value: _controller.value,
      onChangeStart: _onChangeStart,
      onChanged: _onChanged,
      onChangeEnd: _onChangeEnd,
    );
  }
}
