import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'dart:async' show Timer;
import 'dart:io' show HttpClient, HttpClientRequest, HttpClientResponse;
import 'dart:convert' show utf8, json;

class InitSetUpPage extends StatefulWidget {
  MethodChannel methodChannel;
  InitSetUpPage({Key key, this.methodChannel}) : super(key: key);

  @override
  _InitSetUpPageState createState() => _InitSetUpPageState();
}

class _InitSetUpPageState extends State<InitSetUpPage> {
  FocusNode _focusNode;
  TextEditingController _textEditingController;
  String _errorText;
  double _visibilityUpper;
  double _visibilityLower;
  String _statusText;
  bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _visibilityUpper = 0.0;
    _visibilityLower = 1.0;
    _isEnabled = true;
    _statusText = 'Storing API Key ...';
    _focusNode = FocusNode();
    _textEditingController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    _textEditingController.dispose();
  }

  Future<bool> openInTargetApp() async {
    return await widget.methodChannel.invokeMethod(
        'openInTargetApp', <String, String>{
      'getAPIKeyURL': 'https://home.openweathermap.org/users/sign_in'
    }).then((val) => val);
  }

  Future<bool> storeAPIKey() async {
    return await widget.methodChannel.invokeMethod(
        'storeAPIKey', <String, String>{
      'apiKey': _textEditingController.text
    }).then((val) => val);
  }

  Future<void> downloadCityNames(
      {String host: '192.168.1.103',
      int port: 8000,
      String path: '/cityNames'}) async {
    return await HttpClient()
        .get(host, port, path)
        .catchError((error) => Navigator.of(context).pop(false))
        .then((HttpClientRequest req) => req.close())
        .catchError((error) => Navigator.of(context).pop(false))
        .then((HttpClientResponse resp) {
      if (resp.statusCode == 200) {
        resp.transform(utf8.decoder).transform(json.decoder).listen((data) {
          var tmpList = <Map<String, String>>[];
          var tmpMap = <String, String>{};
          for (var i in data) {
            Map<String, dynamic>.from(i).forEach((key, value) {
              if (key == 'coord') {
                tmpMap['lon'] = value['lon']?.toString() ?? "null";
                tmpMap['lat'] = value['lat']?.toString() ?? "null";
              } else
                tmpMap[key] = value.toString();
            });
            tmpList.add(tmpMap);
            tmpMap = {};
          }
          setState(() {
            _statusText = 'Storing City Names ...';
          });
          inflateCityNamesDataBase(tmpList).then((int retVal) {
            setState(() {
              _statusText = retVal == 1 ? 'Done' : 'Something went wrong :/';
            });
            Timer(Duration(seconds: 1), () {
              Navigator.of(context).pop(retVal == 1 ? true : false);
            });
          });
        });
      } else
        Navigator.of(context).pop(false);
    }).catchError((error) => Navigator.of(context).pop(false));
  }

  Future<int> inflateCityNamesDataBase(List<Map<String, String>> data) async {
    return await widget.methodChannel.invokeMethod(
        'inflateCityNamesDataBase', <String, List<Map<String, String>>>{
      'cityNames': data
    }).then((val) => val);
  }

  inputValidator() {
    if (_textEditingController.text.isEmpty) {
      FocusScope.of(context).requestFocus(_focusNode);
      setState(() {
        _errorText = "This can't be kept blank";
      });
    } else {
      _focusNode.unfocus();
      setState(() {
        _isEnabled = false;
        _visibilityUpper = 0.75;
        _visibilityLower = 0.25;
      });
      Timer(Duration(seconds: 1), () {
        storeAPIKey().then((bool val) {
          if (val) {
            setState(() {
              _statusText = 'Downloading City Names ...';
            });
            downloadCityNames();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WeatherZ'),
        textTheme: TextTheme(
          title: TextStyle(
              color: Colors.black,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic),
        ),
        elevation: 12,
        backgroundColor: Colors.cyanAccent,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Opacity(
                opacity: _visibilityLower,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      enabled: _isEnabled,
                      focusNode: _focusNode,
                      onTap: () =>
                          FocusScope.of(context).requestFocus(_focusNode),
                      onSubmitted: (String val) {
                        if (_textEditingController.text.isEmpty) {
                          FocusScope.of(context).requestFocus(_focusNode);
                          setState(() {
                            _errorText = 'This can\'t be kept blank';
                          });
                        } else
                          inputValidator();
                      },
                      onChanged: (String val) {
                        if (_errorText != null && _errorText.isNotEmpty)
                          setState(() {
                            _errorText = null;
                          });
                      },
                      controller: _textEditingController,
                      textInputAction: TextInputAction.done,
                      autofocus: true,
                      cursorWidth: 1,
                      textAlign: TextAlign.justify,
                      decoration: InputDecoration(
                        border: UnderlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.cyanAccent,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                        labelText: 'API Key',
                        contentPadding: EdgeInsets.only(
                            left: 10, right: 8, top: 10, bottom: 4),
                        errorText: _errorText,
                        hintText: 'Enter OpenWeatherMap API Key',
                        helperText: 'E.g. : b1b15e88fa797225412429c1c50c122a1',
                      ),
                    ),
                    Divider(
                      height: 8,
                      color: Colors.white,
                    ),
                    ButtonBar(
                      alignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        RaisedButton(
                          onPressed: _isEnabled ? openInTargetApp : null,
                          child: Text('Get API Key'),
                          elevation: 12,
                          color: Colors.cyanAccent,
                          splashColor: Colors.white,
                        ),
                        RaisedButton(
                          onPressed: _isEnabled ? inputValidator : null,
                          child: Text('Continue'),
                          elevation: 12,
                          color: Colors.cyanAccent,
                          splashColor: Colors.white,
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: _visibilityUpper,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(
                      backgroundColor: Colors.cyanAccent,
                      semanticsLabel: "Storing API Key ...",
                    ),
                    Divider(
                      height: 12,
                      color: Colors.white,
                    ),
                    Text(
                      _statusText,
                      style: TextStyle(
                          letterSpacing: 2,
                          color: Colors.black,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
