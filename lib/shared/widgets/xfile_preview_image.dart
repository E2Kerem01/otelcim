import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Renders a locally-picked [XFile] as an image, before it has been
/// uploaded anywhere. `dart:io`'s `File`/`Image.file` don't work on
/// Flutter Web, so this widget uses `Image.network` there instead — on
/// web, `XFile.path` is a blob: URL the browser can render directly.
class XFilePreviewImage extends StatelessWidget {
  const XFilePreviewImage(
    this.xFile, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final XFile xFile;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(xFile.path, width: width, height: height, fit: fit);
    }
    return Image.file(File(xFile.path), width: width, height: height, fit: fit);
  }
}
