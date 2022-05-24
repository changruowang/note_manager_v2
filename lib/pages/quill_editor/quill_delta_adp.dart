List adptQuillDeltaFormat(List input) {
  for (var elem in input) {
    Map<String, dynamic> newAttr = {};
    if (elem.containsKey('insert') && elem['insert'] is Map) {
      if (elem['insert'].containsKey('image')) {
        elem['insert'] = {'image': elem['insert']['image']};
      }
    }
  }

  return input;
}
