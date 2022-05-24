// import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application/index.dart';
import 'package:yaml/yaml.dart';
import 'package:intl/intl.dart';
import 'package:json2yaml/json2yaml.dart';
import 'dart:math';
import 'package:path/path.dart' as p;
import '../index.dart';

class NoteInfoEvent {
  FileOperationType type;
  List<String> src;
  List<String?>? dst;
  BuildContext? contex;
  NoteInfoEvent({required this.type, required this.src, this.dst, this.contex});
}

class NoteInfoModel extends ChangeNotifier {
  NoteInfoModel();

  Map<String, NoteInfo> get noteInfo => MdFileManager.noteInfo;
  int get noteMount => MdFileManager.noteInfo.length;

  update(String path, NoteInfo _newInfo) {
    MdFileManager().update(path, _newInfo);
    super.notifyListeners();
  }

  add(String path) {
    MdFileManager().getNoteModelFromPath(path);
    super.notifyListeners();
  }

  remove(String path) {
    MdFileManager().remove(path);
    super.notifyListeners();
  }

  rescan() {
    MdFileManager().init(MdFileManager().rootPath);
    super.notifyListeners();
  }
}

class MdFileManager {
  static late final MdFileManager _instance = MdFileManager._internal();
  MdFileManager._internal();
  factory MdFileManager() => _instance;
  late String rootPath;

  late List<AbstrctNoteInfoCollecter> editors = [];
  static Map<String, NoteInfo> noteInfo = {};

  remove(String path) {
    path = p.normalize(path);
    if (noteInfo.containsKey(path)) {
      noteInfo.remove(path);
    }
  }

  update(String path, NoteInfo _newInfo) {
    path = p.normalize(path);
    if (noteInfo.containsKey(path)) {
      noteInfo[path] = _newInfo;
    }
  }

  Future<void> decodeNoteInfo(String path, NoteInfo info) async {
    var file = File(path);
    for (var edt in editors) {
      await edt.handle(file, info);
    }
    return;
  }

  Future<NoteInfo?> getNoteModelFromPath(String path) async {
    path = p.normalize(path);
    return noteInfo.containsKey(path) ? noteInfo[path] : null;
  }

  void updateNoteModel(NoteInfo info) {
    noteInfo[info.path] = info;
  }

  addEditor(AbstrctNoteInfoCollecter obj) {
    editors.add(obj);
  }

  createNullNoteInfo(String path) {
    path = p.normalize(path);
    if (p.extension(path) == '.md') {
      var info = NoteInfo()
        ..path = path
        ..title = p.basenameWithoutExtension(path)
        ..tags = []
        ..links = []
        ..subTitle = ""
        ..abstract = ""
        ..time = '';

      noteInfo[path] = info;
    }
  }

  scanNoteInfo(path) async {
    rootPath = path;
    noteInfo.clear();
    Directory currentDir = Directory(rootPath);
    for (var v in currentDir.listSync(recursive: true)) {
      createNullNoteInfo(v.path);
    }
    for (var key in noteInfo.keys) {
      await decodeNoteInfo(key, noteInfo[key]!);
    }
  }

  Future<void> init(String path) async {
    scanNoteInfo(path);
    // 添加事件监听
    EventBus().on<Profile>((profile) async {
      scanNoteInfo(profile.rootPath);
      return true;
    });

    EventBus().on<GitCloneEvent>((event) async {
      scanNoteInfo(rootPath);
      return true;
    });
    // // 添加事件监听
    EventBus().on<FileOperationEvent>((event) async {
      if (event.type == FileOperationType.move) {
        for (int idx = 0; idx < event.src.length; idx++) {
          var srcPath = p.normalize(event.src[idx]);
          var dstPath = p.normalize(event.dst![idx]!);
          if (p.extension(srcPath) != '.md') continue;
          if (!noteInfo.containsKey(srcPath)) continue;
          noteInfo[dstPath] = noteInfo[srcPath]!;
          noteInfo.remove(srcPath);
        }
      }
      if (event.type == FileOperationType.create) {
        createNullNoteInfo(event.src[0]);
        decodeNoteInfo(event.src[0], noteInfo[event.src[0]]!);
      } else if ((event.type == FileOperationType.delete)) {
        noteInfo.remove(event.src);
      }
      return true;
    });
  }
}

class AbstrctNoteInfoCollecter {
  MdFileManager? scanner;
  AbstrctNoteInfoCollecter({this.scanner});
  handle(FileSystemEntity fileInfo, NoteInfo info) async {}
}

class AbstractDecoder extends AbstrctNoteInfoCollecter {}

class FileTimeDecoder extends AbstrctNoteInfoCollecter {
  @override
  void handle(FileSystemEntity fileInfo, NoteInfo info) async {
    String modifiedTime = DateFormat('yyyy-MM-dd HH:mm:ss', 'zh_CN')
        .format(fileInfo.statSync().modified.toLocal());
    info.time = modifiedTime;
  }
}

class NoteLinkDecoder extends AbstrctNoteInfoCollecter {
  NoteLinkDecoder({MdFileManager? scanner}) : super(scanner: scanner);
  static var linkReg = r"\[(.*?)\]\((.*?)(\.md)\)";

  static Future<List<String>> scanAllLinksInFile(String filePath) async {
    List<String> ans = [];
    var text = '\n' + await File(filePath).readAsString();
    RegExp regExp = RegExp(linkReg);
    var matchs = regExp.allMatches(text);

    for (var match in matchs) {
      var relatedLinkPath = '${match[2]}.md';

      var linkPath = p.isRelative(relatedLinkPath)
          ? p.normalize(p.join(p.dirname(filePath), relatedLinkPath))
          : relatedLinkPath;
      ans.add(linkPath);
      // if (File(linkPath).existsSync()) {
      //   ans.add(linkPath);
      // }
    }
    return ans;
  }

  @override
  void handle(FileSystemEntity fileInfo, NoteInfo info) async {
    info.links = await scanAllLinksInFile(fileInfo.path);
  }
}

class GlobalIdGenerator {
  static Set abbrIds = {};

  static int add(id) {
    abbrIds.add(id);
    return id;
  }

  static int gen() {
    var rng = Random();
    int id;
    do {
      id = rng.nextInt(99999);
    } while (abbrIds.contains(id));
    abbrIds.add(id);
    return id;
  }
}

class YamlDecoder extends AbstrctNoteInfoCollecter {
  final yamlHead = r"^---\n[\s\S]*?\n *--- *";
  final List<String> exportKeys = ['tags', 'title', 'subTitle', 'abbrlink'];
  bool? initAbbr;
  YamlDecoder({this.initAbbr}) {
    initAbbr ??= true;
  }
  String? seperateYamlHead(String text, bool onlyMainText) {
    // text = ('\n' + text).replaceAll(RegExp(r"\n *\n"), "\n");

    int start = text.length;
    int end = 0;
    RegExp regExp = RegExp(yamlHead);
    var firstMatch = regExp.firstMatch(text);
    if (firstMatch == null) {
      return onlyMainText ? text : null;
    } else {
      start = firstMatch.start;
      end = firstMatch.end;
      return onlyMainText
          ? text.substring(end + 1)
          : text.substring(start + 4, end - 3);
    }
  }

  String exportHeader(NoteInfo info) {
    const List<String> exportKeys = ['tags', 'title', 'subTitle', 'abbrlink'];
    var outMap = info.toJson();
    outMap.removeWhere((key, value) => !exportKeys.contains(key));
    return json2yaml(outMap);
  }

  regenFileWithHeader(String path, String newHeader) {
    var mainText = seperateYamlHead(File(path).readAsStringSync(), true);
    var outStr = '---\n$newHeader\n---\n$mainText';
    File(path).writeAsString(outStr);
  }

  @override
  void handle(FileSystemEntity fileInfo, NoteInfo info) async {
    var text = await File(fileInfo.path).readAsString();

    String? yamlStr = seperateYamlHead(text, false);

    if (yamlStr == null) {
      info.tags = [];
      info.title = p.basenameWithoutExtension(fileInfo.path);
      info.subTitle = info.title;
      info.abbrlink = GlobalIdGenerator.gen();
      regenFileWithHeader(fileInfo.path, exportHeader(info));
    } else {
      try {
        var headerInfo = loadYaml(yamlStr);

        if (headerInfo.containsKey('tags') && headerInfo['tags'] != null) {
          info.tags = List<String>.generate(headerInfo['tags'].length,
              (index) => headerInfo['tags'][index].toString());
        }
        if (headerInfo.containsKey('title') && headerInfo['title'] != null) {
          info.title = headerInfo['title'].toString();
        }

        headerInfo.containsKey('subtitle') && headerInfo['subtitle'] != null
            ? info.subTitle = headerInfo['subtitle'].toString()
            : info.subTitle = info.title;
        // 在重新初始化 或者 原本字段里没有 abbr时重新生成
        var isGenAbbr = initAbbr! ||
            !headerInfo.containsKey('abbrlink') ||
            headerInfo['abbrlink'] != null;
        info.abbrlink = isGenAbbr
            ? GlobalIdGenerator.gen()
            : GlobalIdGenerator.add(
                int.parse(headerInfo.containsKey('abbrlink').toString()));

        isGenAbbr
            ? regenFileWithHeader(fileInfo.path, exportHeader(info))
            : null;
      } catch (e) {
        // 如果解析头失败 填充临时值 不然后续信息会解失败
        info.tags = [];
        info.title = p.basenameWithoutExtension(fileInfo.path);
        info.subTitle = info.title;
        info.abbrlink = GlobalIdGenerator.gen();
        Global.log.w("fail decode ${fileInfo.path} yaml header");
      }
    }
  }
}
