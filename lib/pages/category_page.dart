import 'package:flutter/material.dart';
import '../index.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var rootPath = context.watch<ProfileModel>().rootPath;
    return Column(
      children: [
        // Padding(
        //   child: SearchBar(
        //     height: 35,
        //   ),
        //   padding: const EdgeInsets.all(6),
        // ),
        const PageHeader(title: "目录"),
        // Expanded(
        //     child: Material(
        //         child: Text(
        //   '目录',
        //   style: TextStyle(color: Colors.indigo),
        // ))),
        Expanded(child: FileCommon().buildFileManagerWidget(rootPath))
      ],
    );
  }
}
