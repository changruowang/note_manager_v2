import 'package:flutter/material.dart';
export './quill_editor/quill_editor_page.dart';
export './zefyr_editor/zefyr_editor_page.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  String? getMdDocument() {
    throw UnimplementedError();
  }

  String? getDeltaDocument() {
    throw UnimplementedError();
  }

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    throw UnimplementedError();
  }
}
