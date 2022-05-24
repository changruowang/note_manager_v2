import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class YmDialog extends Dialog {
  String? title;
  YmDialog({Key? key, String? title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Builder(builder: ((context) {
      title = context.watch<LoadingStatus>().msg;
      return GestureDetector(
          onTap: () {
            MyLoading.cancel();
            Navigator.of(context).pop();
          },
          child: Center(
            //创建透明层
            child: Material(
              type: MaterialType.transparency, //透明类型
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 400, minWidth: 0, maxHeight: 120, minHeight: 0),
                child: Container(
                  decoration: const ShapeDecoration(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(5.0)))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      if (title != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10, left: 10, right: 10, top: 10),
                          child: Text(
                            title!,
                            style: const TextStyle(
                                fontSize: 14.0, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ));
    }));
  }
}

class LoadingStatus extends ChangeNotifier {
  String? _message;
  String? get msg => _message;

  set msg(String? m) {
    _message = m;
    notifyListeners();
  }
}

class MyLoading {
  static bool isShowing = false;
  static void show(BuildContext context, {String? message}) {
    context.read<LoadingStatus>().msg = message;
    if (!isShowing) {
      isShowing = true;
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return YmDialog();
          });
    } else {
      context.read<LoadingStatus>().msg = message;
    }
  }

  static cancel() {}
}
