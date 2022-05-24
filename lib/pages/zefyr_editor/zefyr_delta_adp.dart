const _keyAtrrMap = {
  'header': 'heading',
  'list': 'block',
  'blockquote': 'block',
  'bold': 'b',
  'link': 'a'
};
const _valueAtrrMap = {
  'bullet': 'ul',
  'ordered': 'ol',
  'checked': 'cl',
  'unchecked': 'cl',
};
List adptZefyrDeltaFormat(List input) {
  for (var elem in input) {
    Map<String, dynamic> newAttr = {};
    if (elem.containsKey('attributes')) {
      elem['attributes'] = elem['attributes'].map((key, value) {
        var newKey = key;
        var newValue = value;
        if (newValue == 'checked') {
          newAttr['checked'] = true;
        }
        if (key == 'blockquote') newValue = 'quote';
        newKey = _keyAtrrMap.containsKey(key) ? _keyAtrrMap[key] : newKey;
        newValue =
            _valueAtrrMap.containsKey(value) ? _valueAtrrMap[value] : newValue;
        return MapEntry(newKey, newValue);
      });
      elem['attributes'].addAll(newAttr);
      // new
      //
    }
  }

  return input;
}
