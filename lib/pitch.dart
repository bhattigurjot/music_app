import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fft/flutter_fft.dart';

class PitchDetector extends StatefulWidget {
  @override
  _PitchDetectorState createState() => _PitchDetectorState();
}

class _PitchDetectorState extends State<PitchDetector> {
  FlutterFft flutterFft = new FlutterFft();

  double frequency;
  String note;
  int octave;
  bool isRecording;

  @override
  void initState() {
    isRecording = flutterFft.getIsRecording;
    frequency = flutterFft.getFrequency;
    note = flutterFft.getNote;
    octave = flutterFft.getOctave;
    super.initState();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void start() async {
    print("Starting recorder...");
    await flutterFft
        .startRecorder(); // Waits for the recorder to properly start.
    print("Recorder started.");
    if (mounted) {
      setState(() => isRecording = flutterFft
          .getIsRecording); // Set the local "isRecording" variable to true once the recorder has started.
    }

    // Listens to the update stream, whenever there's ne-> data, update the local "frequency" and "note"
    // with one of the values returned by the plugin.
    // Also update the plugin's local note and frequency variables.
    flutterFft.onRecorderStateChanged.listen(
      (data) => {
        if (mounted)
          {
            setState(
              () => {
                if (data != null)
                  {
                    // Data indexes at the end of file.
                    frequency = data[1],
                    note = data[2],
                    octave = data[5],
                  }
              },
            )
          },
        flutterFft.setNote = note,
        flutterFft.setFrequency = frequency,
        flutterFft.setOctave = octave,
      },
    );
  }

  void stop() async {
    if (flutterFft != null && flutterFft.getIsRecording) {
      await flutterFft.stopRecorder();

      if (mounted) {
        setState(() {
          this.isRecording = flutterFft.getIsRecording;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.center,
            child: isRecording
                ? Text(
                    "Current note: $note\nCurrent octave: $octave\nCurrent frequency: ${frequency.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  )
                : Text(
                    "Press record button to detect pitch.",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
          ),
        ),
        Expanded(
          child: FlatButton(
            minWidth: double.infinity,
            child: isRecording
                ? Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 100,
                  )
                : Icon(
                    Icons.keyboard_voice,
                    color: Colors.white,
                    size: 100,
                  ),
            color: isRecording ? Colors.red : Colors.blue,
            onPressed: isRecording ? stop : start,
          ),
        ),
      ],
    );
  }
}
