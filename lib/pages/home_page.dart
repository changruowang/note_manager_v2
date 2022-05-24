// import '../flutter_flow/flutter_flow_theme.dart';
// import '../flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flukit/flukit.dart';
import '../index.dart';
// import 'package:google_fonts/google_fonts.dart';

class PageHeader extends StatelessWidget {
  final String title;
  const PageHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(title,
                style: Theme.of(context).textTheme.headline2?.copyWith(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold))));
  }
}

// ignore: must_be_immutable
class SlidePageWidget extends StatefulWidget {
  int selectedBarIndex = 0;
  final List<BarItem> barItems = [
    BarItem(
      text: "分类",
      iconData: Icons.folder,
      color: Colors.yellow.shade900,
    ),
    BarItem(
      text: "最近",
      iconData: Icons.access_time_rounded,
      color: Colors.pinkAccent,
    ),
    BarItem(
      text: "标签",
      iconData: Icons.loyalty,
      color: Colors.indigo,
    ),
    BarItem(
      text: "搜索",
      iconData: Icons.search,
      color: Colors.purple.shade900,
    ),
    BarItem(
      text: "设置",
      iconData: Icons.settings,
      color: const Color(0xFF616161),
    ),
  ];

  SlidePageWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _SlideState();
  }
}

class _SlideState extends State<SlidePageWidget> {
  int selectedBarIndex = 0;
  List<Widget> pages = [];
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    pages.add(const CategoryPage());
    pages.add(Container());
    pages.add(TagViewPage());
    pages.add(const SearchPage());
    pages.add(SettingsPage());

    // 初始化控制器
    _controller = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            flex: 1,
            child: AnimatedBottomBar(
                barItems: widget.barItems,
                animationDuration: const Duration(milliseconds: 150),
                barStyle: BarStyle(fontSize: 14.0, iconSize: 28.0),
                onBarTap: (index) {
                  _controller.animateToPage(index,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeInOut);
                })),
        Expanded(
            flex: 7,
            child: PageView.builder(
                itemCount: pages.length,
                scrollDirection: Axis.vertical,
                controller: _controller,
                itemBuilder: (_, index) {
                  return KeepAliveWrapper(child: pages[index]);
                })),
      ],
    );
  }
}

// class MainContentWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return const ArticleDetail();
//   }
// }

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Theme.of(context).backgroundColor,
      body: Row(children: [
        Expanded(child: SlidePageWidget(), flex: 3),
        const Expanded(child: ArticleDetail(), flex: 7) // EditorPage()
      ]),
    );
  }
}
