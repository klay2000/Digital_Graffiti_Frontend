import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Graffiti',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Digital Graffiti'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Paper(),
        )); // This trailing comma makes auto-formatting nicer for build methods.
  }
}

class PaperCPainter extends CustomPainter {
  List<Offset> points;
  List<Paint> paints;

  PaperCPainter({points, paints}) {
    this.points = points;
    this.paints = paints;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 1; i < points.length; i++) {
      if (points.elementAt(i) == null) {
        if (i + 2 < points.length)
          i += 2;
        else
          break;
      }
      canvas.drawLine(
          points.elementAt(i), points.elementAt(i - 1), paints.elementAt(i));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}

class PaperState extends State<Paper> {
  List<Offset> points = new List();
  static ui.PictureRecorder rec = new ui.PictureRecorder();
  ui.Canvas canvas = new Canvas(rec);
  ByteData byteData;
  List<Paint> paints = new List();
  Paint currentPaint = new Paint()
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;

  static const double BUTTON_SIZE = 50;

  @override
  Widget build(BuildContext context) {
    CustomPaint paint = CustomPaint(
        painter: PaperCPainter(points: points, paints: paints),
        size: Size.infinite);

    return Scaffold(
      body: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              points.add(details.localPosition);
              paints.add(new Paint()
                ..color = currentPaint.color
                ..strokeWidth = currentPaint.strokeWidth
                ..strokeCap = StrokeCap.round);
            });
          },
          onPanEnd: (details) {
            setState(() {
              points.add(null);
              paints.add(null);
            });
            paint.painter.paint(canvas, context.size);
            rec
                .endRecording()
                .toImage(
                    context.size.width.floor(), context.size.height.floor())
                .then((ui.Image value) {
              value
                  .toByteData(format: ui.ImageByteFormat.rawRgba)
                  .then((ByteData value) {
                byteData = value;
                setState(() {
                  rec = new ui.PictureRecorder();
                  canvas = new Canvas(rec);
                });
              });
            });
          },
          child: paint),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.arrow_forward),
        onPressed: () {
          String json = jsonEncode({
            'x': 0,
            'y': 0,
            'width': context.size.width,
            'height': context.size.height,
            'rotation': 0,
            'rgba': byteData.buffer.asUint8List()
          });

          io.Socket.connect("192.168.0.25", 1337).then((io.Socket socket) {
            socket.writeln(json);
            debugPrint(json);
          });

          setState(() {
            rec = new ui.PictureRecorder();

            canvas = new Canvas(rec);

            points = new List<Offset>();

            paints = new List<Paint>();
          });
        },
      ),
      bottomNavigationBar: Row(
        children: <Widget>[
          Container(
              width: BUTTON_SIZE,
              height: BUTTON_SIZE,
              padding: EdgeInsets.all(5),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    currentPaint.color = Color.fromARGB(255, 0, 0, 0);
                  });
                },
                shape: new CircleBorder(),
                fillColor: Color.fromARGB(255, 0, 0, 0),
              )),
          Container(
              width: BUTTON_SIZE,
              height: BUTTON_SIZE,
              padding: EdgeInsets.all(5),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    currentPaint.color = Color.fromARGB(255, 255, 255, 255);
                  });
                },
                shape: new CircleBorder(),
                fillColor: Color.fromARGB(255, 255, 255, 255),
              )),
          Container(
              width: BUTTON_SIZE,
              height: BUTTON_SIZE,
              padding: EdgeInsets.all(5),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    currentPaint.color = Color.fromARGB(255, 255, 0, 0);
                  });
                },
                shape: new CircleBorder(),
                fillColor: Color.fromARGB(255, 255, 0, 0),
              )),
          Container(
              width: BUTTON_SIZE,
              height: BUTTON_SIZE,
              padding: EdgeInsets.all(5),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    currentPaint.color = Color.fromARGB(255, 0, 255, 0);
                  });
                },
                shape: new CircleBorder(),
                fillColor: Color.fromARGB(255, 0, 255, 0),
              )),
          Container(
              width: BUTTON_SIZE,
              height: BUTTON_SIZE,
              padding: EdgeInsets.all(5),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    currentPaint.color = Color.fromARGB(255, 0, 0, 255);
                  });
                },
                shape: new CircleBorder(),
                fillColor: Color.fromARGB(255, 0, 0, 255),
              )),
          Container(
              width: BUTTON_SIZE,
              height: BUTTON_SIZE,
              padding: EdgeInsets.all(5),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    currentPaint.strokeWidth += 1;
                  });
                },
                shape: new CircleBorder(),
                fillColor: Color.fromARGB(255, 255, 255, 255),
                child: Icon(Icons.arrow_upward),
              )),
          Container(
              width: BUTTON_SIZE,
              height: BUTTON_SIZE,
              padding: EdgeInsets.all(5),
              child: RawMaterialButton(
                onPressed: () {
                  setState(() {
                    currentPaint.strokeWidth -= 1;
                  });
                },
                shape: new CircleBorder(),
                fillColor: Color.fromARGB(255, 255, 255, 255),
                child: Icon(Icons.arrow_downward),
              )),
        ],
      ),
    );
  }
}

class Paper extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => PaperState();
}
