library text_composition;

import 'package:flutter/material.dart';

/// * 暂不支持图片
/// * 文本排版
/// * 两端对齐
/// * 底栏对齐
class TextComposition {
  /// 待渲染文本内容
  /// 已经预处理: 不重新计算空行 不重新缩进
  final String? text;

  /// 待渲染文本内容
  /// 已经预处理: 不重新计算空行 不重新缩进
  late final List<String> _paragraphs;
  List<String> get paragraphs => _paragraphs;

  /// 容器宽度
  final double boxWidth;

  /// 容器高度
  final double boxHeight;

  /// 字号
  final double size;

  /// 字体
  final String? family;

  /// 行高
  final double height;

  /// 段高
  late final double paragraph;

  /// 是否底栏对齐
  final bool shouldJustifyHeight;

  /// 每一页内容
  late final List<TextPage> _pages;
  List<TextPage> get pages => _pages;
  int get pageCount => _pages.length;

  /// 全部内容
  late final List<TextLine> _lines;
  List<TextLine> get lines => _lines;
  int get lineCount => _lines.length;

  /// * 文本排版
  /// * 两端对齐
  /// * 底栏对齐
  ///
  ///
  /// * [text] 待渲染文本内容 已经预处理: 不重新计算空行 不重新缩进
  /// * [paragraphs] 待渲染文本内容 已经预处理: 不重新计算空行 不重新缩进
  /// * [paragraphs] 为空时使用[text], 否则忽略[text],
  /// * [size] 字号
  /// * [height] 行高
  /// * [family] 字体
  /// * [boxWidth] 容器宽度
  /// * [boxHeight] 容器高度
  /// * [paragraph] 段高
  /// * [shouldJustifyHeight] 是否底栏对齐
  TextComposition({
    List<String>? paragraphs,
    this.text,
    this.size = 16,
    this.height = 1.5,
    this.family,
    this.boxWidth = double.infinity,
    this.boxHeight = double.infinity,
    this.paragraph = 10,
    this.shouldJustifyHeight = true,
  }) {
    _paragraphs = paragraphs ?? text?.split("\n") ?? <String>[];
    _pages = <TextPage>[];
    _lines = <TextLine>[];

    /// [tp] 只有一行的`TextPainter` [offset] 只有一行的`offset`
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final offset = Offset(boxWidth, 1);
    final style = TextStyle(fontSize: size, fontFamily: family, height: height);
    final _height = size * height;
    final _boxHeight = boxHeight - _height;
    final _boxHeight2 = _boxHeight - paragraph;
    final _boxWidth = boxWidth - size;

    var paragraphCount = 0;
    var pageHeight = 0.0;
    var startLine = 0;

    /// 下一页
    void newPage() {
      _pages.add(TextPage(startLine, lines.length, pageHeight, paragraphCount));
      paragraphCount = 0;
      pageHeight = 0.0;
      startLine = lines.length;
    }

    for (var p in _paragraphs) {
      while (true) {
        pageHeight += _height;
        tp.text = TextSpan(text: p, style: style);
        tp.layout(maxWidth: boxWidth);
        final textCount = tp.getPositionForOffset(offset).offset;
        if (p.length == textCount) {
          lines.add(TextLine(
              text: p,
              textCount: textCount,
              width: tp.width,
              shouldJustifyWidth: tp.width > _boxWidth));
          if (pageHeight > _boxHeight2) {
            newPage();
          } else {
            pageHeight += paragraph;
            lines.add(TextLine(paragraphGap: true));
            paragraphCount++;
          }
          break;
        } else {
          lines.add(TextLine(
              text: p.substring(0, textCount),
              textCount: textCount,
              width: tp.width,
              shouldJustifyWidth: true));
          p = p.substring(textCount);
        }

        /// 段落结束 跳出循环 判断分页 依据: `_boxHeight` `_boxHeight2`是否可以容纳下一行
        if (pageHeight > _boxHeight) {
          newPage();
        }
      }
    }
    if (lines.length > startLine) {
      _pages.add(TextPage(startLine, lines.length, pageHeight, paragraphCount, false));
    }
  }

  TextSpan getLineView(TextLine line, TextPainter tp, TextStyle style) {
    if (line.textCount == 0) return TextSpan(text: "\n \n");
    if (line.shouldJustifyWidth) {
      tp.text = TextSpan(text: line.text, style: style);
      tp.layout();
      return TextSpan(
        text: line.text,
        style: TextStyle(
          letterSpacing: (boxWidth - 2 - tp.width) / line.textCount,
        ),
      );
    }
    return TextSpan(text: line.text);
  }

  TextSpan getPageView(TextPage page) {
    final paragraphHeight = shouldJustifyHeight && page.shouldJustifyHeight
        ? paragraph + (boxHeight - page.height) / page.paragraphCount
        : paragraph;
    final style = TextStyle(
      height: height,
      fontSize: size,
      fontFamily: family,
    );
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    return TextSpan(
      style: style,
      children: lines.sublist(page.startLine, page.endLine).map((line) {
        if (line.paragraphGap)
          return TextSpan(
            text: "\n \n",
            style: TextStyle(
              fontSize: paragraphHeight,
              height: 1,
            ),
          );
        return getLineView(line, tp, style);
      }).toList(),
    );
  }
}

class TextPage {
  final int startLine;
  final int endLine;
  final int paragraphCount;
  final double height;
  final bool shouldJustifyHeight;
  TextPage(this.startLine, this.endLine, this.height, this.paragraphCount,
      [this.shouldJustifyHeight = true]);
}

class TextLine {
  final String text;
  final int textCount;
  final double width;
  final bool paragraphGap;
  final bool shouldJustifyWidth;
  TextLine({
    this.text = "",
    this.textCount = 0,
    this.width = 0,
    this.paragraphGap = false,
    this.shouldJustifyWidth = false,
  });
}
