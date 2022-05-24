import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuple/tuple.dart';

import './markdown_delta/markdown_quill.dart';
import './markdown_delta/src/document.dart' as md;
import 'mark_input_plugs.dart';
// import 'quill_delta_adp.dart';
import '../../index.dart';

// ignore: must_be_immutable
class QuillEditPage extends EditorPage {
  bool editable;
  String? notePath;
  QuillEditPage({Key? key, required this.editable, this.notePath})
      : super(key: key);

  @override
  QuillEditorPageState createState() => QuillEditorPageState();
}

class QuillEditorPageState extends State<QuillEditPage> {
  QuillController? _controller;
  late bool editable;
  final FocusNode _focusNode = FocusNode(skipTraversal: true); //禁止焦点切换
  String? notePath;
  bool _isDesktop() => !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

  QuillEditorPageState();

  void setEditable(bool state) {
    setState(() {
      editable = state;
    });
  }

  @override
  void initState() {
    super.initState();
    editable = widget.editable;
    // notePath = widget.notePath;
  }

  @override
  Widget build(BuildContext context) {
    notePath = widget.notePath;
    notePath ??= '新建文件.md';
    return FutureBuilder<Document>(
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          _controller = QuillController(
              document: snapshot.data!,
              selection: const TextSelection.collapsed(offset: 0));
          var obv = EditorObserver(controller: _controller!);

          _controller!.addListener(() => obv.onInputCharacters());
          return RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => ShortCutKeyListener(controller: _controller!)
                .onShortKeyPressed(event),
            child: _buildEditor(context),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
      future: loadDocument(),
    );
  }

  _buildEditor(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            flex: 15,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: _buildEditArea(context),
            ),
          ),
          kIsWeb
              ? Expanded(
                  child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: _buildToolBar(),
                ))
              : Container(child: editable ? _buildToolBar() : null)
        ],
      ),
    );
  }

  Widget _buildEditArea(BuildContext context) {
    if (kIsWeb) {
      UnimplementedError('未实现web平台编辑');
    }
    // quillEditor = QuillEditor(
    //     controller: _controller!,
    //     scrollController: ScrollController(),
    //     scrollable: true,
    //     focusNode: _focusNode,
    //     autoFocus: false,
    //     readOnly: false,
    //     placeholder: 'Add content',
    //     expands: false,
    //     padding: EdgeInsets.zero,
    //     customStyles: DefaultStyles(
    //       h1: DefaultTextBlockStyle(
    //           const TextStyle(
    //             fontSize: 32,
    //             color: Colors.black,
    //             height: 1.15,
    //             fontWeight: FontWeight.w300,
    //           ),
    //           const Tuple2(16, 0),
    //           const Tuple2(0, 0),
    //           null),
    //       sizeSmall: const TextStyle(fontSize: 9),
    //     ),
    //     embedBuilder: defaultEmbedBuilderWeb);

    return QuillEditor(
        controller: _controller!,
        scrollController: ScrollController(),
        scrollable: true,
        focusNode: _focusNode,
        autoFocus: false,
        readOnly: !editable,
        placeholder: '输入',
        expands: true,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.3,
                fontWeight: FontWeight.w300,
              ),
              const Tuple2(8, 0),
              const Tuple2(0, 0),
              null),
          h1: DefaultTextBlockStyle(
              const TextStyle(
                fontSize: 32,
                color: Colors.black,
                height: 1.15,
                fontWeight: FontWeight.w300,
              ),
              const Tuple2(16, 0),
              const Tuple2(0, 0),
              null),
          sizeSmall: const TextStyle(fontSize: 9),
        ));
  }

  _buildToolBar() {
    if (kIsWeb) {
      return QuillToolbar.basic(
        controller: _controller!,
        onImagePickCallback: _onImagePickCallback,
        webImagePickImpl: _webImagePickImpl,
        showAlignmentButtons: true,
      );
    }
    if (_isDesktop()) {
      return QuillToolbar.basic(
        showAlignmentButtons: false,
        showFontSize: false,
        // showLeftAlignment: false,
        // showRightAlignment: false,
        showJustifyAlignment: false,
        showCameraButton: false,
        controller: _controller!,
        onImagePickCallback: _onImagePickCallback,
        filePickImpl: openFileSystemPickerForDesktop,
      );
    }
    return QuillToolbar.basic(
      controller: _controller!,
      // provide a callback to enable picking images from device.
      // if omit, "image" button only allows adding images from url.
      // same goes for videos.
      onImagePickCallback: _onImagePickCallback,
      onVideoPickCallback: _onVideoPickCallback,
      // uncomment to provide a custom "pick from" dialog.
      // mediaPickSettingSelector: _selectMediaPickSetting,
    );
  }

  String? getMdDocument() {
    if (_controller == null) return null;
    final deltaToMd = DeltaToMarkdown(
      customEmbedHandlers: {
        EmbeddableTable.tableType: EmbeddableTable.toMdSyntax,
      },
    );
    final markdownAgain = deltaToMd.convert(_controller!.document.toDelta());

    return markdownAgain;
  }

  String? getDeltaDocument() {
    if (_controller == null) return null;
    return jsonEncode(_controller!.document);
  }

  Future<Document> loadDocument() async {
    final file = File(notePath!);

    if (await file.exists()) {
      var extention = p.extension(notePath!);

      if (extention == '.md') {
        return await _loadMdDocument(file);
      } else if (extention == 'json') {
        return await _loadJsonDocument(file);
      }
    }
    final delta = Delta()..insert('\n');
    return Document()..compose(delta, ChangeSource.LOCAL);
  }

  Future<Document> _loadMdDocument(File file) async {
    final text = await file.readAsString();
    final contents = YamlDecoder().seperateYamlHead(text, true)!;
    final mdDocument = md.Document(
        // you can add custom syntax.
        // blockSyntaxes: [const EmbeddableTableSyntax()],
        );

    final mdToDelta = MarkdownToDelta(
      markdownDocument: mdDocument,
      customElementToBlockAttribute: {
        'h4': (element) => [HeaderAttribute(level: 4)],
        'cl': (element) {
          return [
            jsonDecode(element.attributes['check']!)[0]
                ? Attribute.checked
                : Attribute.unchecked
          ];
        }
      },
      // custom embed
      customElementToEmbeddable: {
        EmbeddableTable.tableType: EmbeddableTable.fromMdSyntax,
      },
    );
    var delta = mdToDelta.convert(contents);
    var tmpDelta = Delta()..insert('\n');
    return Document.fromDelta(delta.length == 0 ? tmpDelta : delta);
  }

  Future<Document> _loadJsonDocument(File file) async {
    final contents = await file.readAsString().then((data) => data);
    return Document.fromJson(jsonDecode(contents));
  }

  // @override
  // void dispose() {
  //   showAskPromptDialog(context, '未保存文件');
  //   super.dispose();
  // }
}

Future<String?> openFileSystemPickerForDesktop(BuildContext context) async {
  var path = await FilePicker.platform.pickFiles(type: FileType.image);
  if (path == null) return null;
  return path.paths[0];
}

// Renders the image picked by imagePicker from local file storage
// You can also upload the picked image to any server (eg : AWS s3
// or Firebase) and then return the uploaded image URL.
Future<String> _onImagePickCallback(File file) async {
  // Copies the picked file from temporary cache to applications directory
  // final appDocDir = await getApplicationDocumentsDirectory();
  // final copiedFile =
  //     await file.copy('${appDocDir.path}/${basename(file.path)}');

  return file.path.toString();
}

Future<String?> _webImagePickImpl(
    OnImagePickCallback onImagePickCallback) async {
  final result = await FilePicker.platform.pickFiles();
  if (result == null) {
    return null;
  }

  // Take first, because we don't allow picking multiple files.
  final fileName = result.files.first.name;
  final file = File(fileName);

  return onImagePickCallback(file);
}

// Renders the video picked by imagePicker from local file storage
// You can also upload the picked video to any server (eg : AWS s3
// or Firebase) and then return the uploaded video URL.
Future<String> _onVideoPickCallback(File file) async {
  // Copies the picked file from temporary cache to applications directory
  final appDocDir = await getApplicationDocumentsDirectory();
  final copiedFile =
      await file.copy('${appDocDir.path}/${basename(file.path)}');
  return copiedFile.path.toString();
}

// ignore: unused_element
Future<MediaPickSetting?> _selectMediaPickSetting(BuildContext context) =>
    showDialog<MediaPickSetting>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.collections),
              label: const Text('Gallery'),
              onPressed: () => Navigator.pop(ctx, MediaPickSetting.Gallery),
            ),
            TextButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Link'),
              onPressed: () => Navigator.pop(ctx, MediaPickSetting.Link),
            )
          ],
        ),
      ),
    );
