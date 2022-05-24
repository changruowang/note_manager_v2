// import 'dart:html';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:github/github.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as p;

import 'package:dio/dio.dart';

import 'dart:async';

import '../index.dart';

class GitCloneEvent {
  int? status;
}

class GitHubOperation {
  static late final GitHubOperation _instance = GitHubOperation._internal();
  GitHubOperation._internal();
  factory GitHubOperation() => _instance;
  final CancelToken _token = CancelToken();
  String repositoryName = 'Note';
  String userName = 'changruowang';
  String token = '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';
  String rootPath = 'C:/Users/10729/Desktop/测试';
  Map<String, String?> downStatues = {};
  Map<String, int?> upStatues = {};

  bool hasInit = false;
  bool running = false;
  static late GitHub github;

  _initParams(Profile args) {
    token = args.token;
    userName = args.userName;
    rootPath = args.rootPath;
    repositoryName = args.repositoryName;
    github = GitHub(auth: Authentication.withToken(token));
    hasInit = true;
  }

  init() async {
    _initParams(Global.profile);
    EventBus().on<Profile>((args) async {
      hasInit = false;
      _initParams(args);
      hasInit = true;
      return true;
    });
  }

  statusCallBack(EasyLoadingStatus status) {
    if (EasyLoadingStatus.dismiss == status) {
      running = false;
      _token.cancel();
      EasyLoading.showError('下载取消', maskType: EasyLoadingMaskType.black);
    }
  }

  uploadRepository(BuildContext context) async {
    if (running == true) return;
    if (hasInit == false) {
      await init();
    }
    running = true;
    EasyLoading.show(
        status: '正在扫描远程文件信息...',
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: true);
    await scannRemoteFiles('/');

    var remoteFiles = downStatues.keys.toSet();
    var localFiles = scanLoaclFiles();

    upStatues.clear();

    var updataKeys = remoteFiles.intersection(localFiles);
    var updMap = createSubMap(updataKeys.toList(), 1);
    upStatues.addAll(updMap);
    var deleteKeys = remoteFiles.difference(localFiles);
    var deleteMap = createSubMap(deleteKeys.toList(), 2);
    upStatues.addAll(deleteMap);
    var createKeys = localFiles.difference(remoteFiles);
    var createMap = createSubMap(createKeys.toList(), 3);
    upStatues.addAll(createMap);

    var fileKeys = upStatues.keys.toList();
    int fileMounts = upStatues.length;
    int cnt = 0;
    for (int i = 0; i < fileMounts; i++) {
      EasyLoading.showProgress(cnt / fileMounts,
          status: '正在上传 $cnt/$fileMounts 个文件 ...',
          maskType: EasyLoadingMaskType.black);
      ContentCreation? res;
      if (upStatues[fileKeys[i]] == 1) {
        res = await updateRemoteFile(fileKeys[i]);
      } else if (upStatues[fileKeys[i]] == 2) {
        res = await deleteRemoteFile(fileKeys[i]);
      } else {
        res = await createRemoteFile(fileKeys[i]);
      }
      if (res != null) {
        upStatues[fileKeys[i]] = null;
      }
      cnt++;
    }
    upStatues.removeWhere((key, value) => value == null);
    if (upStatues.isNotEmpty) {
      EasyLoading.showError('${upStatues.length}/$fileMounts个文件上传失败',
          maskType: EasyLoadingMaskType.black,
          duration: const Duration(seconds: 2));
    } else {
      EasyLoading.showSuccess('上传成功',
          maskType: EasyLoadingMaskType.black,
          duration: const Duration(seconds: 2));
    }
    running = false;
  }

  Set<String> scanLoaclFiles() {
    var dir = Directory(rootPath);
    var fileEntrys = dir.listSync(recursive: true);
    upStatues.clear();

    var localPaths = fileEntrys.map((e) {
      return p.relative(e.path, from: rootPath).replaceAll('\\', '/');
    });
    var localFiles =
        localPaths.where((element) => p.extension(element) == '.md');
    return localFiles.toSet();
  }

  cloneRepository(BuildContext contex) async {
    if (running == true) return;
    if (hasInit == false) {
      await init();
    }
    running = true;
    EasyLoading.addStatusCallback(statusCallBack);
    EasyLoading.show(
        status: '正在扫描远程文件信息...',
        maskType: EasyLoadingMaskType.black,
        dismissOnTap: true);
    await scannRemoteFiles('/');
    EasyLoading.removeAllCallbacks();
    await cloneAllFiles(contex);
    running = false;
    int fileMounts = downStatues.length;
    downStatues.removeWhere((key, value) => value == null);
    EventBus().emit<GitCloneEvent>(GitCloneEvent());
    if (downStatues.isNotEmpty) {
      EasyLoading.showError('${downStatues.length}/$fileMounts个文件下载失败',
          maskType: EasyLoadingMaskType.black,
          duration: const Duration(seconds: 2));
    } else {
      EasyLoading.showSuccess('下载成功',
          maskType: EasyLoadingMaskType.black,
          duration: const Duration(seconds: 2));
    }

    EasyLoading.dismiss();
  }

  Future scannRemoteFiles(String fold) async {
    var contents = await github.repositories
        .getContents(RepositorySlug(userName, repositoryName), fold);
    if (!contents.isFile && contents.tree != null) {
      for (var item in contents.tree!) {
        if (item.type == 'dir') {
          if (item.path == 'hexo_bolg_files' ||
              p.basename(item.path!) == 'figs') continue;
          await Directory(p.join(rootPath, item.path)).create();
          await scannRemoteFiles(item.path!);
        } else {
          downStatues[item.path!] = item.downloadUrl!;
        }
      }
    }
  }

  Future cloneAllFiles(BuildContext context) async {
    int fileMounts = downStatues.length;
    int cnt = 0;
    for (var path in downStatues.keys.toList().reversed.toList()) {
      EasyLoading.showProgress(
        cnt / fileMounts,
        status: '正在下载 $cnt/$fileMounts 个文件 ...',
        maskType: EasyLoadingMaskType.black,
      );
      var res = await downloadFile(downStatues[path]!, path);
      if (res != null && res.statusCode == 200) {
        downStatues[path] = null;
      } else {
        await github.repositories
            .getContents(RepositorySlug(userName, repositoryName), path)
            .then((value) async {
          var res = await downloadFile(value.file!.downloadUrl!, path);
          if (res != null && res.statusCode == 200) {
            downStatues[path] = null;
            // print('$path 重新下载成功');
          }
        });
      }
      cnt++;
      if (running == false) return;
    }
  }

  Future<Response?> downloadFile(String url, String path) async {
    if (p.extension(path) != '.md' || !running) return null;
    try {
      var savePath = p.join(rootPath, path);
      return await Dio().download(
        url,
        savePath,
        cancelToken: _token,
      );
    } on DioError catch (e) {
      if (CancelToken.isCancel(e)) {
      } else {
        if (e.response != null) {
          // print('$path: ${e.response.toString()}');
        } else {
          // print('$path: ${e.message}');
        }
      }
    }
    return null;
  }

  Future<ContentCreation?> deleteRemoteFile(String path) async {
    try {
      var slug = RepositorySlug(userName, repositoryName);
      var gitPath = path.replaceAll('\\', '/');
      var fileInfo = await github.repositories.getContents(slug, gitPath);
      return await github.repositories
          .deleteFile(slug, path, "删除", fileInfo.file!.sha!, 'main');
    } catch (e) {
      return null;
    }
  }

  Future<ContentCreation?> updateRemoteFile(String path) async {
    var localPath = p.join(rootPath, path.replaceAll('/', '\\'));
    if (p.extension(path) != '.md' || !File(localPath).existsSync()) {
      return null;
    }

    var text = File(localPath).readAsStringSync();
    List<int> bytes = utf8.encode(text);
    String content = base64Encode(bytes);
    try {
      var slug = RepositorySlug(userName, repositoryName);
      var gitPath = path.replaceAll('\\', '/');
      var fileInfo = await github.repositories.getContents(slug, gitPath);
      var sha = fileInfo.file!.sha!;
      return await github.repositories
          .updateFile(slug, gitPath, "更新", content, sha, branch: 'main');
    } catch (e) {
      return null;
    }
  }

  Future<ContentCreation?> createRemoteFile(String path) async {
    var localPath = p.join(rootPath, path.replaceAll('/', '\\'));
    if (p.extension(path) != '.md' || !File(localPath).existsSync()) {
      return null;
    }

    var text = File(localPath).readAsStringSync();
    List<int> bytes = utf8.encode(text);
    String content = base64Encode(bytes);
    try {
      var slug = RepositorySlug(userName, repositoryName);
      var gitPath = path.replaceAll('\\', '/');
      return await github.repositories.createFile(
          slug,
          CreateFile(
              path: gitPath, content: content, branch: 'main', message: '新建'));
    } catch (e) {
      return null;
    }
  }
}

Map<String, int> createSubMap(List<String> keys, int value) {
  List<int> values = List.filled(keys.length, value);
  return Map.fromIterables(keys, values);
}
