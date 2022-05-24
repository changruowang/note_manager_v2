import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:flutter/services.dart';

abstract class MarkerDecoder {
  MarkerDecoder(this._controller);
  final QuillController _controller;
  String get regx;
  int get curSel => _controller.selection.end;

  String matchAndReplace(String text, {String newStr = ''}) {
    var index = text.lastIndexOf(RegExp(regx));
    if (index < 0 || index > text.length) return '';
    var matchResult = text.substring(index);

    var newPos = curSel - matchResult.length + 1;
    var newSelection = TextSelection(baseOffset: newPos, extentOffset: newPos);
    // ignore: todo
    //TODO: index+1是为了不更改上一行结尾的换行符替换，只替换当前行的内容
    // 如果 replaceText(index, matchResult.length, '\n') 就是把上一行的
    // 换行符连带当前行的所有内容一同替换为 '\n' 这样在删除时会报异常
    _controller.replaceText(
        index + 1, matchResult.length - 1, newStr, newSelection);
    return matchResult;
  }

  bool handle(String str);
}

// TODO: 列表编号数的自定义设置
class UnorderListDecoder extends MarkerDecoder {
  UnorderListDecoder(QuillController _controller) : super(_controller);
  @override
  String get regx => r'\n1. ';

  @override
  bool handle(String str) {
    var matchResult = matchAndReplace(str);
    if (matchResult == '') return false;
    _controller.formatSelection(Attribute.ol);
    return true;
  }
}

class OrderListDecoder extends MarkerDecoder {
  OrderListDecoder(QuillController _controller) : super(_controller);
  @override
  String get regx => r'\n\* ';

  @override
  bool handle(String str) {
    var matchResult = matchAndReplace(str);
    if (matchResult == '') return false;
    _controller.formatSelection(Attribute.ul);
    return true;
  }
}

class QuoteDecoder extends MarkerDecoder {
  QuoteDecoder(QuillController _controller) : super(_controller);
  @override
  String get regx => r'\n\> ';

  @override
  bool handle(String str) {
    var matchResult = matchAndReplace(str);
    if (matchResult == '') return false;
    _controller.formatSelection(Attribute.blockQuote);
    return true;
  }
}

class HeaderDecoder extends MarkerDecoder {
  HeaderDecoder(QuillController _controller) : super(_controller);
  @override
  String get regx => r'\n#{1,3} ';

  @override
  bool handle(String str) {
    var matchResult = matchAndReplace(str);
    if (matchResult == '') return false;
    switch (matchResult.length) {
      case 3:
        _controller.formatSelection(Attribute.h1);
        break;
      case 4:
        _controller.formatSelection(Attribute.h2);
        break;
      case 5:
        _controller.formatSelection(Attribute.h3);
        break;
      default:
        _controller.formatSelection(Attribute.header);
    }
    return true;
  }
}

// markdown 标记的快捷输入
class EditorObserver {
  QuillController controller;
  List<MarkerDecoder> decoders = [];
  EditorObserver({required this.controller}) {
    add(HeaderDecoder(controller));
    add(UnorderListDecoder(controller));
    add(OrderListDecoder(controller));
    add(QuoteDecoder(controller));
  }

  void add(MarkerDecoder dec) {
    decoders.add(dec);
  }

  void onInputCharacters() {
    var text = controller.document
        .toPlainText()
        .substring(0, controller.selection.end);

    for (var dec in decoders) {
      if (dec.handle(text)) return;
    }
  }
}

//// 快捷键
class ShortCutKeyListener {
  QuillController controller;
  ShortCutKeyListener({required this.controller});

  void _pressCtrlB() {
    if (controller.getSelectionStyle().attributes.keys.contains('bold')) {
      controller.formatSelection(Attribute.clone(Attribute.bold, null));
    } else {
      controller.formatSelection(Attribute.bold);
    }
  }

  void _pressTab() {
    final indent =
        controller.getSelectionStyle().attributes[Attribute.indent.key];
    if (indent == null) {
      controller.formatSelection(Attribute.indentL1);
      return;
    }
    if (indent.value == 1) {
      controller.formatSelection(Attribute.clone(Attribute.indentL1, null));
      return;
    }
    controller.formatSelection(Attribute.getIndentLevel(indent.value + 1));
  }

  void _pressShiftTab() {
    final indent =
        controller.getSelectionStyle().attributes[Attribute.indent.key];
    if (indent == null) {
      return;
    } else {
      controller.formatSelection(Attribute.getIndentLevel(indent.value - 1));
    }
  }

  void onShortKeyPressed(RawKeyEvent event) {
    if (event.repeat) return;
    // tab键按下
    if (event.logicalKey.keyLabel == 'Tab' &&
        event.isShiftPressed &&
        event.isKeyPressed(LogicalKeyboardKey.tab)) {
      _pressShiftTab();
      // shif + tab
    } else if (event.logicalKey.keyLabel == 'Tab' &&
        event.isKeyPressed(LogicalKeyboardKey.tab)) {
      _pressTab();
      // tab 键
    } else if (event.data.isControlPressed &&
        event.isKeyPressed(LogicalKeyboardKey.keyB)) {
      _pressCtrlB();
    }
  }
}
