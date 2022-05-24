import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
// import 'package:flutter_application/config/theme.dart';
import 'package:animated_search_bar/animated_search_bar.dart';

import '../index.dart';

import 'package:json2yaml/json2yaml.dart';
import 'dart:io';

class ArticleDetail extends StatefulWidget {
  const ArticleDetail({Key? key}) : super(key: key);

  @override
  _ArticleDetailState createState() => _ArticleDetailState();
}

class _ArticleDetailState extends State<ArticleDetail> {
  late bool editable = false;
  late HeaderInformation header;
  // late NoteInfo curNoteInfo;
  late String notePath;
  late bool showHeader;
  late bool initOK = false;
  final GlobalKey<QuillEditorPageState> editorKey =
      GlobalKey<QuillEditorPageState>();

  @override
  void initState() {
    super.initState();
    editable = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //父或祖先widget中的InheritedWidget改变(updateShouldNotify返回true)时会被调用。
    //如果build中没有依赖InheritedWidget，则此回调不会被调用。
    // print("Dependencies change");
  }

  @override
  Widget build(BuildContext context) {
    if (!context.read<CurShowingNoteModel>().hasData) {
      context.read<CurShowingNoteModel>().setTmpShowNote();
    }
    notePath =
        context.select(((CurShowingNoteModel value) => value.curNotePath));

    header = HeaderInformation();
    return Scaffold(
        appBar: AppBar(
          title: const Title(),
          actions: <Widget>[
            SizedBox(
              width: 250,
              child: AnimatedSearchBar(
                searchStyle: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                searchDecoration: const InputDecoration(
                  hintText: "搜索",
                  alignLabelWithHint: true,
                  fillColor: Colors.white,
                  focusColor: Colors.white,
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  print("value on Change");
                },
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                // iconSize: 25,
                icon: const Icon(Icons.edit),
                onPressed: () {
                  editable = !editable;
                  editorKey.currentState!.setEditable(editable);
                },
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                // iconSize: 25,
                icon: const Icon(Icons.save),
                onPressed: () => _saveDocument(context),
              ),
            ),
            Builder(
              builder: (context) => IconButton(
                  // iconSize: 25,
                  icon: const Icon(Icons.info_rounded),
                  onPressed: () => header.editYamlDialogs(context)),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.small(
            onPressed: () => setState(() {
                  editable = !editable;
                }),
            child: const Icon(Icons.add)),
        body: Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          // color: secondBgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              Expanded(
                  child: QuillEditPage(
                      notePath: notePath, editable: editable, key: editorKey)),
            ],
          ),
        ));
  }

  void _saveDocument(BuildContext context) async {
    String? path;
    if (!await File(notePath).exists()) {
      path = await showInputPathDialog(context, p.basename(notePath));
      if (path == null) return;
      notePath = path;
    }

    var mainText = editorKey.currentState!.getMdDocument();
    if (mainText == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('文档正在加载中.')));
      return;
    }
    var headText = header.exportHeader();
    var file = File(notePath);
    file.writeAsString("---\n$headText\n---\n$mainText").then((_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已保存 markdown 文件至 $notePath.')));
    });
  }
}

class Title extends StatelessWidget {
  const Title({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title = context.select((CurShowingNoteModel value) => value.title);
    return Text(title);
    // return AnimatedSearchBar(
    //   label: title,
    //   labelStyle: const TextStyle(fontSize: 24),
    //   searchStyle: const TextStyle(color: Colors.white),
    //   cursorColor: Colors.white,
    //   searchDecoration: const InputDecoration(
    //     hintText: "搜索",
    //     alignLabelWithHint: true,
    //     fillColor: Colors.white,
    //     focusColor: Colors.white,
    //     hintStyle: TextStyle(color: Colors.white70),
    //     border: InputBorder.none,
    //   ),
    //   onChanged: (value) {
    //     print("value on Change");
    //   },
    // );
  }
}

// ignore: must_be_immutable
class HeaderInformation extends StatelessWidget {
  late String time = '';
  late List<String> tags = [];
  late NoteInfo curNoteInfo;
  late CurShowingNoteModel curModel;
  HeaderInformation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userInfo = context.watch<ProfileModel>().profile;
    curModel = context.watch<CurShowingNoteModel>();
    curNoteInfo = curModel.curNote!;
    tags = curNoteInfo.tags;
    return Row(
      children: [
        // 头像
        Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: CircleAvatar(
              backgroundImage: NetworkImage(userInfo.avatarUrl),
              radius: 30,
            )),
        // 作者、等级以及创建时间

        Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(userInfo.userName,
                        style: const TextStyle(
                            fontSize: 12.0, fontWeight: FontWeight.w300)),
                    // TODO  level
                  ],
                ),
                Text(curNoteInfo.time,
                    style: const TextStyle(
                        fontSize: 12.0, fontWeight: FontWeight.w300))
              ],
            )),
        Expanded(
            child: Container(
          alignment: Alignment.bottomLeft,
          child: Wrap(
              spacing: 5,
              children: tags.map((e) {
                return Chip(
                    label: Text(e,
                        style: const TextStyle(
                            fontSize: 12.0, fontWeight: FontWeight.w300)));
              }).toList()),
        ))
      ],
    );
  }

  String exportHeader() {
    const List<String> exportKeys = ['tags', 'title', 'subTitle'];
    var outMap = curNoteInfo.toJson();
    outMap.removeWhere((key, value) => !exportKeys.contains(key));
    // print("$outMap  ${outMap.toYaml()}");
    return json2yaml(outMap);
  }

  void editYamlDialogs(BuildContext context) async {
    var data = curNoteInfo.toJson();
    final inputer = BatchInputer();
    inputer.addStrInput('标  题', 'title', data['title']);
    inputer.addStrInput('副标题', 'subTitle', data['subTitle']);
    inputer.addTagsInput('文章标签', 'tags', data['tags']);
    var edtiedData = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("编辑Yaml头信息"),
          content: inputer.buildWidget(context),
          actions: <Widget>[
            TextButton(
              child: const Text("取消"),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            TextButton(
              child: const Text("确定"),
              onPressed: () {
                Navigator.of(context).pop(inputer.curInputedData);
              },
            ),
          ],
        );
      },
    );
    if (edtiedData != null) {
      curModel.updateCurNoteInfo(edtiedData);
    }
  }
}
