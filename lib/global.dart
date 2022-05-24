import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:logger/logger.dart';

import 'dart:io';

import 'index.dart';

class ProfileModel extends ChangeNotifier {
  Profile get profile => Global.profile;
  String get rootPath => Global.profile.rootPath;
  String get avatarUrl => Global.profile.avatarUrl;
  changeRootPath(String path) {
    Global.profile.rootPath = path;
    Global.saveProfile();
    super.notifyListeners();
  }

  mergProfileSettins(Map<String, dynamic> newData) {
    Map<String, dynamic> oldData = Global.profile.toJson();
    newData.forEach((key, value) {
      if (oldData.containsKey(key)) {
        oldData[key] = value;
      }
    });
    Global.profile = Profile.fromJson(oldData);
    Global.saveProfile();
    EventBus().emit(Global.profile);
    super.notifyListeners();
  }
}

class CurShowingNoteModel extends ChangeNotifier {
  // String? content;
  bool get hasData => !(curNote == null);
  NoteInfo? get curNote => Global.curNote;
  String get title => curNote!.title;
  String get curNotePath => curNote!.path;
  NoteInfo setTmpShowNote() {
    Global.curNote = NoteInfo()
      ..path = ''
      ..tags = ['测试标签1', '测试标签2']
      ..title = '新建文件'
      ..time = '临时时间';
    // content = '这是临时文件\n';
    return Global.curNote!;
  }

  void updateCurNoteInfo(Map<String, dynamic> newData) {
    var curJson = curNote!.toJson();
    newData.forEach(
      (key, value) {
        curJson[key] = value;
      },
    );
    Global.curNote = NoteInfo.fromJson(curJson);
    MdFileManager().updateNoteModel(Global.curNote!);
    super.notifyListeners();
  }

  void setCurShowNote(NoteInfo newNote) async {
    Global.curNote = newNote;
    var file = File(Global.curNote!.path);

    if (await file.exists()) {
      super.notifyListeners();
    }
  }
}

//订阅者回调签名
typedef EventCallback<T> = Future<bool> Function(T args);

class EventBus {
  //私有构造函数
  EventBus._internal();
  //保存单例
  static final EventBus _singleton = EventBus._internal();
  //工厂构造函数
  factory EventBus() => _singleton;
  //保存事件订阅者队列，key:事件名(id)，value: 对应事件的订阅者队列
  final _emap = <Object, List>{};
  final _emap_before = <Object, List>{};
  //添加事件发生后的订阅者
  void on<T>(EventCallback<T> f) {
    _emap[T.hashCode] ??= [];
    _emap[T.hashCode]!.add(f);
  }

  //添加事件发生前的订阅者  返回true表示事件可以执行
  void before<T>(EventCallback<T> f) {
    _emap_before[T.hashCode] ??= [];
    _emap_before[T.hashCode]!.add(f);
  }

  bool _off<T>(Map<Object, List> map, [EventCallback<T>? f]) {
    var list = map[T.hashCode];
    if (list == null) return false;
    if (f == null) {
      list.remove(f);
    }
    return true;
  }

  //移除订阅者
  void off<T>([EventCallback<T>? f]) {
    _off<T>(_emap, f) ? () {} : _off<T>(_emap_before);
  }

  Future<bool> ask<T>(T arg) async {
    var list = _emap_before[T.hashCode];
    if (list == null) return true;
    int len = list.length - 1;
    for (var i = len; i > -1; --i) {
      if (await list[i](arg) == false) return false;
    }
    return true;
  }

  //触发事件，事件触发后该事件所有订阅者会被调用
  void emit<T>(T arg) {
    var list = _emap[T.hashCode];
    if (list == null) return;
    int len = list.length - 1;
    //反向遍历，防止订阅者在回调中移除自身带来的下标错位
    for (var i = len; i > -1; --i) {
      list[i](arg);
    }
  }
}

class Global {
  static Logger log = Logger();
  static late Profile profile;
  static NoteInfo? curNote;
  static Future<void> init() async {
    profile = await readLocalProfile();
    // await FileCommon().init(profile.rootPath);
    MdFileManager().addEditor(YamlDecoder());
    MdFileManager().addEditor(FileTimeDecoder());
    MdFileManager().addEditor(NoteLinkDecoder(scanner: MdFileManager()));
    await MdFileManager().init(profile.rootPath);
    await LinKManager().init();
    await GitHubOperation().init();
    print("init OK");
  }

  static Future<Profile> readLocalProfile() async {
    var rootPath = 'D:/测试文件夹';

    return Profile()
      ..rootPath = rootPath
      ..avatarUrl = 'https://changruowang.github.io/images/icon.png'
      ..userName = 'changruowang'
      ..token = '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'
      ..repositoryName = 'Note2';
  }

  // TODO:本地存储
  static saveProfile() {}
}
