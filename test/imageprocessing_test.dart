import 'package:test/test.dart';
import 'package:skygear_sdk_flutter/src/imageprocessing.dart';

ImageProcessingPipelineBuilder f() {
  return ImageProcessingPipelineBuilder();
}

void main() {
  group('ImageProcessingPipelineBuilder', () {
    test('build format', () {
      expect((f()..format("jpg")).toString(), equals("image/format,jpg"));
      expect((f()..format("png")).toString(), equals("image/format,png"));
      expect((f()..format("webp")).toString(), equals("image/format,webp"));
    });

    test('build quality', () {
      expect((f()..quality(1)).toString(), equals("image/quality,Q_1"));
      expect((f()..quality(100)).toString(), equals("image/quality,Q_100"));
    });

    test('build resize', () {
      expect(
          (f()
                ..resize(
                    scalingMode: "pad",
                    targetWidth: 1,
                    targetHeight: 2,
                    longerSide: 3,
                    shorterSide: 4,
                    color: "556677"))
              .toString(),
          equals("image/resize,m_pad,l_3,s_4,w_1,h_2,color_556677"));
    });

    test('build everything', () {
      expect(
          (f()
                ..resize(
                    scalingMode: "pad",
                    targetWidth: 1,
                    targetHeight: 2,
                    longerSide: 3,
                    shorterSide: 4,
                    color: "556677")
                ..format("jpg")
                ..quality(85))
              .toString(),
          equals(
              "image/resize,m_pad,l_3,s_4,w_1,h_2,color_556677/format,jpg/quality,Q_85"));
    });

    test('applyToUri', () {
      expect(
          (f()
                ..resize(
                    scalingMode: "pad",
                    targetWidth: 1,
                    targetHeight: 2,
                    longerSide: 3,
                    shorterSide: 4,
                    color: "556677")
                ..format("jpg")
                ..quality(85))
              .applyToUri(Uri.parse("http://example.com?pipeline=nonsense"))
              .toString(),
          equals(
              "http://example.com?pipeline=image%2Fresize%2Cm_pad%2Cl_3%2Cs_4%2Cw_1%2Ch_2%2Ccolor_556677%2Fformat%2Cjpg%2Fquality%2CQ_85"));
    });
  });
}
