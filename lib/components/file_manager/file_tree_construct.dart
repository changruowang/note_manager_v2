import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application/components/file_manager/file_manager.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import '../../index.dart';

class FileOperationEvent {
  FileOperationType type;
  List<String> src;
  List<String?>? dst;
  BuildContext? contex;
  FileOperationEvent(
      {required this.type, required this.src, this.dst, this.contex});
}

// // type: 0 新建，1删除，2移动、重命名  isDone：文件操作执行之前和之后
// typedef FileOpBeforeListener = Future<bool> Function(FileOperationType type,
//     String srcFilePath, String? dstFilePath, BuildContext context);
// typedef FileOpAfterListener = void Function(FileOperationType type,
//     String srcFilePath, String? dstFilePath, BuildContext context);

// Future<bool> defaultBerforeListeners(FileOperationType type, String srcFilePath,
//     String? dstFilePath, BuildContext context) async {
//   String notionStr = '';
//   if (type == FileOperationType.move) {
//     // 移动文件时打开确认移动对话框
//     notionStr = '文件/夹将被移动';
//   } else if (type == FileOperationType.delete) {
//     notionStr = '文件/夹将被删除';
//   } else if (type == FileOperationType.create) {
//     notionStr = '新建文件';
//   } else {
//     return true;
//   }
//   var res = await showAskPromptDialog(context, notionStr);
//   res ??= false;
//   return res;
// }

class FileCommon extends ChangeNotifier {
  static late final FileCommon _instance = FileCommon._internal();
  FileCommon._internal();
  factory FileCommon() => _instance;
  late String rootPath;
  late DirectoryWatcher watcher;
  Map<String, List> fileTree = {};
  //TODO：修改为正则匹配的方法过滤文件夹和文件
  List<String> ignoredFolds = ['hexo_bolg_files', 'figs'];

  String getFileSize(int fileSize) {
    String str = '';

    if (fileSize < 1024) {
      str = '${fileSize.toStringAsFixed(2)}B';
    } else if (1024 <= fileSize && fileSize < 1048576) {
      str = '${(fileSize / 1024).toStringAsFixed(2)}KB';
    } else if (1048576 <= fileSize && fileSize < 1073741824) {
      str = '${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB';
    }

    return str;
  }

  void initFoldWatcher(String newPath) {
    watcher = DirectoryWatcher(p.absolute(newPath));
    watcher.events.listen((event) {
      updataFileTree(rootPath);
    });
  }

  Widget buildFileManagerWidget(String path) {
    initFoldWatcher(path);
    rootPath = path;
    return FileManager(currentDirPath: rootPath);
  }

  void getCurrentPathFilesDFS(String path, Map<String, List> ans) {
    // print(path);
    ans[path] = [];
    var currentList = ans[path];
    try {
      Directory currentDir = Directory(path);
      // 遍历所有文件/文件夹
      for (var v in currentDir.listSync()) {
        // 去除以 .开头的文件/文件夹
        var foldName = p.basename(v.path);
        if (foldName.substring(0, 1) == '.' ||
            ignoredFolds.contains(foldName)) {
          continue;
        }

        if (FileSystemEntity.isFileSync(v.path)) {
          currentList!.add(v.path);
        } else {
          currentList!.add(<String, List>{});
          getCurrentPathFilesDFS(v.path, ans[path]!.last);
        }
      }
    } catch (e) {
      Global.log.w('Directory does not exist！');
    }
  }

  void sortPathDFS(Map<String, List> ans) {
    ans.forEach((key, value) {
      value.sort((a, b) {
        if (a is Map) {
          return 0;
        } else if (b is Map) {
          return 1;
        }
        return 1;
      });
      for (var elem in value) {
        if (elem is Map<String, List>) {
          sortPathDFS(elem);
        }
      }
    });
  }

  init(String path) async {
    rootPath = path;
    await getCurrentPathFiles(path);
  }

  // 获取当前路径下的文件/文件夹
  Future<void> getCurrentPathFiles(String path) async {
    getCurrentPathFilesDFS(path, fileTree);
    sortPathDFS(fileTree);
  }

  Future<void> updataFileTree(String path) async {
    rootPath = path;
    await getCurrentPathFiles(path).then((value) => notifyListeners());
  }

  String selectIcon(String ext) {
    String iconImg = 'assets/images/unknown.png';

    switch (ext) {
      case '.ppt':
      case '.pptx':
        iconImg = 'assets/images/ppt.png';
        break;
      case '.doc':
      case '.docx':
        iconImg = 'assets/images/word.png';
        break;
      case '.xls':
      case '.xlsx':
        iconImg = 'assets/images/excel.png';
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
        iconImg = 'assets/images/image.png';
        break;
      case '.txt':
        iconImg = 'assets/images/txt.png';
        break;
      case '.mp3':
        iconImg = 'assets/images/mp3.png';
        break;
      case '.mp4':
        iconImg = 'assets/images/video.png';
        break;
      case '.rar':
      case '.zip':
        iconImg = 'assets/images/zip.png';
        break;
      case '.psd':
        iconImg = 'assets/images/psd.png';
        break;
      default:
        iconImg = 'assets/images/file.png';
        break;
    }
    return iconImg;
  }
}
