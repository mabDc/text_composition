library text_composition;

import 'package:flutter/material.dart';

/// * 文本排版
/// * 两端对齐
/// * 底栏对齐
class TextComposition {
  /// 待渲染文本内容
  /// 已经预处理: 不重新计算空行 不重新缩进
  final String? text;

  /// 待渲染文本内容
  /// 已经预处理: 不重新计算空行 不重新缩进
  final List<String>? paragraphs;

  /// 页面宽度
  final double screenWidth;

  /// 页面高度
  final double screenHeight;

  /// 字号
  final double size;

  /// 字体
  final String? family;

  /// 行高
  final double height;

  /// 段高
  final double paragraph;

  /// 是否底栏对齐
  final bool shouldJustifyHeight;

  /// 每一页内容
  late List<TextPage> _pages;
  List<TextPage> get pages => _pages;

  /// 每一页内容
  late List<TextLine> _lines;
  List<TextLine> get lines => _lines;
  int get pageCount => _pages.length;

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
  /// * [paragraph] 段高
  /// * [screenWidth] 页面宽度
  /// * [screenHeight] 页面高度
  /// * [isHeightJustify] 是否底栏对齐
  TextComposition({
    this.text,
    this.paragraphs,
    required this.size,
    this.height = 1,
    this.family,
    required this.paragraph,
    required this.screenWidth,
    required this.screenHeight,
    this.shouldJustifyHeight = true,
  }) {
    /// [ts] 只有一行的`TextPainter` [offset] 只有一行的`offset`
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final offset = Offset(screenWidth, 1);
    final style = TextStyle(fontSize: size, fontFamily: family);

    // TODO 分页
    _pages = <TextPage>[];
    _lines = <TextLine>[];
    var paragraphFirstLine = true;
    final lineHeight = height * size;
    var pageHeight = 0.0;
    for (var p in paragraphs ?? text?.split("\n") ?? <String>[]) {
      if (paragraphFirstLine) lines.add(TextLine(paragraphFirstLine: true));
      if (p.isEmpty) {
        lines.add(TextLine());
      } else
        while (p.isNotEmpty) {
          tp.text = TextSpan(text: p, style: style);
          tp.layout(maxWidth: screenWidth);
          final textCount = tp.getPositionForOffset(offset).offset;
          lines.add(TextLine(
              text: p.substring(0, textCount), textCount: textCount, width: tp.width));
          p = p.substring(textCount);
          pageHeight += lineHeight;
        }
      paragraphFirstLine = true;
      pageHeight += paragraph;
    }
    _pages.add(TextPage(0, _lines.length, pageHeight));
  }

  TextSpan getLineView(TextLine line) {
    if (line.textCount == 0) return TextSpan(text: "");
    if (screenWidth - line.width < size) return TextSpan(text: line.text);
    return TextSpan(
      text: line.text,
      style: TextStyle(
        wordSpacing: (screenWidth - line.width) / line.textCount,
      ),
    );
  }

  TextSpan getPageView(TextPage page) {
    final paragraphHeight = screenHeight - page.height < paragraph
        ? (screenHeight - page.height) / (page.endLine - page.endLine)
        : 1.0;
    return TextSpan(
      style: TextStyle(
        height: height,
        fontSize: size,
        fontFamily: family,
      ),
      children: lines.sublist(page.startLine, page.endLine).map((line) {
        if (line.paragraphFirstLine)
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
  final double height;
  TextPage(this.startLine, this.endLine, this.height);
}

class TextLine {
  final String text;
  final int textCount;
  final double width;
  final bool paragraphFirstLine;
  TextLine({
    this.text = "",
    this.textCount = 0,
    this.width = 0,
    this.paragraphFirstLine = false,
  });
}
