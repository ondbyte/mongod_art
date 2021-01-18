import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef StringListener = void Function(String);

const listenerError = "listener_error";

class ProcessController {
  Process _process;
  late final StreamSubscription<String> _stdErrSub, _stdOutSub;
  bool dead = false;
  final _cooledDown = Completer<bool>();

  ProcessController._init(this._process, {Function(String)? firstWords}) {
    try {
      _stdErrSub =
          _process.stderr.transform<String>(utf8.decoder).listen((event) {});
      _stdOutSub = _process.stdout.transform<String>(utf8.decoder).listen(
        (event) {
          firstWords?.call(event);
        },
      );
      _stdOutSub.onError(
        (_) {
          dead = true;
        },
      );
    } on ProcessException catch (e) {
      rethrow;
    }
  }

  static Future<ProcessController> start(
    String executable,
    List<String> arguments, {
    Function(String)? firstWords,
  }) async {
    try {
      final process = await Process.start(executable, arguments);
      return ProcessController._init(process, firstWords: firstWords);
    } on ProcessException catch (e) {
      rethrow;
    }
  }

  Future<bool> get coolDown => _cooledDown.future;

  void write(String s) async {
    _process.stdin.write(s);
  }

  Future<String> get listenForErr {
    final completer = Completer<String>();
    if (dead) {
      completer.complete(listenerError);
    } else {
      if (_stdErrSub != null) {
        _stdErrSub.onData((data) {
          completer.complete(data);
        });
      } else {
        completer.complete(listenerError);
      }
    }
    return completer.future;
  }

  Future<String> listenForOut(
      {Duration timeOut = const Duration(seconds: 4)}) async {
    final completer = Completer<String>();
    if (dead) {
      completer.complete(listenerError);
    } else {
      _stdOutSub.onData(
        (data) {
          _stdOutSub.onData(null);
          completer.complete(data);
        },
      );
    }
    final resolved =
        await completer.future.timeout(timeOut, onTimeout: () => listenForErr);
    return resolved;
  }

  bool kill() {
    return _process.kill();
  }
}
