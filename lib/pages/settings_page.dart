import 'package:flutter/material.dart';
import 'package:flutter_application/index.dart';
import 'package:path_provider/path_provider.dart' as p;

import '../index.dart';

class InputerWithIllustration extends InputLineDecorator {
  InputerWithIllustration(
      {required this.label, this.action, InputLineDecorator? nxt})
      : super(nxt: nxt);
  String label;
  Map<String, void Function()>? action;
  TextStyle illutionStyle =
      TextStyle(fontSize: 12, color: Colors.grey.shade700);
  List<Widget> genTexteActions() {
    if (action == null) return [];

    var buttonLabels = action!.keys.toList();
    return List<Widget>.generate(
      buttonLabels.length,
      (index) => TextButton(
        style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(const Size(0, 0)),
            padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 5))),
        child: Text(buttonLabels[index],
            style: illutionStyle.copyWith(
                color: Colors.blue, decoration: TextDecoration.underline)),
        onPressed: () => action![buttonLabels[index]]!(),
      ),
    );
  }

  @override
  Widget buildWidget({required Widget child}) {
    var illustrate = Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [Text(label, style: illutionStyle), ...genTexteActions()],
      ),
      alignment: Alignment.centerRight,
    );
    var cur = Column(children: [child, illustrate]);
    return nxt != null ? nxt!.buildWidget(child: cur) : cur;
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SettingsState();
  }
}

class SettingsState extends State<SettingsPage> {
  late BatchInputer gitBatchSettins;
  late Profile profile = Global.profile;
  GlobalKey formKey = GlobalKey<FormState>();
  gitParamValidCheck() {}

  Map<String, void Function()>? githubActions() {
    return {
      '下载笔记': (() async {
        if ((formKey.currentState as FormState).validate()) {
          context
              .read<ProfileModel>()
              .mergProfileSettins(gitBatchSettins.curInputedData);
          await GitHubOperation().cloneRepository(context);
        }
      }),
      '上传笔记': (() async {
        if ((formKey.currentState as FormState).validate()) {
          context
              .read<ProfileModel>()
              .mergProfileSettins(gitBatchSettins.curInputedData);
          await GitHubOperation().uploadRepository(context);
        }
      }),
    };
  }

  @override
  void initState() {
    super.initState();
    gitBatchSettins = BatchInputer(formKey: formKey);
    gitBatchSettins.addStrInput('用户名', 'userName', profile.userName);
    gitBatchSettins.addStrInput(
        '仓库名', 'repositoryName', profile.repositoryName);
    gitBatchSettins.addStrInput('token', 'token', profile.token);
    gitBatchSettins.addPathInput('笔记路径', 'rootPath', profile.rootPath,
        params: {'dir': null},
        decorator: InputerWithIllustration(
            label: 'GitHub同步配置', action: githubActions()));
  }

  groupTitle(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HorizontalLine(),
        Container(
            alignment: Alignment.centerLeft,
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 5),
            child:
                Text(title, style: const TextStyle(fontFamily: 'NotoSansSC'))),
        HorizontalLine()
      ],
    );
  }

  submittuttons() {
    return Padding(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            child: const Text('重置'),
            onPressed: () {},
          ),
          OutlinedButton(
            child: const Text('保存'),
            onPressed: () {
              if ((formKey.currentState as FormState).validate()) {
                context
                    .read<ProfileModel>()
                    .mergProfileSettins(gitBatchSettins.curInputedData);
              }
            },
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: ((context, constraints) {
      return Material(
          child: Container(
        width: constraints.maxWidth,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            const PageHeader(title: "设置"),
            groupTitle('GitHub配置'),
            gitBatchSettins.buildWidget(context),
            submittuttons(),
          ],
        ),
      ));
    }));
  }
}



// /// Application settings
// class Settings {
//   /// Path to assets folder. If set then edits to any document within this
//   /// application can be saved back to the assets folder.
//   final String? assetsPath;

//   Settings({this.assetsPath});

//   static Future<Settings> load() async {
//     if (kIsWeb) {
//       return Settings(assetsPath: '');
//     }

//     final fs = LocalFileSystem();
//     final dir = await pp.getApplicationSupportDirectory();
//     final file = fs.directory(dir.path).childFile('settings.json');
//     if (await file.exists()) {
//       final json = await file.readAsString();
//       final data = jsonDecode(json) as Map<String, dynamic>;
//       return Settings(assetsPath: data['assetsPath'] as String?);
//     }
//     return Settings(assetsPath: '');
//   }

//   static Settings? of(BuildContext context) {
//     final widget =
//         context.dependOnInheritedWidgetOfExactType<SettingsProvider>()!;
//     return widget.settings;
//   }

//   Future<void> save() async {
//     if (kIsWeb) {
//       return;
//     }
//     final fs = LocalFileSystem();
//     final dir = await pp.getApplicationSupportDirectory();
//     final file = fs.directory(dir.path).childFile('settings.json');
//     final data = {'assetsPath': assetsPath};
//     await file.writeAsString(jsonEncode(data));
//   }
// }

// Future<Settings?> showSettingsDialog(BuildContext context, Settings? settings) {
//   return showDialog<Settings>(
//       context: context, builder: (ctx) => SettingsDialog(settings: settings));
// }

// class SettingsDialog extends StatefulWidget {
//   final Settings? settings;

//   const SettingsDialog({Key? key, required this.settings}) : super(key: key);

//   @override
//   _SettingsDialogState createState() => _SettingsDialogState();
// }

// class _SettingsDialogState extends State<SettingsDialog> {
//   String? _assetsPath = '';
//   TextEditingController? _assetsPathController;

//   @override
//   void initState() {
//     super.initState();
//     _assetsPath = widget.settings!.assetsPath;
//     _assetsPathController = TextEditingController(text: _assetsPath);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text('Settings'),
//       content: Container(
//         constraints: BoxConstraints(minWidth: 400),
//         child: TextField(
//           controller: _assetsPathController,
//           decoration: InputDecoration(
//             labelText: 'Path to assets folder',
//             helperText:
//                 'When set, allows to edit and save documents used in examples from within the app. Only useful if you are a developer of Zefyr package.',
//             helperMaxLines: 3,
//           ),
//           onChanged: _assetsPathChanged,
//         ),
//       ),
//       actions: [TextButton(onPressed: _save, child: Text('Save'))],
//     );
//   }

//   void _assetsPathChanged(String value) {
//     setState(() {
//       _assetsPath = value;
//     });
//   }

//   Future<void> _save() async {
//     final settings = Settings(assetsPath: _assetsPath);
//     await settings.save();
//     if (mounted) {
//       Navigator.pop(context, settings);
//     }
//   }
// }

// class SettingsProvider extends InheritedWidget {
//   final Settings? settings;

//   SettingsProvider({Key? key, this.settings, required Widget child})
//       : super(key: key, child: child);

//   @override
//   bool updateShouldNotify(covariant SettingsProvider oldWidget) {
//     return oldWidget.settings != settings;
//   }
// }
