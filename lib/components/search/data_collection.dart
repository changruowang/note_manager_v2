import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../index.dart';

enum SearchState {
  inputing,
  search,
}

class SearchManagerModel extends ChangeNotifier {
  static late final SearchManagerModel _instance =
      SearchManagerModel._internal();
  SearchManagerModel._internal();
  factory SearchManagerModel() => _instance;

  String quireWord = '';
  bool initOk = false;
  Set<String> searchHistory = {'测试', '你好', '等等', '测试测试', '来测试', '要测试', '去测试'};

  final Map<String, String> _plainText = {};
  final Map<String, NoteInfo> _noteInfo = MdFileManager.noteInfo;

  init() async {
    initOk = false;
    for (var path in _noteInfo.keys) {
      var file = File(path);
      if (file.existsSync()) {
        String text = await file.readAsString();
        text = text.replaceAll(' ', '');
        _plainText[path] = text.replaceAll('\n', '');
      }
    }
    initOk = true;
  }

  List<String> getSuggestions(String input) {
    if (searchHistory.isEmpty) return [];
    return searchHistory.where((element) => element.contains(input)).toList();
  }

  void setInquireStr(String str) {
    quireWord = str;
    notifyListeners();
  }

  Future<List<NoteInfo>> getSearchResults([int maxAbstractLen = 36]) async {
    if (quireWord == '') return [];
    List<List> searchResults = [];
    searchHistory.add(quireWord);
    while (initOk != true) {
      await init();
    }
    _plainText.forEach((key, value) {
      int idx = 0;
      List<String> matchedText = [];
      do {
        idx = value.indexOf(quireWord, idx);
        if (idx >= 0 && idx < value.length) {
          matchedText.add('...' +
              value.substring(max(idx - 5, 0),
                  min(idx + 5 + quireWord.length, value.length)) +
              '...');
          idx = idx + quireWord.length;
        }
      } while (idx < value.length && idx > 0);
      if (matchedText.isNotEmpty) {
        searchResults.add([
          key,
          matchedText.join('').substring(0, maxAbstractLen),
          matchedText.length
        ]);
      }
    });
    searchResults.sort(((a, b) => b[2].compareTo(a[2])));
    return searchResults.map<NoteInfo>((e) {
      var note = _noteInfo[e[0]];
      note!.abstract = e[1];
      return note;
    }).toList();
  }
}
