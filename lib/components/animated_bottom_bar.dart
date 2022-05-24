import 'package:flutter/material.dart';

class AnimatedBottomBar extends StatefulWidget {
  final List<BarItem> barItems;
  final Duration animationDuration;
  final Function? onBarTap;
  final BarStyle? barStyle;

  const AnimatedBottomBar(
      {Key? key,
      required this.barItems,
      this.animationDuration = const Duration(milliseconds: 500),
      this.onBarTap,
      this.barStyle})
      : super(key: key);

  @override
  _AnimatedBottomBarState createState() => _AnimatedBottomBarState();
}

class _AnimatedBottomBarState extends State<AnimatedBottomBar>
    with TickerProviderStateMixin {
  int selectedBarIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10.0,
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 0.0,
          top: 16.0,
          left: 0.0,
          right: 0.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _buildBarItems(),
        ),
      ),
    );
  }

  List<Widget> _buildBarItems() {
    List<Widget> _barItems = [];
    for (int i = 0; i < widget.barItems.length; i++) {
      BarItem item = widget.barItems[i];
      bool isSelected = selectedBarIndex == i;
      _barItems.add(InkWell(
        splashColor: Colors.transparent,
        onTap: () {
          setState(() {
            selectedBarIndex = i;
            widget.onBarTap?.call(selectedBarIndex);
          });
        },
        child: AnimatedContainer(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          duration: widget.animationDuration,
          decoration: BoxDecoration(
              color: isSelected
                  ? item.color?.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(30))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(
                item.iconData,
                color: isSelected ? item.color : Colors.black,
                size: widget.barStyle?.iconSize,
              ),
              const SizedBox(
                height: 5.0,
              ),
              isSelected
                  ? AnimatedSize(
                      duration: widget.animationDuration,
                      curve: Curves.easeInOut,
                      child: Text(
                        item.text!,
                        style: TextStyle(
                            color: item.color,
                            fontWeight: widget.barStyle?.fontWeight,
                            fontSize: widget.barStyle?.fontSize),
                      ),
                    )
                  : Container(),
              const SizedBox(
                height: 5.0,
              ),
            ],
          ),
        ),
      ));
    }
    return _barItems;
  }
}

class BarStyle {
  final double fontSize, iconSize;
  final FontWeight fontWeight;

  BarStyle(
      {this.fontSize = 10,
      this.iconSize = 24,
      this.fontWeight = FontWeight.normal});
}

class BarItem {
  String? text;
  IconData? iconData;
  Color? color;

  BarItem({this.text, this.iconData, this.color});
}
