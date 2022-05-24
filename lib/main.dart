import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'index.dart';

/// 思路分析  安卓外部存储根目录/storage/emulated/0
/// 启动APP：1、获取到SD卡根路径；2、检查读写权限
/// 进入首页，显示根路径下所有文件夹和文件
/// ---点击文件 - 打开
/// ---点击文件夹 - 显示该文件夹下的所有文件夹和文件
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // // Permission check
  // Future<void> getPermission() async {
  //   if (Platform.isAndroid) {
  //     PermissionStatus permission = await Permission.storage.status;

  //     if (permission != PermissionStatus.granted) {
  //       await Permission.storage.request();
  //     }
  //   }
  //   await getSDCardDir();
  // }
  // Future.wait([initializeDateFormatting("zh_CN", null), getPermission()])
  //     .then((result) {
  //   runApp(MyApp());
  // });
  Future.wait([initializeDateFormatting("zh_CN", null), Global.init()])
      .then((result) {
    runApp(MyApp());
  });
  // doWhenWindowReady(() {
  //   final initialSize = Size(600, 450);
  //   appWindow.minSize = initialSize;
  //   appWindow.size = initialSize;
  //   appWindow.alignment = Alignment.center;
  //   appWindow.show();
  // });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ProfileModel()),
          ChangeNotifierProvider.value(value: NoteInfoModel()),
          ChangeNotifierProvider.value(value: CurShowingNoteModel()),
          ChangeNotifierProvider.value(value: LoadingStatus())
        ],
        child: MaterialApp(
          builder: EasyLoading.init(),
          title: 'Flutter File Manager',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: HomePage(),
        ));
  }
}
