import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../index.dart';
// import 'package:flutter/material.dart';
// import 'package:zefyrka/zefyrka.dart';
import 'package:zefyr/zefyr.dart';
// import 'package:json2yaml/json2yaml.dart';
import 'zefyr_custom_builder.dart';
import 'package:quill_delta/quill_delta.dart';
import './markdown_delta/delta_markdown.dart';
import 'zefyr_delta_adp.dart';
import 'dart:convert';
import '../editor_page.dart';
import 'dart:io';
// import 'package:quill_format/quill_format.dart';

class ZefyrEditorPage extends EditorPage {
  ZefyrController? _controller;
  FocusNode _focusNode = FocusNode();
  String? notePath;

  ZefyrEditorPage({Key? key, this.notePath}) : super(key: key);
  Widget _buildWelcomeEditor(BuildContext context) {
    return Column(
      children: [
        // Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: ZefyrEditor(
              enableInteractiveSelection: true,
              controller: _controller!,
              focusNode: _focusNode,
              autofocus: true,
              embedBuilder: customZefyrEmbedBuilder,
              readOnly: false,
              // padding: EdgeInsets.only(left: 16, right: 16),
              onLaunchUrl: _launchUrl,
            ),
          ),
        ),
        editorToolButtons(_controller!),
        //ZefyrToolbar.basic(controller: _controller!)
      ],
    );
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null) return;
    if (url.startsWith('http')) {
      canLaunch(url).then((value) {
        if (value) {
          launch(url);
        }
      });
    }
    String mdFilePath = '';
    if (p.isRelative(url)) {
      mdFilePath = p.absolute(p.dirname(notePath!), url);
    }
    if (p.extension(mdFilePath) == '.md') {
      // MdFileManager().getNoteModelFromPath(mdFilePath).then((value) {
      //   if (value != null) {
      //     context.read<CurShowingNoteModel>().setCurShowNote(value);
      //  }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NotusDocument>(
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          var document = snapshot.data;
          _controller = ZefyrController(document);
          // var obv = EditorObserver(controller: _controller!);
          // initOK = true;

          // _controller!.addListener(() => obv.onInputCharacters());
          return _buildWelcomeEditor(context);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
      future: loadDocument(),
    );
  }

  @override
  String? getMdDocument() {
    if (_controller == null) return null;
    var tmp = jsonEncode(_controller!.document.toDelta());
    return deltaToMarkdown(tmp);
  }

  @override
  String? getDeltaDocument() {
    if (_controller == null) return null;
    return jsonEncode(_controller!.document);
  }

  Future<NotusDocument> loadDocument() async {
    var extention = p.extension(notePath!);

    final file = File(notePath!);
    if (await file.exists()) {
      if (extention == '.md') {
        return await _loadMdDocument(file);
      } else if (extention == 'json') {
        return await _loadJsonDocument(file);
      }
    }
    final delta = Delta()..insert('编辑新文档\n');
    return NotusDocument()..compose(delta, ChangeSource.local);
  }

  Future<NotusDocument> _loadJsonDocument(File file) async {
    final contents = await file.readAsString().then((data) => data);
    return NotusDocument.fromJson(jsonDecode(contents));
  }

  Future<NotusDocument> _loadMdDocument(File file) async {
    final text = await file.readAsString();
    final contents = YamlDecoder().seperateYamlHead(text, true)!;
    final deltaContents = jsonDecode(markdownToDelta(contents));
    final newDeltaContents = adptZefyrDeltaFormat(deltaContents);
    return NotusDocument.fromJson(newDeltaContents);
  }
}
