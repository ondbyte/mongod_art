import 'dart:convert';
import 'dart:io';

import 'std_listener.dart';

class MongoShellException implements Exception {
  final String message;

  MongoShellException(this.message);
}

class MongoDB {
  late ProcessController _processController;

  Future init(MongoConnectionData data) async {
    try {
      var executable = _executableString(data);
      _processController = await ProcessController.start(
        executable.key,
        executable.value,
        firstWords: (words) {},
      );
    } catch (e) {
      throw MongoShellException("cannot start mongo shell");
    }
  }

  Future<bool> get coolDown {
    return _processController?.coolDown ?? Future.value(false);
  }

  Future<Map<dynamic, dynamic>> sample(
      {String collection = "collection", int size = 2}) async {
    final responseToAwait = _processController?.listenForOut;
    final sampleMap = {
      "\$sample": {"size": size}
    };
    final queryString = "db.$collection.aggregate([${sampleMap.toString()}])";
    _processController?.write(queryString);
    final response = await responseToAwait;
    final map = jsonDecode(response ?? "{}");
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
    if (!(_processController?.kill() ?? true)) {
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
