import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'text_composition.dart';

class AutoPage extends StatelessWidget {
  /// 自动
  static const AUTO = -1;

  /// 无动画
  static const NONE = 0;

  /// 渐变 淡入
  static const FADE = 1;

  /// 滑动
  static const SLIDEHorizontal = 2;

  /// 滑动上下
  static const SLIDEVertical = 3;

  final TextComposition textComposition;
  final int currentPage;
  final FutureOr<bool> Function(bool next)? loadChapter;
  final void Function()? toggleMenu;
  final int type;

  const AutoPage(this.textComposition,
      [this.currentPage = 0,
      this.type = AUTO,
      this.loadChapter,
      this.toggleMenu]);

  nextPage(BuildContext context, int type, bool next, [int? page]) async {
    page ??= next ? currentPage + 1 : currentPage - 1;
    if (this.type > 0) type = this.type;
    if (page < 0) {
      print("已经是第一页");
      final r = await loadChapter?.call(next);
      if (r != true) return;
      page = textComposition.pageCount - 1;
    } else if (page >= textComposition.pageCount) {
      print("已经是最后一页");
      final r = await loadChapter?.call(next);
      if (r != true) return;
      page = 0;
    }
    Navigator.pushReplacement(
        context, createRoute(AutoPage(textComposition, page, type), type, next));
  }

  Route createRoute(Widget child, int type, bool next) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black45, //底色,阴影颜色
              offset: Offset(0, 0), //阴影位置,从什么位置开始
              blurRadius: 2, // 阴影模糊层度
              spreadRadius: 2, //阴影模糊大小
            ),
            BoxShadow(
              color: Colors.black87, //底色,阴影颜色
              offset: Offset(0, 0), //阴影位置,从什么位置开始
              blurRadius: 2, // 阴影模糊层度
              spreadRadius: 2, //阴影模糊大小
            ),
            BoxShadow(
              color: Colors.black45, //底色,阴影颜色
              offset: Offset(0, 0), //阴影位置,从什么位置开始
              blurRadius: 2, // 阴影模糊层度
              spreadRadius: 2, //阴影模糊大小
            ),
          ],
        ),
        child: child,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case SLIDEHorizontal:
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(next ? 0.8 : -0.8, 0),
                end: Offset(0.0, 0.0),
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              )),
              child: child,
            );
          case SLIDEVertical:
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, next ? 0.8 : -0.8),
                end: Offset(0.0, 0.0),
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.fastOutSlowIn,
              )),
              child: child,
            );
          case NONE:
            return child;
          case FADE:
            return FadeTransition(
              opacity:
                  Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.fastLinearToSlowEaseIn,
              )),
              child: child,
            );
          default:
            return FadeTransition(
              opacity:
                  Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.fastLinearToSlowEaseIn,
              )),
              child: child,
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onVerticalDragEnd: (DragEndDetails details) {
          final v = details.primaryVelocity ?? 0;
          if (v > 0) {
            nextPage(context, SLIDEVertical, false);
          } else if (v < 0) {
            nextPage(context, SLIDEVertical, true);
          }
        },
        onHorizontalDragEnd: (DragEndDetails details) {
          final v = details.primaryVelocity ?? 0;
          if (v > 0) {
            nextPage(context, SLIDEHorizontal, false);
          } else if (v < 0) {
            nextPage(context, SLIDEHorizontal, true);
          }
        },
        onTapUp: (TapUpDetails details) {
          final size = MediaQuery.of(context).size;
          final _centerL = size.width * (1 / 3);
          final _centerR = size.width - _centerL;
          final _centerT = size.height * (1 / 3);
          final _centerB = size.height - _centerT;

          if (details.globalPosition.dx > _centerL &&
              details.globalPosition.dx < _centerR &&
              details.globalPosition.dy > _centerT &&
              details.globalPosition.dy < _centerB) {
            toggleMenu?.call();
          } else {
            if (details.globalPosition.dx < size.width * 0.5 &&
                details.globalPosition.dy < size.height * 0.5) {
              nextPage(context, NONE, false);
            } else {
              nextPage(context, NONE, true);
            }
          }
        },
        child: RawKeyboardListener(
          focusNode: new FocusNode(),
          autofocus: true,
          onKey: (event) {
            if (event.runtimeType.toString() == 'RawKeyUpEvent') return;
            if (event.data is RawKeyEventDataMacOs ||
                event.data is RawKeyEventDataLinux ||
                event.data is RawKeyEventDataWindows) {
              final logicalKey = event.data.logicalKey;
              print(logicalKey);
              if (logicalKey == LogicalKeyboardKey.arrowUp) {
                nextPage(context, SLIDEVertical, false);
              } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
                nextPage(context, SLIDEHorizontal, false);
              } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                nextPage(context, SLIDEVertical, true);
              } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
                nextPage(context, SLIDEHorizontal, true);
              } else if (logicalKey == LogicalKeyboardKey.home) {
                nextPage(context, FADE, false, 0);
              } else if (logicalKey == LogicalKeyboardKey.end) {
                nextPage(
                    context, FADE, false, textComposition.pageCount - 1);
              } else if (logicalKey == LogicalKeyboardKey.enter ||
                  logicalKey == LogicalKeyboardKey.numpadEnter) {
                toggleMenu?.call();
              } else if (logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
              }
            }
          },
          child: textComposition.getPageWidget(pageIndex: currentPage),
        ),
      ),
    );
  }
}
