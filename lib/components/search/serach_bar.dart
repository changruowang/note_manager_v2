import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:searchable_listview/searchable_listview.dart';
import 'data_collection.dart';
import 'package:flutter/services.dart';
import '../../index.dart';

// ignore: must_be_immutable
class OverlayContent extends StatefulWidget {
  void Function(String s)? onSelect;
  OverlayContent({Key? key, this.onSelect}) : super(key: key) {
    onSelect ??= (String s) {};
  }
  @override
  State<StatefulWidget> createState() {
    return OverlayState();
  }
}

class OverlayState extends State<OverlayContent> {
  List<String> strs = [];
  int curSelect = 0;

  String get curSelectStr => strs[curSelect];

  void setInputting(String inputing) {
    strs.clear();
    if (inputing != '') {
      strs.add(inputing);
    }
    strs.addAll(SearchManagerModel().getSuggestions(inputing));
    curSelect = curSelect >= strs.length ? strs.length - 1 : curSelect;
    setState(() {});
  }

  String upSelect() {
    setState(() {
      curSelect = max(0, curSelect - 1);
    });
    return strs[curSelect];
  }

  String downSelect() {
    setState(() {
      curSelect = min(strs.length - 1, curSelect + 1);
    });
    return strs[curSelect];
  }

  @override
  Widget build(BuildContext context) {
    var selectedDecoration = BoxDecoration(
      color: Theme.of(context).hoverColor,
      border: const Border(
        left: BorderSide(
          width: 3, //宽度
          color: Colors.blueAccent,
          //边框颜色
        ),
      ),
    );
    if (strs.isEmpty) return Container();
    return Material(
      elevation: 4.0,
      child: ListView(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          children: List<Widget>.generate(
              strs.length,
              (index) => Container(
                    decoration: curSelect == index ? selectedDecoration : null,
                    child: ListTile(
                      focusColor: Colors.red,
                      focusNode: FocusNode(),
                      onTap: () => widget.onSelect!(strs[index]),
                      title: Text(strs[index]),
                    ),
                  ))),
    );
  }
}
//  RichText(
//           //富文本
//           text: const TextSpan(
//               text: '测试',
//               style: TextStyle(
//                   color: Colors.black, fontWeight: FontWeight.bold),
//               children: [
//             TextSpan(text: '测试', style: TextStyle(color: Colors.grey))
//           ])),
//       RichText(
//           //富文本
//           text: const TextSpan(
//               text: '测试',
//               style: TextStyle(
//                   color: Colors.black, fontWeight: FontWeight.bold),
//               children: [
//             TextSpan(text: '测试', style: TextStyle(color: Colors.grey))
//           ])),
//     ],

class SearchBar extends StatefulWidget {
  SearchBar({Key? key, required this.height}) : super(key: key);
  double height;
  @override
  State<StatefulWidget> createState() {
    return SearchBarState();
  }
}

class SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<OverlayState> overlayKey = GlobalKey();

  late TextEditingController _textController;
  OverlayEntry? _overlayEntry;
  late double searchBarWidth;
  // {Key? key, required this.height}
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context)?.insert(_overlayEntry!);
      } else {
        _overlayEntry!.remove();
      }
    });
  }

  void onSearchPressed() {
    context.read<SearchManagerModel>().setInquireStr(_textController.text);
  }

  Widget _buildInputBar() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 3,
            color: Color(0x39000000),
            offset: Offset(0, 1),
          )
        ],
        borderRadius: BorderRadius.circular(widget.height),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 0),
                child: TextField(
                  onChanged: ((value) {
                    overlayKey.currentState!.setInputting(value);
                  }),
                  focusNode: _focusNode,
                  textAlignVertical: TextAlignVertical.center,
                  controller: _textController,
                  obscureText: false,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(0),
                    labelStyle: Theme.of(context).textTheme.bodyText1!.copyWith(
                          fontFamily: 'Lexend Deca',
                          color: Color(0xFF57636C),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0x00000000),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0x00000000),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_sharp,
                      color: Color(0xFF57636C),
                      size: 22,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        color: const Color(0xFF262D34),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
              child: ElevatedButton(
                onPressed: () => onSearchPressed(),
                child: const Text('搜索'),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(const Color(0xFF4B39EF)),
                    textStyle: MaterialStateProperty.all(
                        Theme.of(context).textTheme.headline2!.copyWith(
                              fontFamily: 'Lexend Deca',
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            )),
                    elevation: MaterialStateProperty.all(2),
                    minimumSize: MaterialStateProperty.all(Size(50, 35)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0)))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    double leftPadding = 10;
    return OverlayEntry(
      builder: (context) => Positioned(
          left: leftPadding,
          top: offset.dy + size.height + 5.0,
          width: searchBarWidth - leftPadding,
          child: OverlayContent(
            key: overlayKey,
            onSelect: (String s) {
              _textController.text = s;
              onSearchPressed();
            },
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        searchBarWidth = constraints.maxWidth;
        return RawKeyboardListener(
          child: _buildInputBar(),
          focusNode: FocusNode(),
          onKey: (event) {
            if (event.isKeyPressed(LogicalKeyboardKey.end)) {
              onSearchPressed();
            }
            if (overlayKey.currentState == null) return;
            if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
              _textController.text = overlayKey.currentState!.upSelect();
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              _textController.text = overlayKey.currentState!.downSelect();
            }
          },
        );
      },
    );
  }
}
