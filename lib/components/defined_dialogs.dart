import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FormTestRoute extends StatefulWidget {
  @override
  _FormTestRouteState createState() => _FormTestRouteState();
}

class _FormTestRouteState extends State<FormTestRoute> {
  TextEditingController _controller = TextEditingController();
  GlobalKey _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey, //设置globalKey，用于后面获取FormState
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: TextFormField(
        autofocus: true,
        controller: _controller,
        decoration: InputDecoration(
          labelText: "输入路径",
          hintText: "用户名或邮箱",
          icon: Icon(Icons.person),
        ),
        // 校验用户名
        validator: (v) {
          return v!.trim().isNotEmpty ? null : "用户名不能为空";
        },
      ),
    );
  }
}

// ignore: must_be_immutable, use_key_in_widget_constructors
class InputPathWidget extends StatelessWidget {
  InputPathWidget({Key? key, this.defaultFileName}) : super(key: key);
  String? fileSavePath = '';
  final TextEditingController _controller = TextEditingController(text: '');
  String? defaultFileName;
  String? get path => fileSavePath;

  @override
  Widget build(BuildContext context) {
    defaultFileName ??= '新建文件.md';
    GlobalKey _formKey = GlobalKey<FormState>();

    return AlertDialog(
        title: const Text("请输入路径"),
        actions: <Widget>[
          TextButton(
            child: const Text("取消"),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            child: const Text("确定"),
            onPressed: () {
              if ((_formKey.currentState as FormState).validate()) {
                Navigator.of(context).pop(fileSavePath);
              }
            },
          ),
        ],
        content: Form(
            key: _formKey, //设置globalKey，用于后面获取FormState
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SizedBox(
              width: 300,
              child: Row(
                children: [
                  Expanded(
                      flex: 7,
                      child: TextFormField(
                        autofocus: true,
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "文件存储路径",
                        ),
                        validator: (v) {
                          return Directory(p.dirname(v ??= '')).existsSync()
                              ? null
                              : "无效路径";
                        },
                      )),
                  Expanded(
                      flex: 1,
                      child: IconButton(
                          onPressed: () async {
                            fileSavePath = await FilePicker.platform.saveFile(
                              dialogTitle: '选择文件存储路径:',
                              fileName: defaultFileName,
                            );

                            fileSavePath ??= '';
                            _controller.text = fileSavePath!;
                          },
                          icon: const Icon(Icons.folder,
                              color: Colors.lightBlue))),
                ],
              ),
            )));
  }
}

Future<String?> showInputPathDialog(BuildContext context, String? name) async {
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return InputPathWidget(
        defaultFileName: name,
      );
    },
  );
}

Future<bool?> showAskPromptDialog(BuildContext context, String str) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("提示"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(str),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("取消"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text("确定"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );
}

Future<bool?> showPromptErrorDialog(BuildContext context, String str) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("提示"),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(str),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("确定"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
