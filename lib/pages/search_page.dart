import 'package:flutter/material.dart';
import 'dart:async'; // 引入定时去所需要的包

import '../index.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: SearchManagerModel()),
          ],
          child: Builder(
            builder: ((context) => Column(
                  children: [
                    const PageHeader(title: "搜索"),
                    Padding(
                      child: SearchBar(
                        height: 40,
                      ),
                      padding: const EdgeInsets.all(6),
                    ),
                    const Expanded(child: SearchDetailWidget())
                  ],
                )),
          ),
        ));
  }
}

// class SearchDetailWidget extends StatelessWidget {
//   const SearchDetailWidget({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     context.watch<SearchManagerModel>().getSearchResults();
//     return Material(
//         child: AutoScollRow(
//       children: List<Widget>.generate(10, (index) => Text('测试 $index')),
//     ));
//   }
// }

class SearchDetailWidget extends StatelessWidget {
  const SearchDetailWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.watch<SearchManagerModel>().getSearchResults();
    return Material(
        child: FutureBuilder<List<NoteInfo>>(
            builder: ((context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                var data = snapshot.data;
                if (data!.isEmpty) return const Center(child: Text('无数据'));
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ArticleList(articleList: data),
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
            future: context.watch<SearchManagerModel>().getSearchResults()));
  }
}
