import 'package:flutter/material.dart';
import 'dart:async'; // 引入定时去所需要的包

// ignore: must_be_immutable
class AutoScollRow extends StatefulWidget {
  // Duration? duration; // 轮播时间
  double? padding; // 内容之间的间距
  double? speed; // 像素/s
  List<Widget> children = []; //内容
  AutoScollRow({Key? key, this.padding, this.speed, required this.children})
      : super(key: key) {
    speed ??= 100;
    padding ??= 0;
  }
  // AutoScollWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AutoScollState();
  }
}

class AutoScollState extends State<AutoScollRow> {
  late Duration duration; // 轮播时间
  late ScrollController _controller;
  late Timer _timer;
  bool direction = false;

  _intTime() {
    _timer.cancel();
    var distance = _controller.position.maxScrollExtent -
        _controller.position.minScrollExtent;
    duration =
        Duration(milliseconds: ((distance / widget.speed!) * 1000).toInt());

    // 先开始一次
    _controller.animateTo(_controller.position.maxScrollExtent,
        duration: duration, curve: Curves.linear);
    _timer = Timer.periodic(duration, (timer) {
      if (direction) {
        _controller.animateTo(_controller.position.maxScrollExtent,
            duration: duration, curve: Curves.linear);
      } else {
        _controller.animateTo(_controller.position.minScrollExtent,
            duration: duration, curve: Curves.linear);
      }
      direction = !direction;
    });
  }

  @override
  void initState() {
    super.initState();
    duration = const Duration(seconds: 1);
    _controller = ScrollController();
    _timer = Timer.periodic(duration, (timer) {
      _intTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal, // 横向滚动
      controller: _controller,
      children: widget.children,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }
}

// Description：横线
class HorizontalLine extends StatelessWidget {
  final double dashedWidth;
  final double dashedHeight;
  final Color color;

  HorizontalLine({
    this.dashedHeight = 1,
    this.dashedWidth = double.infinity,
    this.color = const Color(0xFF616161),
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(height: dashedHeight, color: color));
  }
}
