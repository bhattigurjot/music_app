import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:music_app/speech.dart';
import 'package:tonal/note/note.dart' as TonalNote;
import 'package:tonal/chord/chord.dart' as TonalChord;
import 'package:tonal/scale/scale.dart' as TonalScale;
import 'package:tonic/tonic.dart' as Tonic;

import 'package:tonal/dictionary/data/chords.dart' as ChordData;
import 'package:tonal/dictionary/data/scales.dart' as ScaleData;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Music'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _flutterMidi = FlutterMidi();
  String _value = "Piano.sf2";
  String noteValue = 'C';
  String octaveValue = '4';
  String chordValue = ChordData.cdata.keys.first;
  String scaleValue = ScaleData.sdata.keys.first;
  List availableChords = new List();
  Timer timer;

  String _speechResult = "";

  @override
  void initState() {
    load(_value);
    updateAvailableChordsList();
    super.initState();
  }

  void updateAvailableChordsList() {
    // Clear chord vaiue and available chords
    chordValue = null;
    availableChords.clear();
    print(availableChords);

    // Update list and select first chord
    availableChords.addAll(TonalScale.chords(scaleValue));
    chordValue = availableChords.first;
    print(availableChords);
  }

  void load(String asset) async {
    print("Loading File...");
    _flutterMidi.unmute(); // Optionally Unmute
    rootBundle
        .load("assets/sf2/" + asset)
        .then((sf2) => {_flutterMidi.prepare(sf2: sf2, name: asset)});
  }

  void playSound() {
    // 4/4 beats
    var beats = 4;
    var tempo = 120;
    var quarterNote = 60000.0 / tempo * beats; // in ms
    print("qn " + quarterNote.toString());
    int ms = (quarterNote).toInt();
    print("ms " + ms.toString());

    //
    // // print(TonalScale.modeNames("egyptian"));
    //
    // // print(ScalePattern.findByName('Diatonic Major').modes.keys.toList());
    //
    // var scalePattern = Tonic.ScalePattern.findByName('Blues');
    // var list = scalePattern.modes;
    // print(list);
    // Future.forEach(list.keys,
    //     (element) => {print("Mode: " + list[element].intervals.toString())});
    //
    // var scale = scalePattern.at(Tonic.PitchClass.parse('A'));
    // print("scale.pitchClasses");
    // print(scale.pitchClasses);
    // // print(scale.pitchClasses[0].toPitch());
    // // var chord =
    // //     Chord.fromPitches(scale.pitchClasses.map((e) => e.toPitch()).toList());
    // for (int i = 0; i < scale.pitchClasses.length; i++) {
    //   print(Tonic.Chord.parse(scale.pitchClasses[i].toString()));
    // }
    // // var chord = Chord.parse(scale.pitchClasses[1].toString());
    // // print(chord);
    //
    // print("yoyo-start");
    // // print(list["Dorian"].name);
    // // print(list["Dorian"].modes);
    // // print(list["Dorian"].intervals);
    // // print(Chord.fromPitches(scale.pitchClasses
    // //     .map((e) => e.toPitch())
    // //     .toList()
    // //     .getRange(0, 3)
    // //     .toList()));
    // // print(ChordPattern.fromIntervals(scale.intervals.getRange(0, 3)));
    // // print(Tonic.Chord.fromPitches(pitches));
    // print(Tonic.ChordPattern.fromIntervals(
    //     [Tonic.Interval.P1, Tonic.Interval.M2, Tonic.Interval.m3]));
    // print(Tonic.ChordPattern.fromIntervals(
    //     list["Dorian"].intervals.getRange(0, 3)));
    // // print(Chord.parse("C " + list["Dorian"].name));
    // print("yoyo - end");

    var notes = getMidiNotesFromTonic(noteValue + chordValue, octaveValue);
    // var notes = getMidiNotesFromTonal(noteValue + octaveValue + ' Major');
    print("notes" + notes.toString());

    if (notes == null) {
      print("Cannot play: no notes found!");
      return;
    } else {
      if (notes[0] == null) {
        print("Cannot play: no notes found!");
        return;
      }
    }

    // to ensure we don't play it again
    stopPlaying();

    int currBeat = 1;
    // Play first beat here
    playChord(notes, ms);
    // Play other beats here
    timer = Timer.periodic(Duration(milliseconds: ms), (timer) {
      playChord(notes, ms);
      print("currBeat " + currBeat.toString());
      if (currBeat == beats - 1) timer.cancel();
      currBeat++;
    });
  }

  void playChord(List notes, int startTime) {
    print("play chord");
    playMidiNotes(notes, true);
    Future.delayed(Duration(milliseconds: startTime - 100), () {
      playMidiNotes(notes, false);
    });
  }

  List getMidiNotesFromTonal(String chordName) {
    // print(Tonic.Chord.parse(chordName).pitches);
    var chord = Tonic.Chord.parse(chordName).pitches;
    print(chord);
    return chord.map((note) => note.midiNumber).toList();
  }

  List getMidiNotesFromTonic(String chordName, String interval) {
    // print(TonalChord.names());
    // print("Tone C4 midi: ");
    // print(TonalNote.midi("C4"));
    var chord = TonalChord.notes(chordName);
    print(chord);
    return chord
        .map((note) => TonalNote.midi(note + interval.toString()))
        .toList();
  }

  void playMidiNotes(List _notes, bool _play) {
    Future.forEach(
        _notes,
        (note) => {
              _play
                  ? _flutterMidi.playMidiNote(midi: note)
                  : _flutterMidi.stopMidiNote(midi: note)
            });
  }

  void stopPlaying() {
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(widget.title),
        title: Text("Test"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton(
              value: scaleValue,
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String newValue) {
                setState(() {
                  scaleValue = newValue;
                  updateAvailableChordsList();
                });
              },
              items: ScaleData.sdata.keys
                  .toList()
                  .map<DropdownMenuItem<String>>((var value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            DropdownButton(
              value: chordValue,
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String newValue) {
                setState(() {
                  chordValue = newValue;
                });
              },
              items: availableChords.map<DropdownMenuItem<String>>((var value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            DropdownButton(
              value: octaveValue,
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String newValue) {
                setState(() {
                  octaveValue = newValue;
                });
              },
              items: <String>[
                '0',
                '1',
                '2',
                '3',
                '4',
                '5',
                '6',
                '7',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            DropdownButton(
              value: noteValue,
              elevation: 16,
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String newValue) {
                setState(() {
                  noteValue = newValue;
                });
              },
              items: <String>[
                'C',
                'C#',
                'D',
                'D#',
                'E',
                'F',
                'F#',
                'G',
                'G#',
                'A',
                'A#',
                'B'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            FlatButton(
                onPressed: playSound,
                color: Colors.amber,
                child: Text(
                  "Play Button",
                  style: TextStyle(fontSize: 20.0),
                )),
            SpeechWidget(
              updateResultFxn: (value) => {
                _speechResult = value,
                print("yoyo: " + value),
              },
            ),
          ],
        ),
      ),
    );
  }
}
