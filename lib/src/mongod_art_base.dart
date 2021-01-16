import 'dart:convert';
import 'dart:io';

import 'package:mongod_art/src/std_listener.dart';

class MongoDB {
  Process? _shell;
  Std? _stdListener;

  Future init(MongoConnectionData data) async {
    if (data.isDefaultConnectionData()) {
      _shell = await _initLocalProcess();
      print("new mongo shell for local started started");
    } else {
      final process = await _initFarProcess(data);
      if(process is Process){
        _stdListener = Std(process);
      }
    }
  }

  Future<bool> get cooleDown{
    return _stdListener?.coolDown ?? Future.value(false);
  }

  Future<Map<dynamic,dynamic>> sample({String collection = "collection",int size = 2}) async {
    final responseToAwait = _stdListener?.listenForOut;
    final sampleMap = {
      "\$sample":{
        "size":size
      }
    };
    final queryString = "db.$collection.aggregate([${sampleMap.toString()}])";
    _stdListener?.write(queryString);
    final response = await responseToAwait;
    final map = jsonDecode(response ?? "{}");
    if(map is Map){
      return map;
    }
    return {};
  }

  Future<Process?> _initFarProcess(MongoConnectionData data) async {
    try {
      final process = await Process.start("mongo", [
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
      ]);
      return process;
    } on ProcessException catch (e) {
      final error =
          "unable to connect through mongo shell, exact error was\n$e";
      kill(m: error);
    } catch (e) {
      kill();
    }
  }

  Future<Process?> _initLocalProcess() async {
    try {
      final process = await Process.start("mongo", []);
      return process;
    } on ProcessException catch (e) {
      kill(
        m: "mongo shell does not exist on path, please add it to path variable",
      );
    } catch (e) {
      kill();
    }
  }

  void kill({String m=""}) {
    if (m.isEmpty) {
      print(m);
    } else {
      print("exit");
    }
    _shell?.kill();
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
