import 'dart:convert';

import 'package:collection/collection.dart' show IterableExtension;
// import 'package:flutter/rendering.dart';
// import 'package:notus_format/notus_format.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show Attribute, AttributeScope, BlockEmbed, Delta, DeltaIterator, Style;

// import 'package:flutter_quill/flutter_quill.dart'
// import 'package:quill_format/quill_format.dart' show Delta, DeltaIterator;
import 'package:zefyr/zefyr.dart';

class DeltaMarkdownEncoder extends Converter<String, String> {
  static const _lineFeedAsciiCode = 0x0A;

  late StringBuffer markdownBuffer;
  late StringBuffer lineBuffer;

  NotusAttribute? currentBlockStyle;
  late NotusStyle currentInlineStyle;

  late List<String> currentBlockLines;
  Map<String, void Function(StringBuffer buffer, Map<String, dynamic> data)>
      embedTagWriter = {};

  DeltaMarkdownEncoder() {
    embedTagWriter['image'] = _writeEmbedImage;
    embedTagWriter['hr'] = _writeEmbedHr;
  }

  /// Converts the [input] delta to Markdown.
  @override
  String convert(String input) {
    markdownBuffer = StringBuffer();
    lineBuffer = StringBuffer();
    currentInlineStyle = NotusStyle();
    currentBlockLines = <String>[];

    final inputJson = jsonDecode(input) as List<dynamic>?;
    if (inputJson is! List<dynamic>) {
      throw ArgumentError('Unexpected formatting of the input delta string.');
    }
    final delta = Delta.fromJson(inputJson);
    final iterator = DeltaIterator(delta);

    while (iterator.hasNext) {
      final operation = iterator.next();

      if (operation.data is String) {
        final operationData = operation.data as String;

        if (!operationData.contains('\n')) {
          _handleInline(lineBuffer, operationData, operation.attributes);
        } else {
          _handleLine(operationData, operation.attributes);
        }
      } else if (operation.data is Map<String, dynamic>) {
        var data = operation.data as Map<String, dynamic>;
        if (embedTagWriter.containsKey(data['_type'])) {
          embedTagWriter[data['_type']]!(lineBuffer, data);
        } else {
          UnimplementedError('embedTagWriter type ${data['_type']}');
        }
      } else {
        throw ArgumentError('Unexpected formatting of the input delta string.');
      }
    }

    _handleBlock(currentBlockStyle); // Close the last block

    return markdownBuffer.toString();
  }

  void _handleInline(
    StringBuffer buffer,
    String text,
    Map<String, dynamic>? attributes,
  ) {
    final style = NotusStyle.fromJson(attributes);

    // First close any current styles if needed
    final markedForRemoval = <NotusAttribute>[];
    // Close the styles in reverse order, e.g. **_ for _**Test**_.
    for (final value in currentInlineStyle.values.toList().reversed) {
      // TODO(tillf): Is block correct?
      if (value.scope == NotusAttributeScope.line) {
        continue;
      }
      if (style.contains(value)) {
        continue;
      }

      final padding = _trimRight(buffer);
      _writeAttribute(buffer, value, close: true);
      if (padding.isNotEmpty) {
        buffer.write(padding);
      }
      markedForRemoval.add(value);
    }

    // Make sure to remove all attributes that are marked for removal.
    for (final value in markedForRemoval) {
      currentInlineStyle.values.toList().removeWhere((v) => v == value);
    }

    // Now open any new styles.
    for (final attribute in style.values) {
      // TODO(tillf): Is block correct?
      if (attribute.scope == NotusAttributeScope.line) {
        continue;
      }
      if (currentInlineStyle.contains(attribute)) {
        continue;
      }
      final originalText = text;
      text = text.trimLeft();
      final padding = ' ' * (originalText.length - text.length);
      if (padding.isNotEmpty) {
        buffer.write(padding);
      }
      _writeAttribute(buffer, attribute);
    }

    // Write the text itself
    buffer.write(text);
    currentInlineStyle = style;
  }

  void _handleLine(String data, Map<String, dynamic>? attributes) {
    final span = StringBuffer();

    for (var i = 0; i < data.length; i++) {
      if (data.codeUnitAt(i) == _lineFeedAsciiCode) {
        if (span.isNotEmpty) {
          // Write the span if it's not empty.
          _handleInline(lineBuffer, span.toString(), attributes);
        }
        // Close any open inline styles.
        _handleInline(lineBuffer, '', null);

        var attrs = NotusStyle.fromJson(attributes).values;

        //  TODO:  增加了对check list选中状态的支持  如果是check选中状态属性中多了一个 check状态就不符合原本的 single 的要求。所以
        //         如果有  check: true 的属性优先以他为block行的属性
        NotusAttribute? lineBlock;
        if (attrs.contains(NotusAttribute.checked)) {
          lineBlock = NotusAttribute.checked;
        } else {
          lineBlock =
              NotusStyle.fromJson(attributes).values.singleWhereOrNull((a) {
            return (a.scope == NotusAttributeScope.line) &&
                (a.key != 'checked');
          });
        }

        if (lineBlock == currentBlockStyle) {
          currentBlockLines.add(lineBuffer.toString());
        } else {
          _handleBlock(currentBlockStyle);
          currentBlockLines
            ..clear()
            ..add(lineBuffer.toString());

          currentBlockStyle = lineBlock;
        }
        lineBuffer.clear();

        span.clear();
      } else {
        span.writeCharCode(data.codeUnitAt(i));
      }
    }

    // Remaining span
    if (span.isNotEmpty) {
      _handleInline(lineBuffer, span.toString(), attributes);
    }
  }

  void _handleEmbed(Map<String, dynamic> data) {
    if (embedTagWriter.containsKey(data['_type'])) {
      embedTagWriter[data['_type']]!(lineBuffer, data);
    } else {
      UnimplementedError('embedTagWriter type ${data['_type']}');
    }
  }

  void _handleBlock(NotusAttribute? blockStyle) {
    if (currentBlockLines.isEmpty) {
      return; // Empty block
    }

    // If there was a block before this one, add empty line between the blocks
    if (markdownBuffer.isNotEmpty) {
      markdownBuffer.writeln();
    }

    if (blockStyle == null) {
      markdownBuffer
        ..write(currentBlockLines.join('\n'))
        ..writeln();
    } else if (blockStyle == NotusAttribute.code) {
      _writeAttribute(markdownBuffer, blockStyle);
      markdownBuffer.write(currentBlockLines.join('\n'));
      _writeAttribute(markdownBuffer, blockStyle, close: true);
      markdownBuffer.writeln();
    } else {
      // Dealing with lists or a quote.
      for (final line in currentBlockLines) {
        _writeBlockTag(markdownBuffer, blockStyle);
        markdownBuffer
          ..write(line)
          ..writeln();
      }
    }
  }

  String _trimRight(StringBuffer buffer) {
    final text = buffer.toString();
    if (!text.endsWith(' ')) {
      return '';
    }

    final result = text.trimRight();
    buffer
      ..clear()
      ..write(result);
    return ' ' * (text.length - result.length);
  }

  void _writeAttribute(
    StringBuffer buffer,
    NotusAttribute attribute, {
    bool close = false,
  }) {
    if (attribute.key == NotusAttribute.bold.key) {
      //行内样式在这里增加
      buffer.write('**');
    } else if (attribute.key == NotusAttribute.italic.key) {
      buffer.write('_');
    } else if (attribute.key == NotusAttribute.link.key) {
      buffer.write(!close ? '[' : '](${attribute.value})');
    } else if (attribute == NotusAttribute.code) {
      buffer.write(!close ? '```\n' : '\n```');
    } else {
      throw ArgumentError('Cannot handle $attribute');
    }
  }

  void _writeBlockTag(
    StringBuffer buffer,
    NotusAttribute block, {
    bool close = false,
  }) {
    if (close) {
      return; // no close tag needed for simple blocks.
    }

    if (block == NotusAttribute.bq) {
      buffer.write('> ');
    } else if (block == NotusAttribute.ul) {
      buffer.write('* ');
    } else if (block == NotusAttribute.ol) {
      buffer.write('1. ');
    } else if (block == NotusAttribute.checked) {
      buffer.write('- [x] '); // 增加对check list选中状态的支持
    } else if (block == NotusAttribute.cl) {
      buffer.write('- [ ] ');
    } else if (block.key == NotusAttribute.h1.key && block.value == 1) {
      buffer.write('# ');
    } else if (block.key == NotusAttribute.h2.key && block.value == 2) {
      buffer.write('## ');
    } else if (block.key == NotusAttribute.h3.key && block.value == 3) {
      buffer.write('### ');
    } else {
      throw ArgumentError('Cannot handle block $block');
    }
  }

  // void _writeEmbedTag(
  //   StringBuffer buffer,
  //   BlockEmbed embed, {
  //   bool close = false,
  // }) {
  //   const kImageType = 'image';
  //   const kDividerType = 'divider';

  //   if (embed.type == kImageType) {
  //     if (close) {
  //       buffer.write('](${embed.data})');
  //     } else {
  //       buffer.write('![');
  //     }
  //   } else if (embed.type == kDividerType && close) {
  //     buffer.write('\n---\n\n');
  //   }
  // }

  void _writeEmbedImage(StringBuffer buffer, Map<String, dynamic> data) {
    try {
      var path = data['image'];
      buffer.write('![]($path)');
    } catch (e) {
      print(e);
    }
  }

  void _writeEmbedHr(StringBuffer buffer, Map<String, dynamic> data) {
    buffer.write('\n---\n\n');
  }
}
