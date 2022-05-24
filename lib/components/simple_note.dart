import 'package:flutter/material.dart';
import 'package:flutter_application/index.dart';

// 文章组件
class ArticleList extends StatefulWidget {
  final List<NoteInfo> articleList;

  const ArticleList({
    Key? key,
    this.articleList = const [],
  }) : super(key: key);

  @override
  ArticleState createState() => ArticleState();
}

class ArticleState extends State<ArticleList> {
  final ScrollController _controller = ScrollController(); //ListView控制器
  List<NoteInfo> _articleList = [];

  List<Widget> buildArticle() {
    List<Widget> articles = [];
    for (var element in _articleList) {
      articles.add(ArticleSingle(element));
    }
    return articles;
  }

  @override
  void initState() {
    super.initState();
    _articleList = widget.articleList;
  }

  void freshData(List<NoteInfo> newData) {
    setState(() {
      _articleList = newData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: _articleList.isEmpty
            ? const Center(
                child: Text('没有数据'),
              )
            : ListView(
                controller: _controller,
                children: buildArticle(),
              ));
  }
}

class ArticleSingle extends StatelessWidget {
  final NoteInfo articleModel;

  const ArticleSingle(this.articleModel, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> getTagList() {
      List<Widget> tagList = [];
      for (var element in articleModel.tags) {
        tagList.add(Padding(
          padding: const EdgeInsets.all(5),
          child: RawChip(
              label: Text(element),
              labelStyle: const TextStyle(fontSize: 12.0),
              padding: const EdgeInsets.all(0)),
        ));
      }
      return tagList;
    }

    return InkWell(
      onTap: () => {
        // print("点击文章"),
        context.read<CurShowingNoteModel>().setCurShowNote(articleModel),
        // routePush(new ArticleDetail())
      },
      child: Container(
        decoration: BoxDecoration(
          border: BorderDirectional(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1.5,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              articleModel.title,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              maxLines: 1,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 18.0),
            ),
            Text(
              articleModel.subTitle,
              style: const TextStyle(
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                    child: SizedBox(
                  width: 100,
                  height: 40,
                  child: AutoScollRow(speed: 50, children: [...getTagList()]),
                )),
                const SizedBox(width: 5),
                Text(articleModel.time,
                    style: const TextStyle(
                        fontWeight: FontWeight.normal, fontSize: 12.0))
              ],
            ),
            if (articleModel.abstract.isNotEmpty)
              Text(
                articleModel.abstract,
                style: const TextStyle(
                    // fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                    color: Color.fromARGB(179, 107, 106, 106)),
              ),
          ],
        ),
      ),
    );
  }
}
