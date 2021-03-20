import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:text_composition/text_composition.dart';
import 'package:page_turn/page_turn.dart'as ori;

import 'first_chapter.dart';

main(List<String> args) {
  runApp(MaterialApp(home: Setting()));
}

class Setting extends StatefulWidget {
  Setting({Key? key}) : super(key: key);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  var physicalSize = window.physicalSize,
      ratio = window.devicePixelRatio,
      size = TextEditingController(text: '16'),
      height = TextEditingController(text: '1.55'),
      paragraph = TextEditingController(text: '10'),
      shouldJustifyHeight = true,
      start = DateTime.now(),
      end = DateTime.now();
  TextComposition? textComposition;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(30),
        children: [
          Text("physicalSize / ratio: $physicalSize / $ratio = ${physicalSize / ratio}"),
          TextField(
            decoration: InputDecoration(labelText: "字号 size"),
            controller: size,
            keyboardType: TextInputType.number,
          ),
          TextField(
            decoration: InputDecoration(labelText: "行高 height"),
            controller: height,
            keyboardType: TextInputType.number,
          ),
          TextField(
            decoration: InputDecoration(labelText: "段高 paragraph"),
            controller: paragraph,
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            title: Text("是否底栏对齐"),
            subtitle: Text("shouldJustifyHeight"),
            value: shouldJustifyHeight,
            onChanged: (bool value) => setState(() {
              shouldJustifyHeight = !shouldJustifyHeight;
            }),
          ),
          Text("排版开始 $start"),
          Text("排版结束 $end"),
          OutlinedButton(
            child: Text("开始或重新排版"),
            onPressed: () {
              physicalSize = window.physicalSize;
              ratio = window.devicePixelRatio;
              start = DateTime.now();
              textComposition = TextComposition(
                paragraphs: first_chapter,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: double.tryParse(size.text),
                  height: double.tryParse(height.text),
                ),
                title: "烙印纹章 第一卷 一卷全",
                titleStyle: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: double.tryParse(size.text),
                  height: 2,
                ),
                paragraph: double.tryParse(paragraph.text) ?? 10.0,
                padding: EdgeInsets.all(10),
                buildFooter: ({TextPage? page, int? pageIndex}) {
                  return Text(
                    "烙印纹章 第一卷 一卷全 ${pageIndex == null ? '' : pageIndex + 1}/${textComposition!.pageCount}",
                    style: TextStyle(fontSize: 12),
                  );
                },
                footerHeight: 24,
                shouldJustifyHeight: shouldJustifyHeight,
                linkPattern: "<img",
                linkText: (s) =>
                    RegExp('(?<=src=".*)[^/\'"]+(?=[\'"])').stringMatch(s) ?? "链接",
                linkStyle: TextStyle(
                  color: Colors.cyan,
                  fontStyle: FontStyle.italic,
                  fontSize: double.tryParse(size.text),
                  height: double.tryParse(height.text),
                ),
                // onLinkTap: (s) => Navigator.of(context).push(MaterialPageRoute(
                //     builder: (BuildContext context) => Scaffold(
                //           appBar: AppBar(),
                //           body: Image.network(
                //               RegExp('(?<=src=")[^\'"]+').stringMatch(s) ?? ""),
                //         ))),
              );
              end = DateTime.now();
              setState(() {});
            },
          ),
          SizedBox(
            height: 10,
          ),
          OutlinedButton(
            child: Text("预览 自动翻页"),
            onPressed: () async {
              if (textComposition == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('先排版才能预览'),
                ));
              } else {
                await SystemChrome.setEnabledSystemUIOverlays([]);
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (BuildContext context) => AutoPage(textComposition!)))
                    .then((value) =>
                        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values));
              }
            },
          ),
          SizedBox(
            height: 10,
          ),
          OutlinedButton(
            child: Text("预览 仿真翻页 原始版"),
            onPressed: () async {
              if (textComposition == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('先排版才能预览'),
                ));
              } else {
                await SystemChrome.setEnabledSystemUIOverlays([]);
                Navigator.of(context)
                    .push(MaterialPageRoute(
                    builder: (BuildContext context) => HomeScreen(textComposition: textComposition!,)))
                    .then((value) =>
                    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values));
              }
            },
          ),
          SizedBox(
            height: 10,
          ),
          OutlinedButton(
            child: Text("预览 仿真翻页 修改版"),
            onPressed: () async {
              if (textComposition == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('先排版才能预览'),
                ));
              } else {
                await SystemChrome.setEnabledSystemUIOverlays([]);
                Navigator.of(context)
                    .push(MaterialPageRoute(
                    builder: (BuildContext context) => PageTurn(textComposition: textComposition!,)))
                    .then((value) =>
                    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values));
              }
            },
          ),
          SizedBox(
            height: 10,
          ),
          OutlinedButton(
            child: Text("预览 水平排列"),
            onPressed: () async {
              if (textComposition == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('先排版才能预览'),
                ));
              } else {
                await SystemChrome.setEnabledSystemUIOverlays([]);
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (BuildContext context) =>
                            PageListView(textComposition: textComposition!)))
                    .then((value) =>
                        SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values));
              }
            },
          ),
        ],
      ),
    );
  }
}

class PageListView extends StatelessWidget {
  final TextComposition textComposition;
  const PageListView({required this.textComposition, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    final col = Column(
      children: List.generate(
        textComposition.boxSize.height ~/ 10,
        (index) => Container(
          height: 10,
          width: 20,
          color: index % 2 == 0 ? null : Colors.cyan,
          child: Text(
            index % 2 == 0 ? "" : (index * 10).toString(),
            textAlign: TextAlign.end,
            style: TextStyle(color: Colors.white, fontSize: 10, height: 1),
          ),
        ),
      ),
    );
    return Scaffold(
      body: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: textComposition.pageCount,
        separatorBuilder: (BuildContext context, int index) => col,
        itemBuilder: (BuildContext context, int index) {
          return textComposition.getPageWidget(pageIndex: index, debugPrint: false);
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final TextComposition textComposition;
  const HomeScreen({
    required this.textComposition,
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = GlobalKey<PageTurnState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ori.PageTurn(
        key: _controller,
        backgroundColor: Colors.white,
        showDragCutoff: false,
        lastPage: Container(child: Center(child: Text('Last Page!'))),
        children: <Widget>[
          for (var i = 0; i < widget.textComposition.pageCount; i++) widget.textComposition.getPageWidget(pageIndex: i),
        ],
      )
    );
  }
}
