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

  /// 对齐宽度判断
  late final double _boxWidth;

  /// 容器高度
  final double boxHeight;

  /// 对齐高度判断
  late final double _boxHeight;

  /// 字号
  final double size;

  /// 字体
  final String? family;

  /// 行高
  final double height;

  /// 实际行高
  late final double _height;

  /// 段高
  final double paragraph;

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
  /// * [paragraph] 段高
  /// * [shouldJustifyHeight] 是否底栏对齐
  /// * [boxWidth] 容器宽度
  /// * [boxHeight] 容器高度
  TextComposition({
    List<String>? paragraphs,
    this.text,
    this.size = 14,
    this.height = 1,
    this.family,
    this.paragraph = 0.0,
    this.shouldJustifyHeight = true,
    required this.boxWidth,
    required this.boxHeight,
  }) {
    _height = size * height;
    _boxWidth = boxWidth - size;
    _boxHeight = boxHeight - _height;
    _paragraphs = paragraphs ?? text?.split("\n") ?? <String>[];
    _pages = <TextPage>[];
    _lines = <TextLine>[];

    /// [tp] 只有一行的`TextPainter` [offset] 只有一行的`offset` [boxHeight2] 下一行是新段落时\
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final offset = Offset(boxWidth, 1);
    final boxHeight2 = boxHeight - _height - paragraph;
    final style = TextStyle(fontSize: size, fontFamily: family);

    var paragraphCount = 0;
    var pageHeight = 0.0;
    var endLine = 0;
    var startLine = endLine;

    /// 下一页
    void newPage() {
      _pages.add(TextPage(startLine, endLine, pageHeight, paragraphCount));
      paragraphCount = 0;
      pageHeight = 0.0;
      startLine = endLine;
    }

    for (var p in _paragraphs) {
      while (true) {
        tp.text = TextSpan(text: p, style: style);
        tp.layout(maxWidth: boxWidth);
        final textCount = tp.getPositionForOffset(offset).offset;
        lines.add(TextLine(
            text: p.substring(0, textCount), textCount: textCount, width: tp.width));
        endLine++;
        pageHeight += _height;
        p = p.substring(textCount);

        /// 段落结束 跳出循环 判断分页 依据: `_boxHeight` `_boxHeight2`是否可以容纳下一行
        if (p.isEmpty) {
          if (pageHeight > boxHeight2) {
            newPage();
          } else {
            lines.add(TextLine(paragraphGap: true));
            pageHeight += paragraph;
            paragraphCount++;
            endLine++;
          }
          break;
        } else if (pageHeight > _boxHeight) {
          newPage();
        }
      }
    }
    if (endLine > startLine) {
      _pages.add(TextPage(startLine, endLine, pageHeight, paragraphCount, false));
    }
  }

  TextSpan getLineView(TextLine line) {
    if (line.textCount == 0) return TextSpan(text: "");
    if (line.width < _boxWidth) return TextSpan(text: line.text);
    return TextSpan(
      text: line.text,
      style: TextStyle(
        wordSpacing: (boxWidth - line.width) / line.textCount,
      ),
    );
  }

  TextSpan getPageView(TextPage page) {
    final paragraphHeight = shouldJustifyHeight && page.shouldJustifyHeight
        ? (boxHeight - page.height) / page.paragraphCount
        : 1.0;
    return TextSpan(
      style: TextStyle(
        height: height,
        fontSize: size,
        fontFamily: family,
      ),
      children: lines.sublist(page.startLine, page.endLine).map((line) {
        if (line.paragraphGap)
          return TextSpan(
            text: "",
            style: TextStyle(
              fontSize: paragraph,
              height: paragraphHeight,
            ),
          );
        return getLineView(line);
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
  TextLine({
    this.text = "",
    this.textCount = 0,
    this.width = 0,
    this.paragraphGap = false,
  });
}
