import 'package:flutter/material.dart';

import '../index.dart';

class TagInfoManager {
  late Map<String, List<NoteInfo>> tagInfo = {};
  final Map<String, NoteInfo> noteInfo;
  Set<String> get allTags => tagInfo.keys.toSet();
  int get tagMount => tagInfo.keys.length;
  TagInfoManager(this.noteInfo);

  Future<void> scanTags() async {
    noteInfo.forEach((key, value) {
      for (var tag in value.tags) {
        tagInfo.containsKey(tag)
            ? tagInfo[tag]!.add(value)
            : tagInfo[tag] = [value];
      }
    });
  }

  List<NoteInfo> getSelectedTagNote(Set<String> selTags) {
    Set<NoteInfo> ans = {};

    for (var tag in selTags) {
      if (tagInfo.containsKey(tag)) ans = ans.union(tagInfo[tag]!.toSet());
    }

    var res = ans.toList();
    res.sort(
      (a, b) {
        var ma = selTags.intersection(a.tags.toSet()).length;
        var mb = selTags.intersection(b.tags.toSet()).length;
        return ma > mb ? 0 : 1;
      },
    );

    return res;
  }

  int getNoteMountInTag(String tag) {
    return tagInfo.containsKey(tag) ? tagInfo[tag]!.length : 0;
  }
}

// ignore: must_be_immutable
class TagViewPage extends StatelessWidget {
  TagViewPage({Key? key}) : super(key: key);
  late double pageWidth;
  late TagInfoManager tagManager;
  final GlobalKey<ArticleState> _globalKey = GlobalKey();
  List<String> curSelTags = [];

  onChangeChipSelect(List<String> selTags) {
    curSelTags = selTags;
    _globalKey.currentState!.freshData(getArticleModelList());
  }

  Widget buildChipsWidget(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(8),
        child: FilterChipView(
            maxHeight: 250,
            onChanged: onChangeChipSelect,
            labels: tagManager.allTags
                .map((e) => ActorFilterEntry(
                    e, tagManager.getNoteMountInTag(e).toString()))
                .toList()));
  }

  List<NoteInfo> getArticleModelList() {
    return tagManager.getSelectedTagNote(curSelTags.toSet());
  }

  Widget buildSimpleNoteList(BuildContext context) {
    return Container(
        width: pageWidth,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ArticleList(
          key: _globalKey,
          articleList: getArticleModelList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    tagManager = TagInfoManager(context.watch<NoteInfoModel>().noteInfo);
    tagManager.scanTags();
    return LayoutBuilder(builder: ((context, constraints) {
      pageWidth = constraints.maxWidth;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PageHeader(title: "标签"),
          Text(
            "共有 ${tagManager.tagMount} 个标签",
            style: Theme.of(context).textTheme.headline6,
          ),
          buildChipsWidget(context),
          Expanded(child: buildSimpleNoteList(context)),
        ],
      );
    }));
  }
}
