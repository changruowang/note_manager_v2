// import 'package:zefyrka/zefyrka.dart';
import 'package:zefyr/zefyr.dart';

import 'package:flutter/material.dart';
import 'dart:io';
import 'zefyr_img_comp.dart';

Map<String, Widget Function(BuildContext, EmbedNode)> _embedBuilderFunc = {
  // 'yaml': buildEmbedYaml,
  'image': buildEmbedImage,
  'hr': (BuildContext context, EmbedNode node) {
    final theme = ZefyrTheme.of(context)!;
    return Divider(
      height: theme.paragraph.style.fontSize! * theme.paragraph.style.height!,
      thickness: 2,
      color: Colors.grey.shade200,
    );
  },
};

editorToolButtons(ZefyrController controller) {
  return ZefyrToolbar(children: [
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.bold,
        icon: Icons.format_bold,
        controller: controller,
      ),
    ),
    const SizedBox(width: 1),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.italic,
        icon: Icons.format_italic,
        controller: controller,
      ),
    ),
    const SizedBox(width: 1),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.underline,
        icon: Icons.format_underline,
        controller: controller,
      ),
    ),
    const SizedBox(width: 1),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.strikethrough,
        icon: Icons.format_strikethrough,
        controller: controller,
      ),
    ),
    const SizedBox(width: 1),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.inlineCode,
        icon: Icons.code,
        controller: controller,
      ),
    ),
    Visibility(
        visible: true,
        child: VerticalDivider(
            indent: 16, endIndent: 16, color: Colors.grey.shade400)),
    Visibility(
        visible: true,
        child: ToggleStyleButton(
          attribute: NotusAttribute.rtl,
          icon: Icons.format_textdirection_r_to_l,
          controller: controller,
        )),
    VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey.shade400),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.left,
        icon: Icons.format_align_left,
        controller: controller,
      ),
    ),
    const SizedBox(width: 1),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.center,
        icon: Icons.format_align_center,
        controller: controller,
      ),
    ),
    const SizedBox(width: 1),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.right,
        icon: Icons.format_align_right,
        controller: controller,
      ),
    ),
    const SizedBox(width: 1),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.justify,
        icon: Icons.format_align_justify,
        controller: controller,
      ),
    ),
    Visibility(
        visible: true,
        child: VerticalDivider(
            indent: 16, endIndent: 16, color: Colors.grey.shade400)),
    Visibility(
        visible: true, child: SelectHeadingStyleButton(controller: controller)),
    VerticalDivider(indent: 16, endIndent: 16, color: Colors.grey.shade400),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.block.numberList,
        controller: controller,
        icon: Icons.format_list_numbered,
      ),
    ),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.block.bulletList,
        controller: controller,
        icon: Icons.format_list_bulleted,
      ),
    ),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.block.checkList,
        controller: controller,
        icon: Icons.checklist,
      ),
    ),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.block.code,
        controller: controller,
        icon: Icons.code,
      ),
    ),
    Visibility(
        visible: true,
        child: VerticalDivider(
            indent: 16, endIndent: 16, color: Colors.grey.shade400)),
    Visibility(
      visible: true,
      child: ToggleStyleButton(
        attribute: NotusAttribute.block.quote,
        controller: controller,
        icon: Icons.format_quote,
      ),
    ),
    Visibility(
        visible: true,
        child: VerticalDivider(
            indent: 16, endIndent: 16, color: Colors.grey.shade400)),
    Visibility(visible: true, child: LinkStyleButton(controller: controller)),
    Visibility(
      visible: true,
      child: InsertEmbedButton(
        controller: controller,
        icon: Icons.horizontal_rule,
      ),
    ),
    CustomInsertImageButton(
      controller: controller,
      icon: Icons.image,
    ),
  ]);
}

Widget customZefyrEmbedBuilder(BuildContext context, EmbedNode node) {
  var type = node.value.type;
  if (_embedBuilderFunc.containsKey(type)) {
    return _embedBuilderFunc[type]!(context, node);
  } else {
    print(UnimplementedError('customZefyrEmbedBuilder type $type'));
    return Text(type);
  }
}
