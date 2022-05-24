import 'package:flutter/material.dart';
import 'package:flukit/flukit.dart';
import 'dart:async'; // 引入定时去所需要的包

// ignore: must_be_immutable
class FilterChipView extends StatefulWidget {
  final List<ActorFilterEntry> labels;
  Function(List<String>)? onChanged;
  double maxHeight;
  FilterChipView(
      {Key? key, required this.labels, this.onChanged, required this.maxHeight})
      : super(key: key);
  @override
  FilterChipViewState createState() => FilterChipViewState();
}

class ActorFilterEntry {
  const ActorFilterEntry(this.name, this.initials);

  final String name;
  final String initials;
}

class FilterChipViewState extends State<FilterChipView> {
  final List<String> _filters = [];
  late Size _size;
  bool scrollV = false;
  Iterable<Widget> get actorWidgets sync* {
    for (ActorFilterEntry actor in widget.labels) {
      yield Padding(
        padding: const EdgeInsets.all(4.0),
        child: FilterChip(
          elevation: 2.0,
          avatar: CircleAvatar(child: Text(actor.initials)),
          label: Text(actor.name),
          selected: _filters.contains(actor.name),
          onSelected: (bool value) {
            setState(() {
              if (value) {
                _filters.add(actor.name);
              } else {
                _filters.removeWhere((String _name) {
                  return _name == actor.name;
                });
              }
            });
            widget.onChanged!(_filters);
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _size = const Size(0, 0);
  }

  getSize(GlobalKey key) {
    return key.currentContext?.size;
  }

  @override
  Widget build(BuildContext context) {
    widget.onChanged ??= (List<String> p1) {};
    // if(_size.height < widget.maxHeight)
    Widget wrapperWidget = Column(
      children: <Widget>[
        Wrap(children: actorWidgets.toList()),
        if (_filters.isNotEmpty)
          const Padding(padding: EdgeInsets.only(top: 5), child: Text('查找:')),
        if (_filters.isNotEmpty)
          Text(_filters.join(',  '), textAlign: TextAlign.center),
      ],
    );
    return AfterLayout(
        callback: (RenderAfterLayout value) {
          _size = value.size;
          if (_size.height > widget.maxHeight) {
            setState(() {
              scrollV = true;
            });
          }
        },
        child: scrollV
            ? SizedBox(
                child: SingleChildScrollView(
                    controller: ScrollController(), child: wrapperWidget),
                height: widget.maxHeight,
              )
            : wrapperWidget);
  }
}
