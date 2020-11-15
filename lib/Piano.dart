import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:tonic/tonic.dart';

class PianoWidget extends StatefulWidget {
  final List allKeys;
  final bool canPlayManually;
  final FlutterMidi flutterMidi;

  PianoWidget(
      {Key key,
      @required this.allKeys,
      @required this.canPlayManually,
      @required this.flutterMidi})
      : super(key: key);

  @override
  _PianoWidgetAppState createState() => new _PianoWidgetAppState();
}

class _PianoWidgetAppState extends State<PianoWidget> {
  double get keyWidth => 100 + (100 * _widthRatio);
  double _widthRatio = 0.0;
  bool _showLabels = true;
  SnackBar snackBar;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.allKeys);
    int i = 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            // mainAxisSize: MainAxisSize.min,
            children: [
              _buildKey(28 + i, false),
              _buildKey(30 + i, false),
              _buildKey(32 + i, false),
              _buildKey(33 + i, false),
              _buildKey(35 + i, false),
              _buildKey(37 + i, false),
              _buildKey(39 + i, false),
              _buildKey(40 + i, false),
            ],
          ),
          Positioned(
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              // mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: keyWidth * 0.125 + keyWidth * 0.25),
                _buildKey(29 + i, true),
                Container(width: keyWidth * 0.25),
                _buildKey(31 + i, true),
                Container(width: keyWidth * 0.5 + keyWidth * 0.25),
                _buildKey(34 + i, true),
                Container(width: keyWidth * 0.25),
                _buildKey(36 + i, true),
                Container(width: keyWidth * 0.25),
                _buildKey(38 + i, true),
              ],
            ),
          )
        ]),
      ],
    );
  }

  Widget _buildKey(int i, bool isBlackKey) {
    bool isPlaying = false;
    // print("widget.allkeys: " + widget.allKeys.toString());

    widget.allKeys.forEach((e) => {
          if (Pitch.fromMidiNumber(e).letterName ==
                  Pitch.fromMidiNumber(i).letterName &&
              Pitch.fromMidiNumber(e).accidentalsString ==
                  Pitch.fromMidiNumber(i).accidentalsString)
            {isPlaying = true}
        });
    if (i == 40) {
      // print("yh: " + i.toString());
      // print("yh: " + Pitch.fromMidiNumber(i).letterName);
      isPlaying = false;
    }

    return InkResponse(
      containedInkWell: true,
      radius: keyWidth * 0.25,
      splashColor: Colors.pink,
      // highlightColor: Colors.pink,
      onHighlightChanged: (value) => {},
      onTap: () {
        if (!widget.canPlayManually) {
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('Use Play tab to manually play the keys!'),
            duration: Duration(seconds: 3),
          ));
        }
      },
      // onTapCancel: () => widget.flutterMidi.stopMidiNote(midi: i),
      onTapDown: widget.canPlayManually
          ? (_) => {
                widget.flutterMidi.playMidiNote(midi: i),
                Future.delayed(Duration(milliseconds: 1000), () {
                  widget.flutterMidi.stopMidiNote(midi: i);
                })
              }
          : null,
      child: Ink(
        height: isBlackKey ? 80 : 150,
        width: isBlackKey ? keyWidth * 0.25 : keyWidth * 0.5,
        // padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
            color: isPlaying
                ? Colors.pink
                : (isBlackKey ? Colors.black : Colors.white),
            // color: isblackKey ? Colors.black : Colors.white,
            border: Border.all()),
      ),
    );
  }
}
