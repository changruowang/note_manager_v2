// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'noteInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteInfo _$NoteInfoFromJson(Map<String, dynamic> json) => NoteInfo()
  ..tags = (json['tags'] as List<dynamic>).map((e) => e as String).toList()
  ..title = json['title'] as String
  ..path = json['path'] as String
  ..subTitle = json['subTitle'] as String
  ..abbrlink = json['abbrlink'] as num
  ..time = json['time'] as String
  ..abstract = json['abstract'] as String;

Map<String, dynamic> _$NoteInfoToJson(NoteInfo instance) => <String, dynamic>{
      'tags': instance.tags,
      'title': instance.title,
      'path': instance.path,
      'subTitle': instance.subTitle,
      'abbrlink': instance.abbrlink,
      'time': instance.time,
      'abstract': instance.abstract,
    };
