// CustomPageView Feature with cacheExtent

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _defaultCacheExtent = 0.0;

class CustomPageView extends StatefulWidget {
    CustomPageView({
        Key key,
        this.scrollDirection = Axis.horizontal,
        this.reverse = false,
        PageController controller,
        this.physics,
        this.pageSnapping = true,
        this.onPageChanged,
        List<Widget> children = const <Widget>[],
        this.dragStartBehavior = DragStartBehavior.start,
        this.cacheExtent = _defaultCacheExtent,
    })  : controller = controller ?? _defaultPageController,
            childrenDelegate = SliverChildListDelegate(children),
            super(key: key);

    CustomPageView.builder({
        Key key,
        this.scrollDirection = Axis.horizontal,
        this.reverse = false,
        PageController controller,
        this.physics,
        this.pageSnapping = true,
        this.onPageChanged,
        @required IndexedWidgetBuilder itemBuilder,
        int itemCount,
        this.dragStartBehavior = DragStartBehavior.start,
        this.cacheExtent = _defaultCacheExtent,
    })  : controller = controller ?? _defaultPageController,
            childrenDelegate =
            SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
            super(key: key);

    CustomPageView.custom({
        Key key,
        this.scrollDirection = Axis.horizontal,
        this.reverse = false,
        PageController controller,
        this.physics,
        this.pageSnapping = true,
        this.onPageChanged,
        @required this.childrenDelegate,
        this.dragStartBehavior = DragStartBehavior.start,
        this.cacheExtent = _defaultCacheExtent,
    })  : assert(childrenDelegate != null),
            controller = controller ?? _defaultPageController,
            super(key: key);
    final Axis scrollDirection;

    final bool reverse;

    final PageController controller;

    final ScrollPhysics physics;

    final bool pageSnapping;

    final ValueChanged<int> onPageChanged;

    final SliverChildDelegate childrenDelegate;

    final DragStartBehavior dragStartBehavior;

    final double cacheExtent;

    @override
    _CustomPageViewState createState() => _CustomPageViewState();
}

final PageController _defaultPageController = PageController();
const PageScrollPhysics _kPagePhysics = PageScrollPhysics();

class _CustomPageViewState extends State<CustomPageView> {
    int _lastReportedPage = 0;

    @override
    void initState() {
        super.initState();
        _lastReportedPage = widget.controller.initialPage;
    }

    AxisDirection _getDirection(BuildContext context) {
        switch (widget.scrollDirection) {
            case Axis.horizontal:
                assert(debugCheckHasDirectionality(context));
                final TextDirection textDirection = Directionality.of(context);
                final AxisDirection axisDirection =
                textDirectionToAxisDirection(textDirection);
                return widget.reverse
                    ? flipAxisDirection(axisDirection)
                    : axisDirection;
            case Axis.vertical:
                return widget.reverse ? AxisDirection.up : AxisDirection.down;
        }
        return null;
    }

    @override
    Widget build(BuildContext context) {
        final AxisDirection axisDirection = _getDirection(context);
        final ScrollPhysics physics = widget.pageSnapping
            ? _kPagePhysics.applyTo(widget.physics)
            : widget.physics;

        return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
                if (notification.depth == 0 &&
                    widget.onPageChanged != null &&
                    notification is ScrollUpdateNotification) {
                    final PageMetrics metrics = notification.metrics;
                    final int currentPage = metrics.page.round();
                    if (currentPage != _lastReportedPage) {
                        _lastReportedPage = currentPage;
                        widget.onPageChanged(currentPage);
                    }
                }
                return false;
            },
            child: Scrollable(
                dragStartBehavior: widget.dragStartBehavior,
                axisDirection: axisDirection,
                controller: widget.controller,
                physics: physics,
                viewportBuilder: (BuildContext context, ViewportOffset position) {
                    return Viewport(
                        cacheExtent: widget.cacheExtent,
                        axisDirection: axisDirection,
                        offset: position,
                        slivers: <Widget>[
                            SliverFillViewport(
                                viewportFraction: widget.controller.viewportFraction,
                                delegate: widget.childrenDelegate,
                            ),
                        ],
                    );
                },
            ),
        );
    }

    @override
    void debugFillProperties(DiagnosticPropertiesBuilder description) {
        super.debugFillProperties(description);
        description
            .add(EnumProperty<Axis>('scrollDirection', widget.scrollDirection));
        description.add(
            FlagProperty('reverse', value: widget.reverse, ifTrue: 'reversed'));
        description.add(DiagnosticsProperty<PageController>(
            'controller', widget.controller,
            showName: false));
        description.add(DiagnosticsProperty<ScrollPhysics>(
            'physics', widget.physics,
            showName: false));
        description.add(FlagProperty('pageSnapping',
            value: widget.pageSnapping, ifFalse: 'snapping disabled'));
    }
}
