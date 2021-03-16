// @dart = 2.12
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

  /// 容器大小
  final Size boxSize;

  /// 单栏宽度
  late final double columnWidth;

  /// 字体样式 字号 [size] 行高 [height] 字体 [family] 字色[Color]
  final TextStyle style;

  /// 标题
  final String? title;

  /// 标题样式
  final TextStyle? titleStyle;

  /// 是否底栏对齐
  final bool shouldJustifyHeight;

  /// 段间距
  late final double paragraph;

  /// 每一页内容
  late final List<TextPage> _pages;
  List<TextPage> get pages => _pages;
  int get pageCount => _pages.length;

  /// 分栏个数
  int columnCount;

  /// 分栏间距
  double columnGap;

  final Pattern? linkPattern;
  final TextStyle? linkStyle;
  final String Function(String s)? linkText;
  // canvas 点击事件不生效
  // final void Function(String s)? onLinkTap;

  /// * 文本排版
  /// * 两端对齐
  /// * 底栏对齐
  /// * 多栏布局
  ///
  ///
  /// * [text] 待渲染文本内容 已经预处理: 不重新计算空行 不重新缩进
  /// * [paragraphs] 待渲染文本内容 已经预处理: 不重新计算空行 不重新缩进
  /// * [paragraphs] 为空时使用[text], 否则忽略[text],
  /// * [style] 字体样式 字号 [size] 行高 [height] 字体 [family] 字色[Color]
  /// * [title] 标题
  /// * [titleStyle] 标题样式
  /// * [boxSize] 容器大小
  /// * [paragraph] 段间距
  /// * [shouldJustifyHeight] 是否底栏对齐
  /// * [columnCount] 分栏个数
  /// * [columnGap] 分栏间距
  /// * onLinkTap canvas 点击事件不生效
  TextComposition({
    List<String>? paragraphs,
    this.text,
    required this.style,
    this.title,
    this.titleStyle,
    required this.boxSize,
    this.paragraph = 10.0,
    this.shouldJustifyHeight = true,
    this.columnCount = 1,
    this.columnGap = 0.0,
    this.linkPattern,
    this.linkStyle,
    this.linkText,
    // this.onLinkTap,
  }) {
    _paragraphs = paragraphs ?? text?.split("\n") ?? <String>[];
    _pages = <TextPage>[];
    columnWidth = boxSize.width - (columnCount - 1) * columnGap;

    /// [tp] 只有一行的`TextPainter` [offset] 只有一行的`offset`
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final offset = Offset(columnWidth, 1);
    final size = style.fontSize ?? 14;
    // [_boxWidth] 仅用于判断段尾是否需要调整 [size] 准确性不重要
    final _boxWidth = columnWidth - size;
    // [_boxHeight] 仅用作判断容纳下一行依据 [_height] 是否实际行高不重要
    final _boxHeight = boxSize.height - size * (style.height ?? 1.0);

    var pageHeight = 0.0;
    var isTitlePage = false;

    if (title != null && title!.isNotEmpty) {
      tp
        ..maxLines = null
        ..text = TextSpan(text: title, style: titleStyle)
        ..layout(maxWidth: columnWidth);
      pageHeight += tp.height + paragraph;
      tp.maxLines = 1;
      isTitlePage = true;
    }

    var lines = <TextLine>[];
    var columnNum = 1;
    var dx = 0.0;

    /// 下一页 判断分页 依据: `_boxHeight` `_boxHeight2`是否可以容纳下一行
    void newPage([bool shouldJustifyHeight = true]) {
      if (columnNum == columnCount) {
        columnNum = 1;
        dx = 0;
        if (shouldJustifyHeight && this.shouldJustifyHeight) {
          double justify = (boxSize.height - pageHeight) / lines.length;
          int i = -1;
          _pages.add(TextPage(
              lines.map((line) {
                i++;
                return line.apply(dy: line.dy + justify * i);
              }).toList(),
              pageHeight,
              isTitlePage));
          lines.clear();
        } else {
          _pages.add(TextPage(lines, pageHeight, isTitlePage));
          lines = <TextLine>[];
        }
        pageHeight = 0;
        if (isTitlePage) isTitlePage = false;
      } else {
        columnNum++;
        pageHeight = 0;
        dx += columnWidth + columnGap;
        if (isTitlePage) isTitlePage = false;
      }
    }

    /// 新段落
    void newParagraph() {
      if (pageHeight > _boxHeight) {
        newPage();
      } else {
        pageHeight += paragraph;
      }
    }

    for (var p in _paragraphs) {
      if (linkPattern != null && p.startsWith(linkPattern!)) {
        tp.text = TextSpan(text: p, style: linkStyle);
        tp.layout();
        lines.add(TextLine(
          dx: dx,
          dy: pageHeight,
          link: true,
          text: p,
        ));
        pageHeight += tp.height;
        newParagraph();
      } else
        while (true) {
          tp.text = TextSpan(text: p, style: style);
          tp.layout(maxWidth: columnWidth);
          final textCount = tp.getPositionForOffset(offset).offset;
          if (p.length == textCount) {
            lines.add(TextLine(
              dx: dx,
              dy: pageHeight,
              text: p,
              shouldJustifyWidth: tp.width > _boxWidth,
            ));
            pageHeight += tp.height;
            newParagraph();
            break;
          } else {
            lines.add(TextLine(
                dx: dx,
                dy: pageHeight,
                text: p.substring(0, textCount),
                shouldJustifyWidth: true));
            pageHeight += tp.height;
            p = p.substring(textCount);
            if (pageHeight > _boxHeight) {
              newPage();
            }
          }
        }
    }
    if (lines.isNotEmpty) {
      newPage(false);
    }
  }

  void paint(TextPage page, Canvas canvas, Size size, [bool debugPrint = false]) {
    if (debugPrint)
      print("****** [TextComposition paint start] [${DateTime.now()}] ******");
    final lineCount = page.lines.length;
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    if (page.isTitlePage) {
      tp.text = TextSpan(text: title, style: titleStyle);
      tp.maxLines = null;
      tp.layout(maxWidth: columnWidth);
      tp.paint(canvas, Offset.zero);
      tp.maxLines = 1;
    }
    for (var i = 0; i < lineCount; i++) {
      final line = page.lines[i];
      if (line.text.isEmpty) {
        continue;
      } else if (line.link) {
        tp.text = TextSpan(
          text: linkText?.call(line.text) ?? line.text,
          style: linkStyle,
        );
      } else if (line.shouldJustifyWidth) {
        tp.text = TextSpan(text: line.text, style: style);
        tp.layout();
        tp.text = TextSpan(
          text: line.text,
          style: style.copyWith(
            letterSpacing: (columnWidth - tp.width) / line.text.length,
          ),
        );
      } else {
        tp.text = TextSpan(text: line.text, style: style);
      }
      final offset = Offset(line.dx, line.dy);
      if (debugPrint) print("$offset ${line.text}");
      tp.layout();
      tp.paint(canvas, offset);
    }
    if (debugPrint)
      print("****** [TextComposition paint end  ] [${DateTime.now()}] ******");
  }

  /// [debug] 查看时间输出
  Widget getPageWidget({TextPage? page, bool debugPrint = false, int? pageIndex}) {
    if (page == null) page = pages[pageIndex!];
    final child = CustomPaint(painter: PagePainter(this, page, debugPrint));
    return Container(
      width: boxSize.width,
      height: boxSize.height.isInfinite ? page.height : boxSize.height,
      child: child,
    );
  }
}

class PagePainter extends CustomPainter {
  final TextComposition textComposition;
  final TextPage page;
  final bool debugPrint;
  PagePainter(this.textComposition, this.page, this.debugPrint);

  @override
  void paint(Canvas canvas, Size size) {
    textComposition.paint(page, canvas, size, debugPrint);
  }

  @override
  bool shouldRepaint(CustomPainter old) {
    return true;
  }
}

class TextPage {
  final List<TextLine> lines;
  final double height;
  final bool isTitlePage;
  const TextPage(
    this.lines,
    this.height,
    this.isTitlePage,
  );
}

class TextLine {
  final bool link;
  final String text;
  final double dx;
  final double dy;
  final bool shouldJustifyWidth;
  const TextLine({
    this.link = false,
    required this.dx,
    required this.dy,
    required this.text,
    this.shouldJustifyWidth = false,
  });

  TextLine apply({
    bool? link,
    String? text,
    double? dx,
    double? dy,
    bool? shouldJustifyWidth,
  }) {
    if (link == null) link = this.link;
    if (text == null) text = this.text;
    if (dx == null) dx = this.dx;
    if (dy == null) dy = this.dy;
    if (shouldJustifyWidth == null) shouldJustifyWidth = this.shouldJustifyWidth;
    return TextLine(
      link: link,
      dx: dx,
      dy: dy,
      text: text,
      shouldJustifyWidth: shouldJustifyWidth,
    );
  }
}
