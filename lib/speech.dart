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
  String textResult = "Press record button to record your speech.";

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
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: EdgeInsets.only(top: 50),
          child: FloatingActionButton(
            child: _isListening
                ? Icon(
                    Icons.stop_rounded,
                    color: Colors.white,
                    size: 50,
                  )
                : Icon(
                    Icons.keyboard_voice,
                    color: Colors.white,
                    size: 50,
                  ),
            backgroundColor: _isListening ? Colors.red : Color(0xFFFFC107),
            onPressed: _isListening ? stop : start,
          ),
        ),
        Container(
          alignment: Alignment.center,
          margin: EdgeInsets.all(10),
          height: 200,
          child: Text(
            textResult,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
