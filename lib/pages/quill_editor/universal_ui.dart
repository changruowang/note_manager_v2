library universal_ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:universal_html/html.dart' as html;

// import '../widgets/responsive_widget.dart';
import 'fake_ui.dart' if (dart.library.html) 'real_ui.dart' as ui_instance;

class ResponsiveWidget extends StatelessWidget {
  const ResponsiveWidget({
    required this.largeScreen,
    this.mediumScreen,
    this.smallScreen,
    Key? key,
  }) : super(key: key);

  final Widget largeScreen;
  final Widget? mediumScreen;
  final Widget? smallScreen;

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800 &&
        MediaQuery.of(context).size.width <= 1200;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return largeScreen;
        } else if (constraints.maxWidth <= 1200 &&
            constraints.maxWidth >= 800) {
          return mediumScreen ?? largeScreen;
        } else {
          return smallScreen ?? largeScreen;
        }
      },
    );
  }
}

class PlatformViewRegistryFix {
  void registerViewFactory(dynamic x, dynamic y) {
    if (kIsWeb) {
      ui_instance.PlatformViewRegistry.registerViewFactory(
        x,
        y,
      );
    }
  }
}

class UniversalUI {
  PlatformViewRegistryFix platformViewRegistry = PlatformViewRegistryFix();
}

var ui = UniversalUI();

Widget defaultEmbedBuilderWeb(BuildContext context, QuillController controller,
    Embed node, bool readOnly) {
  switch (node.value.type) {
    case 'image':
      final imageUrl = node.value.data;
      final size = MediaQuery.of(context).size;
      UniversalUI().platformViewRegistry.registerViewFactory(
          imageUrl, (viewId) => html.ImageElement()..src = imageUrl);
      return Padding(
        padding: EdgeInsets.only(
          right: ResponsiveWidget.isMediumScreen(context)
              ? size.width * 0.5
              : (ResponsiveWidget.isLargeScreen(context))
                  ? size.width * 0.75
                  : size.width * 0.2,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.45,
          child: HtmlElementView(
            viewType: imageUrl,
          ),
        ),
      );

    default:
      throw UnimplementedError(
        'Embeddable type "${node.value.type}" is not supported by default '
        'embed builder of QuillEditor. You must pass your own builder function '
        'to embedBuilder property of QuillEditor or QuillField widgets.',
      );
  }
}
