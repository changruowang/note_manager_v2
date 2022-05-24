import 'dart:async';

// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../../index.dart';

enum FileOperationType { move, create, delete, modify, rename }

/// 点击一个文件夹，传入文件夹的路径，显示该文件夹下的文件和文件夹
/// 点击一个文件，打开
/// 返回上一层，返回上一层目录路径 [dir.parent.path]
// ignore: must_be_immutable
class FileManager extends StatefulWidget {
  FileManager({Key? key, required this.currentDirPath, this.width})
      : super(key: key);
  double? width;
  final String currentDirPath; // 当前路径

  @override
  _FileManagerState createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  List<FileSystemEntity> currentFiles = []; // 当前路径下的文件夹和文件
  late double _x;
  late double _y;
  @override
  void initState() {
    super.initState();
    FileCommon().getCurrentPathFiles(widget.currentDirPath);
  }

  @override
  void didUpdateWidget(FileManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    FileCommon().getCurrentPathFiles(widget.currentDirPath);
  }

  Future<bool> _notifyBeforeListeners(FileOperationType type,
      List<String> srcFilePath, List<String>? dstFilePath) async {
    return await EventBus().ask<FileOperationEvent>(FileOperationEvent(
        type: type, src: srcFilePath, dst: dstFilePath, contex: context));
  }

  void _notifyAfterListeners(FileOperationType type, List<String> srcFilePath,
      List<String>? dstFilePath) async {
    EventBus().emit<FileOperationEvent>(FileOperationEvent(
        type: type, src: srcFilePath, dst: dstFilePath, contex: context));
  }

  freshShow() async {
    await FileCommon().updataFileTree(widget.currentDirPath);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [ChangeNotifierProvider.value(value: FileCommon())],
        child: Builder(
          builder: (context) {
            var rootFileList =
                context.watch<FileCommon>().fileTree[widget.currentDirPath];

            return LayoutBuilder(
              builder: ((context, constraints) {
                widget.width ??= constraints.maxWidth;
                return rootFileList!.isEmpty
                    ? const Text("空目录")
                    : Scrollbar(
                        child: ListView(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        children: rootFileList.map((e) {
                          if (e is Map) {
                            return _buildFolderItem(e, 1);
                          } else {
                            return _buildFileItem(e, 1,
                                parentNode: FileCommon().fileTree);
                          }
                        }).toList(),
                      ));
              }),
            );
          },
        ));
  }

  void _createFold(String foldPath) async {
    _notifyBeforeListeners(FileOperationType.create, [foldPath], null)
        .then((value) async {
      if (value == false) {
        return;
      } else {
        try {
          var fold = Directory(p.join(foldPath, '新建文件夹'));
          if (!await fold.exists()) {
            await fold.create();
            await freshShow();
          }
        } on FileSystemException catch (e) {
          // Fluttertoast.showToast(msg: e.message, gravity: ToastGravity.CENTER);
          EasyLoading.showToast(
            'Toast',
          );
        }
      }
    });
  }

  void _createFile(String foldPath) {
    _notifyBeforeListeners(FileOperationType.create, [foldPath], null)
        .then((value) async {
      if (value == true) {
        try {
          var file = File(p.join(foldPath, '新建文件.md'));
          if (!await file.exists()) {
            await file.create();

            await freshShow();
          }
        } on FileSystemException catch (e) {
          // Fluttertoast.showToast(msg: e.message, gravity: ToastGravity.CENTER);
          EasyLoading.showToast(e.message);
        }

        return;
      }
    });
  }

  void _rename(FileSystemEntity file) async {
    var origPath = file.path;

    String origName = p.basename(origPath);
    String dirPath = p.dirname(origPath);
    // TODO: 重命名前没有通知事件
    showInputStringDialog(context, origName).then((value) async {
      if (value != null && value != origName) {
        try {
          if (await file.exists()) {
            String newPath;
            await file.rename(newPath = p.join(dirPath, value));
            await freshShow();
            _notifyAfterListeners(
                FileOperationType.rename, [origPath], [newPath]);
          }
        } on FileSystemException catch (e) {
          // Fluttertoast.showToast(msg: e.message, gravity: ToastGravity.CENTER);
          EasyLoading.showToast(e.message);
        }
      }
    });
  }

  void _delete(FileSystemEntity file) {
    var path = file.path;

    _notifyBeforeListeners(FileOperationType.delete, [path], null)
        .then((value) async {
      if (value == true) {
        try {
          if (await file.exists()) {
            await file.delete(recursive: true);
            await freshShow();
            _notifyAfterListeners(FileOperationType.delete, [path], null);
            return;
          }
        } on FileSystemException catch (e) {
          // Fluttertoast.showToast(msg: e.message, gravity: ToastGravity.CENTER);
          EasyLoading.showToast(e.message);
        }
      }
    });
  }

  void _fileOperation(String path, Map parentNode) {
    var menueStyle = const TextStyle(fontSize: 14);
    showMenu(
        context: context,
        position: RelativeRect.fromLTRB(_x, _y, _x, _y),
        items: <PopupMenuItem>[
          PopupMenuItem(
            child: Text(
              '新建文件',
              style: menueStyle,
            ),
            value: 0,
          ),
          PopupMenuItem(
            child: Text(
              '新建文件夹',
              style: menueStyle,
            ),
            value: 1,
          ),
          PopupMenuItem(
            child: Text(
              '其他应用打开',
              style: menueStyle,
            ),
            value: 2,
          ),
          PopupMenuItem(
            child: Text(
              '删除',
              style: menueStyle,
            ),
            value: 3,
          ),
          PopupMenuItem(
            child: Text(
              '重命名',
              style: menueStyle,
            ),
            value: 4,
          )
        ]).then((value) {
      switch (value) {
        case 0:
          _createFile(p.dirname(path));
          break;
        case 1:
          _createFold(p.dirname(path));
          break;
        case 2:
          OpenFile.open(path).then((value) {
            // print(value.message);
          });
          break;
        case 3:
          _delete(File(path));
          break;
        case 4:
          _rename(File(path));
          break;
        default:
      }

      print(value);
    });
  }

  Widget _buildFileItem(String path, double level, {Map? parentNode}) {
    FileSystemEntity file = File(path);
    String modifiedTime = DateFormat('yyyy-MM-dd HH:mm:ss', 'zh_CN')
        .format(file.statSync().modified.toLocal());

    var contentWidget = GestureDetector(
      child: ListTile(
        contentPadding: EdgeInsets.only(left: level * 16),
        leading: _buildTileIcon(file.path),
        title: Text(file.path.substring(file.parent.path.length + 1)),
        subtitle: Text(
            '$modifiedTime  ${FileCommon().getFileSize(file.statSync().size)}',
            style: const TextStyle(fontSize: 12.0)),
        onTap: () {
          MdFileManager().getNoteModelFromPath(file.path).then((value) {
            if (value != null) {
              context.read<CurShowingNoteModel>().setCurShowNote(value);
            } else {
              showPromptErrorDialog(context, '文件格式$path不正确!');
            }
          });
        },
      ),
      //右键
      onSecondaryTap: () => _fileOperation(path, parentNode!),
      onSecondaryTapDown: (details) {
        _x = details.globalPosition.dx;
        _y = details.globalPosition.dy;
      },
    );
    return DragTarget<String>(onAccept: (String data) {
      var srcPath = data;
      var dstFold = p.dirname(path);

      _move(srcPath, dstFold);
    }, builder: ((context, candidateData, rejectedData) {
      return InkWell(
          child: Draggable(
              data: path,
              child: contentWidget,
              feedback: Opacity(
                  opacity: 0.8,
                  child: Material(
                    child: Container(child: contentWidget, width: widget.width),
                  ))));
    }));
  }

  Widget _buildTileIcon(String path) {
    path = path.toLowerCase();
    switch (p.extension(path)) {
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Image.file(
          File(path),
          width: 40.0,
          height: 40.0,
          // 解决加载大量本地图片可能会使程序崩溃的问题
          cacheHeight: 90,
          cacheWidth: 90,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
        );
      default:
        return Image.asset(FileCommon().selectIcon(p.extension(path)),
            width: 40.0, height: 40.0);
    }
  }

  void _foldOperation(Map node) {
    var menueStyle = const TextStyle(fontSize: 14);
    showMenu(
        context: context,
        position: RelativeRect.fromLTRB(_x, _y, _x, _y),
        items: <PopupMenuItem>[
          PopupMenuItem(
            child: Text(
              '新建文件',
              style: menueStyle,
            ),
            value: 0,
          ),
          PopupMenuItem(
            child: Text(
              '新建文件夹',
              style: menueStyle,
            ),
            value: 1,
          ),
          PopupMenuItem(
            child: Text(
              '删除',
              style: menueStyle,
            ),
            value: 2,
          ),
          PopupMenuItem(
            child: Text(
              '重命名',
              style: menueStyle,
            ),
            value: 3,
          )
        ]).then((value) {
      var foldPath = node.keys.toList()[0];
      switch (value) {
        case 0:
          _createFile(foldPath);
          break;
        case 1:
          _createFold(foldPath);
          break;
        case 2:
          _delete(Directory(foldPath));
          break;
        case 3:
          _rename(Directory(foldPath));
          break;

        default:
      }
    });
  }

  Future<void> _copyFold(String srcFold, String dstFold) async {
    String newFold = p.join(dstFold, p.basename(srcFold));
    await Directory(newFold).create();

    await for (var entity in Directory(srcFold).list()) {
      if (entity is Directory) {
        await _copyFold(entity.path, newFold);
      } else if (entity is File) {
        var dst = p.join(newFold, p.basename(entity.path));

        await entity.copy(dst);
      }
    }
  }

  void _move(String srcPath, String dstFold) {
    List<String> listSrcFiles(String srcFold) {
      List<String> srcs;

      List<FileSystemEntity> listPaths =
          Directory(srcFold).listSync(recursive: true);
      var listFilePaths = listPaths
          .where((element) => FileSystemEntity.isFileSync(element.path));

      srcs = listFilePaths.map((e) => e.path).toList();

      return srcs;
    }

    List<String> listDstFiles(
        String srcFold, String dstFold, List<String> srcFiles) {
      List<String> out = [];
      for (var element in srcFiles) {
        var base = p.relative(element, from: srcFold);
        out.add(p.normalize(p.join(dstFold, p.basename(srcFold), base)));
      }
      return out;
    }

    srcPath = p.normalize(srcPath);
    dstFold = p.normalize(dstFold);
    bool isFileMove = FileSystemEntity.isFileSync(srcPath);
    // 过滤无效移动
    if ((srcPath == dstFold) ||
        (isFileMove && (p.dirname(srcPath) == dstFold))) {
      return;
    }
    List<String> srcFiles = isFileMove ? [srcPath] : listSrcFiles(srcPath);
    List<String> dstFiles = isFileMove
        ? [p.join(dstFold, p.basename(srcPath))]
        : listDstFiles(srcPath, dstFold, srcFiles);

    _notifyBeforeListeners(FileOperationType.move, srcFiles, dstFiles)
        .then((value) async {
      if (value == true) {
        try {
          if (await FileSystemEntity.isDirectory(srcPath)) {
            await _copyFold(srcPath, dstFold);
            await Directory(srcPath).delete(recursive: true);
          } else {
            var file = File(srcPath);
            await file.copy(p.join(dstFold, p.basename(srcPath)));
            await file.delete();
          }
          _notifyAfterListeners(FileOperationType.move, srcFiles, dstFiles);
        } on FileSystemException catch (e) {
          EasyLoading.showToast(e.message);
        }
      }
      await freshShow();
    });
  }

  Widget _buildFolderItem(Map fold, double level) {
    String foldName = fold.keys.toList()[0];
    var file = Directory(foldName);
    // print("$level");
    var listChildren = fold[foldName];

    var foldWidget = Row(
      children: <Widget>[
        Text(p.basename(file.path)),
        const Spacer(),
        Text(
          '${_calculateFilesCountByFolder(file)}项',
          style: const TextStyle(color: Colors.grey),
        )
      ],
    );
    var contentWidget = listChildren.isEmpty
        ? ListTile(
            contentPadding: EdgeInsets.only(left: level * 16),
            leading: Image.asset('assets/images/folder.png'),
            title: foldWidget,
          )
        : ExpansionTile(
            tilePadding: EdgeInsets.only(left: level * 16),
            leading: Image.asset('assets/images/folder.png'),
            title: foldWidget,
            children: List.generate(listChildren.length, (index) {
              if (listChildren[index] is String) {
                return _buildFileItem(listChildren[index], level + 1,
                    parentNode: fold);
              } else {
                return _buildFolderItem(listChildren[index], level + 1);
              }
            }));

    return DragTarget<String>(
      builder: ((context, candidateData, rejectedData) {
        return Draggable(
            data: foldName,
            child: GestureDetector(
              child: contentWidget,
              onSecondaryTap: () => _foldOperation(fold),
              onSecondaryTapDown: (details) {
                _x = details.globalPosition.dx;
                _y = details.globalPosition.dy;
              },
            ),
            feedback: Opacity(
                opacity: 0.8,
                child: Material(
                  child: Container(child: contentWidget, width: widget.width),
                )));
      }),
      onAccept: (String srcInfo) {
        _move(srcInfo, foldName);
      },
    );
  }

  // 计算以 . 开头的文件、文件夹总数
  int _calculatePointBegin(List<FileSystemEntity> fileList) {
    int count = 0;
    for (var v in fileList) {
      if (p.basename(v.path).substring(0, 1) == '.') count++;
    }

    return count;
  }

  // 计算文件夹内 文件、文件夹的数量，以 . 开头的除外
  int _calculateFilesCountByFolder(Directory path) {
    var dir = path.listSync();
    int count = dir.length - _calculatePointBegin(dir);

    return count;
  }
}

Future<String?> showInputStringDialog(
    BuildContext context, String? name) async {
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return InputStringWidget(
        defaultFileName: name,
      );
    },
  );
}

// ignore: must_be_immutable
class InputStringWidget extends StatelessWidget {
  InputStringWidget({Key? key, this.defaultFileName}) : super(key: key);
  late TextEditingController _controller;
  String? defaultFileName;

  @override
  Widget build(BuildContext context) {
    defaultFileName ??= '新建文件.md';
    GlobalKey _formKey = GlobalKey<FormState>();
    _controller = TextEditingController(text: defaultFileName);
    return AlertDialog(
        // title: const Text("请输入路径"),
        actions: <Widget>[
          TextButton(
            child: const Text("取消"),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            child: const Text("确定"),
            onPressed: () {
              if ((_formKey.currentState as FormState).validate()) {
                Navigator.of(context).pop(_controller.text);
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
                            // hintText: "文件存储路径",
                            ),
                        validator: (v) {
                          return null;
                        },
                      )),
                ],
              ),
            )));
  }
}
