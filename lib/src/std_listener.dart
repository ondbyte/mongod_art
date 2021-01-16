import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef void StringListener(String);
const listenerError = "listener_error";

class Std {
  final Process _process;
  StreamSubscription<String>? _stdErrSub, _stdOutSub;
  bool dead = false;
  final _cooledDown = Completer<bool>();

  Std(this._process) {
    _stdErrSub =
        _process.stderr.transform<String>(utf8.decoder).listen((event) {});
    _stdOutSub =
        _process.stdout.transform<String>(utf8.decoder).listen((event) {
      if(event.endsWith(">")){
        _cooledDown.complete(true);
      }
    });
    _stdOutSub?.onError((_) {
      dead = true;
    });
  }

  Future<bool> get coolDown =>_cooledDown.future;

  void write(String s) async {
    _process.stdin.write(s);
  }

  Future<String> get listenForErr {
    final completer = Completer<String>();
    if (dead) {
      completer.complete(listenerError);
    } else {
      if (_stdErrSub != null) {
        _stdErrSub?.onData((data) {
          completer.complete(data);
        });
      } else {
        completer.complete(listenerError);
      }
    }
    return completer.future;
  }

  Future<String> get listenForOut {
    final completer = Completer<String>();
    if (dead) {
      completer.complete(listenerError);
    } else {
      if (_stdOutSub != null) {
        _stdOutSub?.onData((data) {
          completer.complete(data);
        });
      } else {
        completer.complete(listenerError);
      }
    }
    return completer.future;
  }
}
