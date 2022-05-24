import 'dart:io';
// import 'package:fluent_ui/fluent_ui.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_tag_editor/tag_editor.dart';
import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';

enum InputType { tags, str, num, path }

class InputLine<T> {
  T get curData => values;
  // InputType type = InputType.num;
  String label = '';
  Map? params;
  InputLineDecorator? decorator;
  late String key;
  late T values;
  late TextEditingController controller;
  late Function dataCollector;

  InputLine(
      {required this.key,
      required this.label,
      required this.values,
      this.decorator,
      this.params});

  buildWidget() {}
}

abstract class InputLineDecorator<T> {
  InputLineDecorator({this.nxt});
  InputLineDecorator? nxt;
  Widget buildWidget({required Widget child});
}

class PlainStrInputer extends InputLine<String> {
  PlainStrInputer(
      {required String key,
      required String label,
      required String values,
      InputLineDecorator? decorator})
      : super(key: key, label: label, values: values, decorator: decorator);
  @override
  buildWidget() {
    controller = TextEditingController(text: values);
    return TextFormField(
      autofocus: true,
      controller: controller,
      style: const TextStyle(fontSize: 14),
      validator: (v) {
        return v!.isEmpty ? '请输入$label' : null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  String get curData => controller.text;
}

class PlainPathInputer extends InputLine<String> {
  PlainPathInputer(
      {required String key,
      required String label,
      required String values,
      InputLineDecorator? decorator,
      params})
      : super(
            key: key,
            label: label,
            values: values,
            params: params,
            decorator: decorator);
  @override
  String get curData => controller.text;

  @override
  buildWidget() {
    controller = TextEditingController(text: values);

    return Row(
      children: [
        Expanded(
            child: TextFormField(
          autofocus: true,
          controller: controller,
          style: const TextStyle(fontSize: 14),
          validator: (v) {
            return Directory(v!).existsSync() ? null : '输入路径不存在';
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            isDense:
                true, // TextFormField控件纵向不加约束 并且isDense设置true 之后 通过contentPadding即可控制纵向的高度
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )),
        IconButton(
            onPressed: () async {
              if (params != null && params!.containsKey('dir')) {
                var path = await FilePicker.platform.getDirectoryPath();
                controller.text = (path ?? "");
              } else if (params != null && params!.containsKey('file')) {
                var fileSavePath = await FilePicker.platform.pickFiles(
                    dialogTitle: '选择文件存储路径:', initialDirectory: values);
                controller.text =
                    (fileSavePath == null ? '' : fileSavePath.paths[0])!;
              }
            },
            icon: const Icon(
              Icons.folder,
              color: Colors.grey,
            ))
      ],
    );
  }
}

class TagEditer extends InputLine<List<String>> {
  TagEditer({
    required String key,
    required String label,
    required List<String> values,
    InputLineDecorator? decorator,
  }) : super(key: key, label: label, values: values, decorator: decorator);

  late EditableTagsWidget widget;

  @override
  List<String> get curData => widget.curTags;

  @override
  buildWidget() {
    widget = EditableTagsWidget(
        controller: TextEditingController(), defaultTags: values);

    return widget;
  }
}

class BatchInputer {
  GlobalKey? formKey;
  double? width;
  BatchInputer({this.width, this.formKey});
  List<InputLine> lines = [];

  void addStrInput(String label, String key, String value,
      {InputLineDecorator? decorator}) {
    lines.add(PlainStrInputer(
        label: label, key: key, values: value, decorator: decorator));
  }

  void addTagsInput(String label, String key, List<String> values,
      {InputLineDecorator? decorator}) {
    lines.add(TagEditer(
        label: label, key: key, values: values, decorator: decorator));
  }

  void addPathInput(String label, String key, String value,
      {Map? params, InputLineDecorator? decorator}) {
    lines.add(PlainPathInputer(
        key: key,
        label: label,
        values: value,
        params: params,
        decorator: decorator));
  }

  buildEditableTags(InputLine e) {
    var child = EditableTagsWidget(
        controller: TextEditingController(),
        defaultTags: e.values as List<String>);
    e.dataCollector = () => child.curTags;
    return child;
  }

  Map<String, dynamic> get curInputedData {
    Map<String, dynamic> ans = {};
    for (var elem in lines) {
      ans[elem.key] = elem.curData;
    }
    return ans;
  }

  Widget buildWidget(BuildContext contex) {
    return LayoutBuilder(
      builder: ((context, constraints) {
        if (constraints.maxWidth != double.infinity) {
          width = constraints.maxWidth;
        } else {
          width = 450;
        }

        return Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
                controller: ScrollController(),
                child: Column(
                    children: lines.map((e) {
                  var baseInputer = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          child: Text(e.label,
                              style:
                                  const TextStyle(fontFamily: 'NotoSansSC'))),
                      Expanded(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minHeight: 30, maxHeight: double.infinity),
                              child: e.buildWidget()),
                          flex: 4)
                    ],
                  );
                  return Padding(
                      child: e.decorator != null
                          ? e.decorator!.buildWidget(child: baseInputer)
                          : baseInputer,
                      padding: const EdgeInsets.only(bottom: 20));
                }).toList())),
          ),
        );
      }),
    );
  }
}

// ignore: must_be_immutable
class EditableTagsWidget extends StatefulWidget {
  EditableTagsWidget({Key? key, required this.controller, this.defaultTags})
      : super(key: key);

  final TextEditingController controller;
  List<String>? defaultTags = [];
  late _EditableTagState _state;

  List<String> get curTags => _state._values;

  @override
  // ignore: no_logic_in_create_state
  _EditableTagState createState() {
    _state = _EditableTagState();
    return _state;
  }
}

class _EditableTagState extends State<EditableTagsWidget> {
  late List<String> _values;
  final FocusNode _focusNode = FocusNode();
  // final TextEditingController _textEditingController = TextEditingController();

  @override
  initState() {
    super.initState();
    _values = List<String>.from(widget.defaultTags ??= []);
  }

  _onDelete(index) {
    setState(() {
      _values.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        // Text('标签: '),
        TagEditor(
          length: _values.length,
          controller: widget.controller,
          focusNode: _focusNode,
          delimiters: [',', ' '],
          hasAddButton: true,
          resetTextOnSubmitted: true,
          // This is set to grey just to illustrate the `textStyle` prop
          textStyle: const TextStyle(color: Colors.grey),
          onSubmitted: (outstandingValue) {
            setState(() {
              _values.add(outstandingValue);
            });
          },
          inputDecoration: const InputDecoration(
            border: InputBorder.none,
            hintText: '输入标签...',
          ),
          onTagChanged: (newValue) {
            setState(() {
              _values.add(newValue);
            });
          },
          tagBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _Chip(
                index: index,
                label: _values[index],
                onDeleted: _onDelete,
              )),
          // InputFormatters example, this disallow \ and /
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[/\\]'))],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onDeleted,
    required this.index,
  });

  final String label;
  final ValueChanged<int> onDeleted;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Chip(
      labelPadding: const EdgeInsets.only(left: 3.0),
      label: Text(label),
      deleteIcon: const Icon(
        Icons.close,
        size: 18,
      ),
      onDeleted: () {
        onDeleted(index);
      },
    );
  }
}

// // ignore: must_be_immutable
// class DetailInputScreen extends StatelessWidget {
//   String _image = "";
//   DetailInputScreen(this._image, {Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: GestureDetector(
//         child: Center(
//           child: Hero(
//               tag: 'imageHero',
//               child: Image.file(File(_image), fit: BoxFit.contain)),
//         ),
//         onTap: () {
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
// }
