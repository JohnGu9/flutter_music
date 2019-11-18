import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/component/CustomPageRoute.dart';
import 'package:flutter_app/data/Constants.dart';
import 'package:flutter_app/data/Variable.dart';
import 'package:flutter_app/plugin/MediaMetadataRetriever.dart';

class Setting extends StatelessWidget {
  const Setting({Key key}) : super(key: key);
  static const opacityForSubText = const AlwaysStoppedAnimation(0.5);

  static pushPage(BuildContext context, Offset startPoint) async {
    await SchedulerBinding.instance.endOfFrame;
    Future.microtask(() => Navigator.push(
        context,
        CustomPageRoute(
          builder: _builder,
          transitionBuilder: CustomPageRoute.clipOvalTransition(startPoint),
          transitionDuration: const Duration(milliseconds: 600),
        )));
  }

  static Widget _builder(BuildContext context) => const Setting();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: CustomScrollView(
        cacheExtent: 100,
        slivers: <Widget>[
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 4.0,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            actions: <Widget>[
              Material(
                color: Colors.transparent,
                elevation: 0.0,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: Icon(Icons.trip_origin),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              title: Row(
                children: <Widget>[
                  //const Icon(Icons.brightness_1),
                  const Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0)),
                  Padding(
                    padding: Constants.AppBarTitlePadding,
                    child: Text('Setting', style: Theme.of(context).textTheme.title),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    // Where the linear gradient begins and ends
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Add one stop for each color. Stops should increase from 0 to 1
                    stops: const [0.1, 0.9],
                    colors: [
                      // Colors are easy thanks to Flutter's Colors class.
                      Color.alphaBlend(Colors.blueGrey.withOpacity(0.1),
                          Theme.of(context).backgroundColor),
                      Theme.of(context).backgroundColor,
                    ],
                  ),
                ),
              ),
            ),
            backgroundColor: Theme.of(context).backgroundColor,
          ),
          const SliverToBoxAdapter(
            child: ThemeController(),
          ),
          const SliverToBoxAdapter(
            child: NetworkController(),
          ),
          const SliverToBoxAdapter(
            child: NotificationController(),
          ),
          const SliverToBoxAdapter(
            child: About(),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Constants.ListViewEndWidget,
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeController extends StatefulWidget {
  const ThemeController({Key key}) : super(key: key);

  @override
  _ThemeControllerState createState() => _ThemeControllerState();
}

class _ThemeControllerState extends State<ThemeController> {
  _onChanged(value) {
    setState(() => Variable.themeSwitch.value = value);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        const Divider(height: 30),
        ListTile(
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Theme',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          trailing: const Icon(Icons.palette),
        ),
        RadioListTile<String>(
          value: Variable.autoTheme,
          title: Text(Variable.autoTheme),
          subtitle: FadeTransition(
            opacity: Setting.opacityForSubText,
            child: Text(
              'Depend on system theme',
              style: Theme.of(context).textTheme.body2,
            ),
          ),
          groupValue: Variable.themeSwitch.value,
          onChanged: _onChanged,
        ),
        RadioListTile<String>(
          value: Variable.lightTheme,
          title: Text(Variable.lightTheme),
          groupValue: Variable.themeSwitch.value,
          onChanged: _onChanged,
        ),
        RadioListTile<String>(
          value: Variable.darkTheme,
          title: Text(Variable.darkTheme),
          groupValue: Variable.themeSwitch.value,
          onChanged: _onChanged,
        ),
      ],
    );
  }
}

class NetworkController extends StatefulWidget {
  const NetworkController({Key key}) : super(key: key);

  @override
  _NetworkControllerState createState() => _NetworkControllerState();
}

class _NetworkControllerState extends State<NetworkController> {
  ValueNotifier<int> fileSize;

  getFileSize() async {
    fileSize.value = await Variable.cacheRemotePicture.getSize();
  }

  _clearCache(BuildContext context) async {
    final res = await showCupertinoDialog(context: context, builder: _dialog);
    if (res[0]) {
      fileSize.value = null;
      final data = await Variable.cacheRemotePicture.database.rawQuery(
          '''SELECT ${Variable.cacheRemotePicture.primaryKey.keyName} FROM ${Constants.cacheRemotePictureTable};''');
      data.forEach((Map value) {
        final String filePath =
            value[Variable.cacheRemotePicturePrimaryKey.keyName];
        Variable.filePathToImageMap[filePath]?.value = null;
        MediaMetadataRetriever.filePathToPaletteMap[filePath]?.value = null;
        Variable.filePathToPendingRequestMap[filePath] = true;
      });
      await Variable.cacheRemotePicture.dropTable();
      await getFileSize();
    }
  }

  Widget _dialog(BuildContext context) {
    return AlertDialog(
      elevation: 8.0,
      shape: const RoundedRectangleBorder(borderRadius: Constants.borderRadius),
      title: Row(
        children: <Widget>[
          const Icon(Icons.delete),
          const VerticalDivider(),
          const Text('Clear cache'),
        ],
      ),
      content: const Text('Do you want to clear all remote artwork cache? '),
      actions: <Widget>[
        FlatButton(
          onPressed: () => Navigator.of(context).pop([true]),
          child: Text(
            "Yes",
            style: Theme.of(context).textTheme.body2,
          ),
        ),
        FlatButton(
          onPressed: () => Navigator.of(context).pop([false]),
          child: Text(
            "Cancel",
            style: Theme.of(context).textTheme.body2,
          ),
        ),
      ],
    );
  }

  _onChanged(value) {
    setState(() {
      Variable.remoteImageQuality.value = value;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fileSize = ValueNotifier(null);
    getFileSize();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    fileSize.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        const Divider(height: 30),
        ListTile(
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Remote Artwork Retriever',
              style: Theme.of(context).textTheme.title,
            ),
          ),
          subtitle: Text(
            "Search Artwork online for those audios don't embed pictures in original files. \nRetrievers' accuracy depend on the infomations' accuracy embedded in audio files. ",
            style: Theme.of(context).textTheme.body2,
          ),
          trailing: const Icon(Icons.cloud_download),
        ),
        const Divider(),
        ListTile(
          title: const Text('WLAN'),
          leading: const Icon(Icons.wifi),
          trailing: CupertinoSwitch(
              value: Variable.wifiSwitch.value,
              onChanged: (bool value) =>
                  setState(() => Variable.wifiSwitch.value = value)),
          onTap: () => setState(
              () => Variable.wifiSwitch.value = !Variable.wifiSwitch.value),
        ),
        ListTile(
          title: const Text('Mobile data'),
          leading: const Icon(Icons.data_usage),
          trailing: CupertinoSwitch(
              value: Variable.mobileDataSwitch.value,
              onChanged: (bool value) =>
                  setState(() => Variable.mobileDataSwitch.value = value)),
          onTap: () => setState(() => Variable.mobileDataSwitch.value =
              !Variable.mobileDataSwitch.value),
        ),
        ListTile(
          leading: Icon(Icons.image),
          title: Text('Remote Image Quality'),
          dense: false,
        ),
        Row(
          children: <Widget>[
            Expanded(
                child: RadioListTile<int>(
                    title: Text('Full'),
                    dense: true,
                    value: Variable.highQuality,
                    groupValue: Variable.remoteImageQuality.value,
                    onChanged: _onChanged)),
            Expanded(
              child: RadioListTile<int>(
                  title: Text('Mid'),
                  dense: true,
                  value: Variable.middleQuality,
                  groupValue: Variable.remoteImageQuality.value,
                  onChanged: _onChanged),
            ),
            Expanded(
              child: RadioListTile<int>(
                  title: Text('Low'),
                  dense: true,
                  value: Variable.lowQuality,
                  groupValue: Variable.remoteImageQuality.value,
                  onChanged: _onChanged),
            ),
          ],
        ),
        ListTile(
          title: const Text('Artwork Cache'),
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Icon(Icons.file_download),
          ),
          subtitle: FadeTransition(
            opacity: Setting.opacityForSubText,
            child: ValueListenableBuilder(
              valueListenable: fileSize,
              builder: (BuildContext context, int size, Widget child) {
                if (size == null) {
                  return const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const CircularProgressIndicator(),
                      ));
                }
                final mb = size / (1024 * 1024 );
                return Text(mb.toStringAsFixed(2) + ' MB',
                    style: Theme.of(context).textTheme.body2);
              },
            ),
          ),
          trailing: IconButton(
              icon: Icon(Icons.delete), onPressed: () => _clearCache(context)),
          onTap: () => _clearCache(context),
        ),
        const Divider(
//          color: Colors.black,
          height: 20.0,
        ),
      ],
    );
  }
}

class NotificationController extends StatefulWidget {
  const NotificationController({Key key}) : super(key: key);

  @override
  _NotificationControllerState createState() => _NotificationControllerState();
}

class _NotificationControllerState extends State<NotificationController> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        const Divider(
//          color: Colors.black,
          height: 10.0,
        ),
        ListTile(
          title: Text(
            'Notification',
            style: Theme.of(context).textTheme.title,
          ),
          trailing: Icon(Icons.notifications_active),
        ),
        ListTile(
          leading: Icon(Icons.play_circle_filled),
          title: Text('Playback'),
          trailing: CupertinoSwitch(
              value: Variable.notificationPlayBackSwitch.value,
              onChanged: (bool value) => setState(() {
                    Variable.notificationPlayBackSwitch.value = value;
                  })),
          onTap: () => setState(() {
            Variable.notificationPlayBackSwitch.value =
                !Variable.notificationPlayBackSwitch.value;
          }),
        ),
        ListTile(
          leading: Icon(Icons.update),
          title: Text('Product News'),
          trailing: CupertinoSwitch(
              value: Variable.notificationProductNewsSwitch.value,
              onChanged: (bool value) => setState(() {
                    Variable.notificationProductNewsSwitch.value = value;
                  })),
          onTap: () => setState(() {
            Variable.notificationProductNewsSwitch.value =
                !Variable.notificationProductNewsSwitch.value;
          }),
        ),
        const Divider(
//          color: Colors.black,
          height: 20.0,
        ),
      ],
    );
  }
}

class About extends StatelessWidget {
  const About({Key key}) : super(key: key);

  static const BuildConfig = '1.0.0';

  Widget _dialog(BuildContext context) {
    return AlertDialog(
      elevation: 8.0,
      shape: const RoundedRectangleBorder(borderRadius: Constants.borderRadius),
      title: Row(
        children: <Widget>[
          const Icon(Icons.info),
          const VerticalDivider(),
          const Text('Version'),
        ],
      ),
      content: const Text(BuildConfig),
      actions: <Widget>[
        FlatButton(
          onPressed: () => Navigator.of(context).pop([true]),
          child: Text(
            "Back",
            style: Theme.of(context).textTheme.body2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            'About',
            style: Theme.of(context).textTheme.title,
          ),
          trailing: Icon(Icons.info),
        ),
        ListTile(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.info),
          ),
          title: Text('Version'),
          subtitle: FadeTransition(
            opacity: Setting.opacityForSubText,
            child: Text(
              BuildConfig,
              style: Theme.of(context).textTheme.body2,
            ),
          ),
          onTap: () {
            showCupertinoDialog(context: context, builder: _dialog);
          },
        ),
      ],
    );
  }
}

class CustomDecoration extends Decoration {
  const CustomDecoration({this.edgeGradient});

  static const CustomDecoration none = CustomDecoration();

  final LinearGradient edgeGradient;

  static CustomDecoration lerp(
    CustomDecoration a,
    CustomDecoration b,
    double t,
  ) {
    assert(t != null);
    if (a == null && b == null) return null;
    return CustomDecoration(
      edgeGradient: LinearGradient.lerp(a?.edgeGradient, b?.edgeGradient, t),
    );
  }

  @override
  CustomDecoration lerpFrom(Decoration a, double t) {
    if (a is! CustomDecoration) return CustomDecoration.lerp(null, this, t);
    return CustomDecoration.lerp(a, this, t);
  }

  @override
  CustomDecoration lerpTo(Decoration b, double t) {
    if (b is! CustomDecoration) return CustomDecoration.lerp(this, null, t);
    return CustomDecoration.lerp(this, b, t);
  }

  @override
  CustomShadowPainter createBoxPainter([VoidCallback onChanged]) {
    return CustomShadowPainter(this, onChanged);
  }

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) return false;
    final CustomDecoration typedOther = other;
    return edgeGradient == typedOther.edgeGradient;
  }

  @override
  int get hashCode => edgeGradient.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<LinearGradient>('edgeGradient', edgeGradient));
  }
}

/// A [BoxPainter] used to draw the page transition shadow using gradients.
class CustomShadowPainter extends BoxPainter {
  CustomShadowPainter(
    this._decoration,
    VoidCallback onChange,
  )   : assert(_decoration != null),
        super(onChange);

  final CustomDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final LinearGradient gradient = _decoration.edgeGradient;
    if (gradient == null) return;
    // The drawable space for the gradient is a rect with the same size as
    // its parent box one box width on the start side of the box.
    final TextDirection textDirection = configuration.textDirection;
    assert(textDirection != null);

    double deltaX;
    switch (textDirection) {
      case TextDirection.rtl:
        deltaX = configuration.size.width;
        break;
      case TextDirection.ltr:
        deltaX = -configuration.size.width;
        break;
    }
    final Rect rect = (offset & configuration.size).translate(deltaX, 0.0);

//    double deltaY = -configuration.size.height;
//    final Rect rect = (offset & configuration.size).translate(0.0, deltaY);

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect, textDirection: textDirection);

    canvas.drawRect(rect, paint);
  }
}
