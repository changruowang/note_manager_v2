import 'dart:convert';
import 'delta2markdown.dart';
import 'markdown2delta.dart';

const MyDeltaMarkdownCodec _kCodec = MyDeltaMarkdownCodec();

String markdownToDelta(String markdown) {
  return _kCodec.decode(markdown);
}

String deltaToMarkdown(String delta) {
  return _kCodec.encode(delta);
}

class MyDeltaMarkdownCodec extends Codec<String, String> {
  const MyDeltaMarkdownCodec();

  @override
  Converter<String, String> get decoder => DeltaMarkdownDecoder();

  @override
  Converter<String, String> get encoder => DeltaMarkdownEncoder();
}
