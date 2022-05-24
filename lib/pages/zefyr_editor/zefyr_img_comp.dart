import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:zefyr/zefyr.dart';
// import 'package:zefyrka/zefyrka.dart';
import 'package:flutter/material.dart';

class CustomInsertImageButton extends StatelessWidget {
  final ZefyrController controller;
  final IconData icon;

  const CustomInsertImageButton({
    Key? key,
    required this.controller,
    required this.icon,
  }) : super(key: key);

  Future<String?> upload(String imgPath) async {
    return "";
  }
  // // open a bytestream
  // var stream = http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
  // // get file length
  // var length = await imageFile.length();

  // // string to uri
  // var uri = Uri.parse(server + "/upload");

  // // create multipart request
  // var request = http.MultipartRequest("POST", uri);

  // // multipart that takes file
  // var multipartFile = http.MultipartFile('note', stream, length,
  //     filename: basename(imageFile.path));

  // // add file to multipart
  // request.files.add(multipartFile);

  // // send
  // var response = await request.send();
  // // listen for response.join()
  // return response.stream.transform(utf8.decoder).join();

  // Future<String?> pickImage(ImageSource source) async {
  //   final file =
  //       await ImagePicker.pickImage(source: source, imageQuality: 65);
  //   // if (file == null) return null;
  //   // String value = await upload(file);
  //   // var v = jsonDecode(value);
  //   // var url = server + "/" + v["data"]["filepath"];
  //   // print(url);
  //   return "https://changruowang.github.io/images/icon.png";
  // }

  @override
  Widget build(BuildContext context) {
    return ZIconButton(
      highlightElevation: 0,
      hoverElevation: 0,
      size: 32,
      icon: Icon(
        icon,
        size: 18,
        color: Theme.of(context).iconTheme.color,
      ),
      fillColor: Theme.of(context).canvasColor,
      onPressed: () async {
        final index = controller.selection.baseOffset;
        final length = controller.selection.extentOffset - index;

        FilePicker.platform.pickFiles(type: FileType.image).then((value) async {
          if (value == null) return;
          var formatPath = await upload(value.paths[0]!);
          if (formatPath != null) {
            controller.replaceText(
                index,
                length,
                BlockEmbed('image', data: {
                  'image': value.paths[0]!
                })); //BlockEmbed('image', data: {'path': value.paths[0]!})
          } //
        });
      },
    );
  }
}

// ignore: must_be_immutable
class DetailImgScreen extends StatelessWidget {
  String _image = "";
  DetailImgScreen(this._image, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        child: Center(
          child: Hero(
              tag: 'imageHero',
              child: Image.file(File(_image), fit: BoxFit.contain)),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}

Widget buildEmbedImage(BuildContext context, EmbedNode node) {
  var path = node.value.data['image'];
  return LayoutBuilder(
    builder: ((context, constraints) {
      return UnconstrainedBox(
        child: SizedBox(
          width: constraints.maxWidth * 0.5,
          child: GestureDetector(
            child: Image.file(File(path), fit: BoxFit.fitWidth),
            //Image.network(node.value.type, fit: BoxFit.fill),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return DetailImgScreen(path);
              }));
            },
          ),
        ),
      );
    }),
  );
}
