import 'package:json_annotation/json_annotation.dart';

part 'noteInfo.g.dart';

@JsonSerializable()
class NoteInfo {
  NoteInfo();

  late List<String> tags = [];
  late List<String> links = [];
  late String title = "";
  late String path = "";
  late String subTitle = "";
  late num abbrlink = 0;
  late String time = "";
  late String abstract = "";

  factory NoteInfo.fromJson(Map<String, dynamic> json) =>
      _$NoteInfoFromJson(json);
  Map<String, dynamic> toJson() => _$NoteInfoToJson(this);
}
