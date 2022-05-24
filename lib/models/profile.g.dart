// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => Profile()
  ..rootPath = json['rootPath'] as String
  ..avatarUrl = json['avatarUrl'] as String
  ..userName = json['userName'] as String
  ..token = json['token'] as String
  ..repositoryName = json['repositoryName'] as String;

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
      'rootPath': instance.rootPath,
      'avatarUrl': instance.avatarUrl,
      'userName': instance.userName,
      'token': instance.token,
      'repositoryName': instance.repositoryName,
    };
