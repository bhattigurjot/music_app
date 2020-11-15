import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_midi/flutter_midi.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:music_app/Piano.dart';
import 'package:music_app/pitch.dart';
import 'package:music_app/speech.dart';
import 'package:tonal/note/note.dart' as TonalNote;
import 'package:tonal/chord/chord.dart' as TonalChord;
import 'package:tonal/scale/scale.dart' as TonalScale;
import 'package:tonal/distance/distance.dart' as TonalDistance;
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF512DAB),
        accentColor: Color(0xFF512DAB),
        // primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Break Thy Block'),
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
  List notesMidiToPlay = [];
  List availableChords = new List();
  Timer timer;
  bool isPlaying = false;

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

    var scaleNotes = TonalScale.notes(scaleValue);
    var intervals = TonalScale.intervals(scaleValue);

    // print("yoyo sn: " + scaleNotes.toString());
    // print("yoyo in: " + intervals.toString());

    final lift = (fn) => (arr) => arr.split(" ").map(fn).join(" ");

    Future.forEach(intervals, (element) {
      // print(" original: " + element.toString());
      final fxn = lift(TonalDistance.transposeBy(element.toString()));
      // print(" changed: " + fxn("C1"));
    });

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
    if (mounted) {
      setState(() {
        isPlaying = true;
      });
    }
    playChord(notes, ms);
    // Play other beats here
    timer = Timer.periodic(Duration(milliseconds: ms), (timer) {
      playChord(notes, ms);
      // print("currBeat " + currBeat.toString());
      if (currBeat == beats - 1) {
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
        ;
        timer.cancel();
      }
      ;
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

    if (mounted) {
      setState(() {
        _play ? notesMidiToPlay.addAll(_notes) : notesMidiToPlay.clear();
      });
    }
  }

  void stopPlaying() {
    if (timer != null && timer.isActive) {
      timer.cancel();
    }
    if (mounted) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  final List<Tab> tabs = <Tab>[
    Tab(
      icon: Icon(Icons.list),
      text: 'Select',
    ),
    Tab(
      icon: Icon(Icons.record_voice_over_sharp),
      text: 'Pitch',
    ),
    Tab(
      icon: Icon(Icons.search),
      text: 'Find',
    ),
    Tab(
      icon: Icon(Icons.play_arrow_sharp),
      text: 'Play',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Builder(
        builder: (BuildContext context) {
          final TabController tabController = DefaultTabController.of(context);
          tabController.addListener(() {
            if (!tabController.indexIsChanging) {
              // To get index of current tab use tabController.index
              stopPlaying();
            }
          });
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              bottom: TabBar(
                tabs: tabs,
              ),
            ),
            body: TabBarView(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              "Key",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          // Expanded(
                          //   child: DropdownSearch<String>(
                          //       mode: Mode.MENU,
                          //       showSelectedItem: true,
                          //       items: <String>[
                          //         'C',
                          //         'C#',
                          //         'D',
                          //         'D#',
                          //         'E',
                          //         'F',
                          //         'F#',
                          //         'G',
                          //         'G#',
                          //         'A',
                          //         'A#',
                          //         'B'
                          //       ],
                          //       label: "Key",
                          //       hint: "Select Key",
                          //       // popupItemDisabled: (String s) =>
                          //       //     s.startsWith('I'),
                          //       onChanged: (String newValue) {
                          //         setState(() {
                          //           noteValue = newValue;
                          //         });
                          //       },
                          //       selectedItem: noteValue),
                          // ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 20),
                              padding: EdgeInsets.only(left: 10, right: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  value: noteValue,
                                  elevation: 16,
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
                                  ].map<DropdownMenuItem<String>>((var value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              "Octave",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 20),
                              padding: EdgeInsets.only(left: 10, right: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  value: octaveValue,
                                  elevation: 16,
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
                                  ].map<DropdownMenuItem<String>>((var value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "Scale",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 20),
                              padding: EdgeInsets.only(left: 10, right: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  value: scaleValue,
                                  elevation: 16,
                                  onChanged: (String newValue) {
                                    setState(() {
                                      scaleValue = newValue;
                                    });
                                  },
                                  // items: availableChords
                                  items: ScaleData.sdata.keys
                                      .toList()
                                      .map<DropdownMenuItem<String>>(
                                          (var value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "Chord",
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 20),
                              padding: EdgeInsets.only(left: 10, right: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  value: chordValue,
                                  elevation: 16,
                                  onChanged: (String newValue) {
                                    setState(() {
                                      chordValue = newValue;
                                    });
                                  },
                                  items: availableChords
                                      .toList()
                                      .map<DropdownMenuItem<String>>(
                                          (var value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            child: isPlaying
                                ? Icon(
                                    Icons.stop_rounded,
                                    color: Colors.white,
                                    size: 50,
                                  )
                                : Icon(
                                    Icons.play_arrow_sharp,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                            backgroundColor:
                                isPlaying ? Colors.red : Color(0xFFFFC107),
                            onPressed: isPlaying ? stopPlaying : playSound,
                          ),
                        ],
                      ),
                      PianoWidget(
                        allKeys: notesMidiToPlay,
                        canPlayManually: false,
                        flutterMidi: _flutterMidi,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: PitchDetector(),
                ),
                Center(
                    child: Column(
                  children: [
                    SpeechWidget(
                      updateResultFxn: (value) => {
                        _speechResult = value,
                        print("yoyo: " + value),
                      },
                    ),
                  ],
                )),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        child: Text(
                          "On your keys\nGet set\nPlay!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                      PianoWidget(
                        allKeys: notesMidiToPlay,
                        canPlayManually: true,
                        flutterMidi: _flutterMidi,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget CustomDropDownWidget(List itemList, String val) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: 20),
        padding: EdgeInsets.only(left: 10, right: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton(
            // value: chordValue,
            value: val,
            elevation: 16,
            onChanged: (String newValue) {
              setState(() {
                // chordValue = newValue;
                val = newValue;
              });
            },
            // items: availableChords
            items: itemList.map<DropdownMenuItem<String>>((var value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
