import 'package:flutter/material.dart';

import 'DrawingWidget.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Graffiti',
      theme: ThemeData(
          primarySwatch: Colors.blue, backgroundColor: Colors.white70),
      home: MyHomePage(title: 'Digital Graffiti'),
    );
  }
}

// This class is the main widget for the app.
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: DrawingWidget(),
        ));
  }
}
