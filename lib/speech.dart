import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:speech_recognition/speech_recognition.dart';

class SpeechWidget extends StatefulWidget {
  final Function updateResultFxn;

  SpeechWidget({Key key, this.updateResultFxn}) : super(key: key);

  @override
  _SpeechWidgetAppState createState() => new _SpeechWidgetAppState();
}

const languages = const [
  const Language('English', 'en_US'),
  const Language('Francais', 'fr_FR'),
  const Language('Pусский', 'ru_RU'),
  const Language('Italiano', 'it_IT'),
  const Language('Español', 'es_ES'),
];

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}

class _SpeechWidgetAppState extends State<SpeechWidget> {
  SpeechRecognition _speech;
  String textResult = "Test";

  //String _currentLocale = 'en_US';
  Language selectedLang = languages.first;
  bool _speechRecognitionAvailable = false;
  bool _isListening = false;

  @override
  initState() {
    super.initState();
    activateSpeechRecognizer();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void activateSpeechRecognizer() {
    print('_MyAppState.activateSpeechRecognizer... ');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    _speech.setCurrentLocaleHandler(onCurrentLocale);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech.activate().then((res) => {
          if (mounted) {setState(() => _speechRecognitionAvailable = res)}
        });
  }

  void start() => _speech
      .listen(locale: selectedLang.code)
      .then((result) => print('_MyAppState.start => result ${result}'));

  void cancel() => _speech.cancel().then((result) => {
        if (mounted) {setState(() => _isListening = result)}
      });

  void stop() => _speech
      .stop()
      .then((result) => mounted ? setState(() => _isListening = result) : null);

  void onSpeechAvailability(bool result) =>
      setState(() => _speechRecognitionAvailable = result);

  void onCurrentLocale(String locale) {
    print('_MyAppState.onCurrentLocale... $locale');
    setState(
        () => selectedLang = languages.firstWhere((l) => l.code == locale));
  }

  void onRecognitionStarted() => setState(() => _isListening = true);

  void onRecognitionResult(String text) =>
      setState(() => {textResult = text, widget.updateResultFxn(text)});

  void onRecognitionComplete() => setState(() => _isListening = false);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            child: Icon(Icons.keyboard_voice),
            backgroundColor: Colors.blue,
            onPressed: _speechRecognitionAvailable && !_isListening
                ? () => start()
                : null,
          ),
          Text(
            textResult,
            style: TextStyle(
              fontSize: 15,
            ),
            softWrap: true,
          ),
          FlatButton(
              onPressed: _isListening ? () => stop() : null,
              color: Colors.red,
              child: Text(
                "Stop",
                style: TextStyle(fontSize: 20.0),
              ))
        ],
      ),
    );
  }
}
