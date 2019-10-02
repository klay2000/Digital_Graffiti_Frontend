import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// Custom painter for drawing widget.
class DrawingCustomPainter extends CustomPainter {
  List<Offset> points;
  List<Paint> paints;

  DrawingCustomPainter({points, paints}) {
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
    return true;
  }
}

class DrawingWidgetState extends State<DrawingWidget> {
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
        painter: DrawingCustomPainter(points: points, paints: paints),
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

          io.Socket.connect("10.0.2.2", 1337).then((io.Socket socket) {
            socket.writeln(json);
//            debugPrint(json);
          });

          setState(() {
            rec = new ui.PictureRecorder();

            byteData = null;

            canvas = new Canvas(rec);

            points = new List<Offset>();

            paints = new List<Paint>();
          });
        },
      ),
      bottomNavigationBar: Row(
        children: <Widget>[
          BottomButton(
              size: BUTTON_SIZE,
              onPressed: () => setState(() {
                    currentPaint.color = Colors.black;
                  }),
              fillColor: Colors.black),
          BottomButton(
              size: BUTTON_SIZE,
              onPressed: () => setState(() {
                    currentPaint.color = Colors.white;
                  }),
              fillColor: Colors.white),
          BottomButton(
              size: BUTTON_SIZE,
              onPressed: () => setState(() {
                    currentPaint.color = Colors.red;
                  }),
              fillColor: Colors.red),
          BottomButton(
              size: BUTTON_SIZE,
              onPressed: () => setState(() {
                    currentPaint.color = Colors.green;
                  }),
              fillColor: Colors.green),
          BottomButton(
              size: BUTTON_SIZE,
              onPressed: () => setState(() {
                    currentPaint.color = Colors.blue;
                  }),
              fillColor: Colors.blue),
          BottomButton(
              size: BUTTON_SIZE,
              onPressed: () => setState(() {
                    currentPaint.strokeWidth =
                        pow(currentPaint.strokeWidth, 1.1);
                  }),
              fillColor: Colors.white,
              icon: Icons.add),
          BottomButton(
              size: BUTTON_SIZE,
              onPressed: () => setState(() {
                    currentPaint.strokeWidth =
                        pow(currentPaint.strokeWidth, 1 / 1.1);
                  }),
              fillColor: Colors.white,
              icon: Icons.remove)
        ],
      ),
    );
  }
}

// This widget is the main drawing widget.
class DrawingWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => DrawingWidgetState();
}

// This Widget is for the buttons at the bottom of the drawing widget.
class BottomButton extends StatelessWidget {
  BottomButton(
      {this.onPressed,
      this.size = 5.0,
      this.fillColor = Colors.white,
      this.icon});

  final onPressed;
  final size;
  final icon;
  final fillColor;

  Widget build(BuildContext context) {
    return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(5),
        child: RawMaterialButton(
          onPressed: () => onPressed(),
          shape: new CircleBorder(),
          fillColor: fillColor,
          child: (icon == null ? null : Icon(icon)),
        ));
  }
}
