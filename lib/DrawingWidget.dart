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
    ..color = Colors.blue
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;

  HSVColor HSV = HSVColor.fromColor(Colors.blue);

  static const double BUTTON_SIZE = 75;

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
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(builder: (context, setState) {
                            return AlertDialog(
                              title: Text("Color Picker"),
                              content: Row(
                                children: <Widget>[
                                  Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Padding(
                                            padding: EdgeInsets.only(top: 10)),
                                        Text("Hue"),
                                        Slider(
                                            onChanged: (newHue) {
                                              setState(() {
                                                HSV = HSV.withHue(newHue);

                                                currentPaint.color =
                                                    HSV.toColor();
                                              });
                                            },
                                            max: 360.0,
                                            min: 0.0,
                                            value: HSV.hue),
                                        Text("Saturation"),
                                        Slider(
                                          onChanged: (newSat) {
                                            setState(() {
                                              HSV = HSV.withSaturation(newSat);

                                              currentPaint.color =
                                                  HSV.toColor();
                                            });
                                          },
                                          max: 1.0,
                                          min: 0.0,
                                          value: HSV.saturation,
                                        ),
                                        Text("Value"),
                                        Slider(
                                          onChanged: (newVal) {
                                            setState(() {
                                              HSV = HSV.withValue(newVal);

                                              currentPaint.color =
                                                  HSV.toColor();
                                            });
                                          },
                                          max: 1.0,
                                          min: 0,
                                          value: HSV.value,
                                        )
                                      ]),
                                  Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.brightness_1,
                                          size: 75,
                                          color: currentPaint.color,
                                        )
                                      ])
                                ],
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  child: new Text("Done"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                )
                              ],
                            );
                          });
                        });
                  }),
              fillColor: Colors.white,
              icon: Icons.brush),
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
              icon: Icons.remove),
        ],
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
