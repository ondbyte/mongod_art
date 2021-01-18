import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'std_listener.dart';

class MongoShellException implements Exception {
  final String message;

  MongoShellException(this.message);
}

class MongoDB {
  late final ProcessController _processController;
  late final String sessionId;
  final _sessionActive = Completer<bool>();

  Future init(MongoConnectionData data) async {
    try {
      var executable = _executableString(data);
      _processController = await ProcessController.start(
        executable.key,
        executable.value,
        firstWords: (words) {
          final _sid = _exctractSessionId(words);
          if (_sid.isNotEmpty) {
            Future.delayed(
              const Duration(seconds: 1),
              () {
                print("mongo shell session is active, session id: $_sid");
                _processController.stopListeningOut();
                sessionId = _sid;
                _sessionActive.complete(true);
              },
            );
          }
        },
      );
    } catch (e) {
      throw MongoShellException("cannot start mongo shell");
    }
  }

  String _exctractSessionId(String s) {
    final regex = RegExp(
        r'[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}');
    if (s.isEmpty) {
      return "";
    }
    return regex.stringMatch(s) ?? "";
  }

  Future<bool> get sessionActive => _sessionActive.future;

  Future<Map<dynamic, dynamic>> sample(
      {String collection = "collection", int size = 2}) async {
    final responseToAwait = _processController.listenForOut();
    final sampleMap = {
      "\$sample": {"size": size}
    };
    final queryString = "JSON.stringify(db.$collection.aggregate([${sampleMap.toString()}]))\n";
    _processController.write(queryString);
    final response = await responseToAwait;
    if(response == ProcessController.listenForOutErr){
      return {};
    }
    final map = jsonDecode(response);
    if (map is Map) {
      return map;
    }
    return {};
  }

  MapEntry<String, List<String>> _executableString(MongoConnectionData data) {
    // ignore: omit_local_variable_types
    final List<String> args = data.isDefaultConnectionData()
        ? []
        : [
            "--username",
            data.userName,
            "--password",
            data.passWord,
            "--authenticationDatabase",
            data.authenticationDataBase,
            "--host",
            data.host,
            "--port",
            data.port,
          ];
    return MapEntry("mongo", args);
  }

  void kill({String m = ""}) {
    if (m.isEmpty) {
      print(m);
    } else {
      print("exit");
    }
    if (!(_processController.kill())) {
      print("unable kill process by process controller");
    }
    exit(0);
  }
}

class MongoConnectionData {
  final String host;
  final String port;
  final String userName;
  final String passWord;
  final String authenticationDataBase;

  MongoConnectionData(
      {this.host = "",
      this.port = "",
      this.userName = "",
      this.passWord = "",
      this.authenticationDataBase = ""});

  static DefaultConnectionData defaultConnectionData() {
    return DefaultConnectionData();
  }

  bool isDefaultConnectionData() {
    return false;
  }
}

class DefaultConnectionData extends MongoConnectionData {
  @override
  bool isDefaultConnectionData() {
    return true;
  }
}
