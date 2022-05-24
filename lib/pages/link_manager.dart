// ignore_for_file: unnecessary_string_escapes

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as p;
// import 'package:flutter/material.dart';

// import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

import '../index.dart';

class LinKManager {
  static late final LinKManager _instance = LinKManager._internal();
  factory LinKManager() => _instance;
  LinKManager._internal();
  final linkReg = r"\[(.*?)\]\((.*?)(\.md)\)";

  Map<int, String> idToPathMap = {};
  final Map<int, Set<int>> linker = {};
  final Map<int, Set<int>> linked = {};

  initLinkRelation() {
    idToPathMap.clear();
    MdFileManager.noteInfo.forEach(
      (key, value) {
        idToPathMap[value.abbrlink.toInt()] = value.path;
        linker[value.abbrlink.toInt()] = {};
        linked[value.abbrlink.toInt()] = {};
      },
    );
    MdFileManager.noteInfo.forEach(
      (key, value) async {
        for (var path in value.links) {
          if (!File(path).existsSync()) continue;
          var id = (await MdFileManager().getNoteModelFromPath(path))!.abbrlink;
          linker[value.abbrlink.toInt()]!.add(id.toInt());
          linked[MdFileManager.noteInfo[path]!.abbrlink.toInt()]!
              .add(value.abbrlink.toInt());
        }
      },
    );
  }

  init() async {
    initLinkRelation();
    EventBus().before<FileOperationEvent>((event) async {
      if (event.type == FileOperationType.delete) {
        NoteInfo? info =
            await MdFileManager().getNoteModelFromPath(event.src[0]);
        if ((info == null) || (info.links.isEmpty)) return true;

        var str = info.links.join('\n');
        // 删除文件时  如果有其他文件依赖该文件，则弹出提示
        try {
          var ans = await showAskPromptDialog(
              event.contex!, "如果删除，以下文件中的引用将失效:\n\n$str");
          ans ??= false;
          return ans;
        } catch (e) {
          EasyLoading.showToast("以下文件中的引用已失效：\n$str");
          return true;
        }
      } else if (event.type == FileOperationType.move ||
          event.type == FileOperationType.rename) {
        //// 在文件夹还未移动时的调整方式
        assert(event.src.length == event.dst!.length);
        beforeMoveAdaptions(event.src, event.dst!);
      }
      return true;
    });

    EventBus().on<FileOperationEvent>((event) async {
      if (event.dst == null) return true;
      if (event.type == FileOperationType.move ||
          event.type == FileOperationType.rename) {
        // afterMoveAdaptions(event.src, event.dst!);
      } else if (event.type == FileOperationType.delete ||
          event.type == FileOperationType.create) {
        // 如果是删除 新建 了文件 不需要处理文件的引用关系 直接重新建立引用关系
        initLinkRelation();
      }

      return true;
    });
  }

  void afterMoveAdaptions(List<String> src, List<String?> dst) async {
    // 在文件、文件夹已经已经移动以后的调整方式
    assert(src.length == dst.length);
    for (int i = 0; i < src.length; i++) {
      var srcPath = p.normalize(src[i]);
      var dstPath = p.normalize(dst[i]!);
      idToPathMap = idToPathMap.map(
          (key, value) => MapEntry(key, value == srcPath ? dstPath : value));
    }
    List<String> changes = [];
    for (int i = 0; i < src.length; i++) {
      var srcPath = p.normalize(src[i]);
      var dstPath = p.normalize(dst[i]!);
      var dstFold = p.dirname(dstPath);
      if (p.extension(srcPath) != '.md') continue;
      changes.addAll(await asLinker(srcPath, dst[i]!, dstFold, true));
      changes.addAll(await asLinked(srcPath, dst[i]!, true));
    }
    if (changes.isNotEmpty) {
      EasyLoading.showToast(changes.join(''));
    }
  }

  void beforeMoveAdaptions(List<String> src, List<String?> dst) async {
    List<String> changes = [];
    for (int i = 0; i < src.length; i++) {
      var srcPath = p.normalize(src[i]);
      var dstPath = p.normalize(dst[i]!);
      var dstFold = p.dirname(dstPath);
      if (p.extension(srcPath) != '.md') continue;
      changes.addAll(await asLinker(srcPath, dst[i]!, dstFold, false,
          willMove: src.toSet()));
      changes.addAll(
          await asLinked(srcPath, dst[i]!, false, willMove: src.toSet()));
    }
    for (int i = 0; i < src.length; i++) {
      var srcPath = p.normalize(src[i]);
      var dstPath = p.normalize(dst[i]!);
      idToPathMap = idToPathMap.map(
          (key, value) => MapEntry(key, value == srcPath ? dstPath : value));
    }
    if (changes.isNotEmpty) {
      EasyLoading.showToast(changes.join(''));
    }
  }

  Future<int> getFileAbbr(String path) async {
    // TODO: 先使用移动前的路径来从noteInfo中读取信息  后面改成直接读文档的addr值
    return (await MdFileManager().getNoteModelFromPath(path))!.abbrlink.toInt();
  }

  Future<List<String>> asLinker(
      String srcPath, String dstPath, String dstFold, bool moved,
      {Set<String>? willMove}) async {
    assert(moved || (!moved && willMove != null));
    try {
      var file = File(moved ? dstPath : srcPath);
      var text = '\n' + file.readAsStringSync();
      var textCopy = '\n' + file.readAsStringSync();
      RegExp regExp = RegExp(linkReg);
      var matchs = regExp.allMatches(text);
      int cnt = 0;
      for (var match in matchs) {
        var relatedLinkPath = '${match[2]}.md';
        // 计算引用的引用的文档的完整路径
        var linkPath = p.isRelative(relatedLinkPath)
            ? p.normalize(p.join(p.dirname(srcPath), relatedLinkPath))
            : relatedLinkPath;
        var newlinkPath = p.relative(linkPath, from: dstFold);
        //  引用的是有效文档。
        // 如果是一个文件夹内的两个文件之间有相互引用 那么当移动这个文件夹时 就不用修改他们之间的相对引用
        // 如果是 移动后处理， 那么这个判断总是通过不了的所以不会修改二者之间的相互引用
        // 如果是移动前调整 就要排除这种情况
        if (!File(linkPath).existsSync()) continue;
        if (!moved && willMove!.contains(linkPath)) {
          continue; //文件还未移动 并且路径也在移动列表中 这种情况不用修改引用
        }
        var oldFullLink = textCopy.substring(match.start, match.end);
        // 计算相对路径 并替换
        var newFullLink = '[${match[1]}]($newlinkPath)';
        text = text.replaceAll(oldFullLink, newFullLink);
        cnt++;
      }
      file.writeAsStringSync(text.substring(1));
      if (cnt > 0) return ['\"$dstPath\"中, $cnt处引用已自动修改\n'];
    } catch (e) {
      rethrow;
    }
    return [];
  }

  Future<List<String>> asLinked(String srcPath, String dstPath, bool moved,
      {Set<String>? willMove}) async {
    List<String> showTmp = [];
    assert(moved || (!moved && willMove != null));
    // 获取所有链接了该文档的文件
    // 在文件夹已经移动以后 以这种方式读出noteInfo中的信息可能有bug  srcPath的信息可能有错误
    var id = await getFileAbbr(srcPath);
    if (!linked.containsKey(id)) return [];
    List<String> linkedFiles =
        linked[id]!.map<String>((e) => idToPathMap[e]!).toList();

    for (String linkFile in linkedFiles) {
      var file = File(linkFile);
      if (!file.existsSync()) continue;
      if (!moved && willMove!.contains(linkFile)) {
        continue; //文件还未移动 并且路径也在移动列表中 这种情况不用修改引用
      }
      var text = '\n' + file.readAsStringSync();
      var textCopy = '\n' + file.readAsStringSync();
      RegExp regExp = RegExp(linkReg);
      var matchs = regExp.allMatches(text);
      int cnt = 0;
      for (var match in matchs) {
        var relatedLinkPath = '${match[2]}.md';
        var linkPath = p.isRelative(relatedLinkPath)
            ? p.normalize(p.join(p.dirname(linkFile), relatedLinkPath))
            : relatedLinkPath;
        var newlinkPath = p.relative(dstPath, from: p.dirname(linkFile));
        if (linkPath == srcPath) {
          var oldFullLink = textCopy.substring(match.start, match.end);
          var newFullLink = '[${match[1]}]($newlinkPath)';
          text = text.replaceAll(oldFullLink, newFullLink);
          cnt++;
        }
      }
      file.writeAsStringSync(text.substring(1));

      if (cnt > 0) showTmp.add('\"$linkFile\"中, $cnt处引用已自动修改\n');
    }
    return showTmp;
  }
}
