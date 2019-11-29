class ImageProcessingPipelineBuilder {
  static const formatJpg = "jpg";
  static const formatPNG = "png";
  static const formatWebp = "webp";

  static const scalingModeLfit = "lfit";
  static const scalingModeMfit = "mfit";
  static const scalingModeFill = "fill";
  static const scalingModePad = "pad";
  static const scalingModeFixed = "fixed";

  static const queryName = "pipeline";

  final List<_Operation> _ops = [];

  void format(String format) {
    _ops.add(_FormatOperation(format));
  }

  void quality(int absoluteQuality) {
    _ops.add(_QualityOperation(absoluteQuality));
  }

  void resize(
      {String scalingMode,
      int targetWidth,
      int targetHeight,
      int longerSide,
      int shorterSide,
      String color}) {
    _ops.add(_ResizeOperation(
        scalingMode: scalingMode,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        longerSide: longerSide,
        shorterSide: shorterSide,
        color: color));
  }

  @override
  String toString() {
    final parts = ["image"];
    for (var op in _ops) {
      parts.add(op.toString());
    }
    return parts.join("/");
  }

  Uri applyToUri(Uri uri) {
    final q = Map<String, List<String>>.from(uri.queryParametersAll);
    q["pipeline"] = [toString()];
    return uri.replace(queryParameters: q);
  }
}

abstract class _Operation {
  String toString();
}

class _FormatOperation implements _Operation {
  final String format;

  _FormatOperation(this.format);

  @override
  String toString() {
    return "format,$format";
  }
}

class _QualityOperation implements _Operation {
  final int absoluteQuality;

  _QualityOperation(this.absoluteQuality);

  @override
  String toString() {
    return "quality,Q_$absoluteQuality";
  }
}

class _ResizeOperation implements _Operation {
  final String scalingMode;
  final int targetWidth;
  final int targetHeight;
  final int longerSide;
  final int shorterSide;
  final String color;

  _ResizeOperation(
      {this.scalingMode,
      this.targetWidth,
      this.targetHeight,
      this.longerSide,
      this.shorterSide,
      this.color});

  @override
  String toString() {
    final parts = ["resize"];
    if (scalingMode != null) {
      parts.add("m_$scalingMode");
    }
    if (longerSide != null) {
      parts.add("l_$longerSide");
    }
    if (shorterSide != null) {
      parts.add("s_$shorterSide");
    }
    if (targetWidth != null) {
      parts.add("w_$targetWidth");
    }
    if (targetHeight != null) {
      parts.add("h_$targetHeight");
    }
    if (color != null) {
      parts.add("color_$color");
    }
    return parts.join(",");
  }
}
