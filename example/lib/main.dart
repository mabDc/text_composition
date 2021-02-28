import 'package:flutter/material.dart';
import 'package:text_composition/text_composition.dart';

import 'first_chapter.dart';

main(List<String> args) {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        child: Text("开"),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (BuildContext context) => Page()),
        ),
      ),
    );
  }
}

class Page extends StatelessWidget {
  const Page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final start = DateTime.now();
    final tc = TextComposition(
      paragraphs: first_chapter,
      boxHeight: 500,
      boxWidth: 320,
    );
    final end = DateTime.now();
    final style = TextStyle(color: Colors.white);
    return Scaffold(
      body: Container(
        color: Colors.deepPurple,
        width: 320 + 30,
        child: Column(
          children: [
            Text("开始时间 $start", style: style),
            Text("结束时间 $end", style: style),
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, index) => Container(
                  height: 20,
                  color: Colors.teal,
                  child: Text("页数 ${index + 1} / ${tc.pageCount}", style: style),
                ),
                itemCount: tc.pageCount,
                itemBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 500,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                            children: List.generate(
                          500 ~/ 20,
                          (index) => Container(
                            height: 20,
                            width: 30,
                            color: Colors.primaries[index % Colors.primaries.length],
                            child: Text(
                              ((index + 1) * 20).toString(),
                              textAlign: TextAlign.end,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )),
                        Expanded(child: RichText(text: tc.getPageView(tc.pages[index]))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
