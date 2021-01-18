import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef StringListener = void Function(String);

class ProcessController {
  static const listenForOutErr = "listener_error";
  final Process _process;
  late final StreamSubscription<String> _stdErrSub, _stdOutSub;
  bool dead = false;

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

  void stopListeningOut() {
    _stdOutSub.onData(null);
  }

  void stopListeningErr() {
    _stdErrSub.onData(null);
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

  void write(String s) async {
    _process.stdin.write(s);
  }

  Future<String> get listenForErr {
    final completer = Completer<String>();
    if (dead) {
      completer.complete(listenForOutErr);
    } else {
      if (_stdErrSub != null) {
        _stdErrSub.onData((data) {
          completer.complete(data);
        });
      } else {
        completer.complete(listenForOutErr);
      }
    }
    return completer.future;
  }

  Future<String> listenForOut(
      {Duration timeOut = const Duration(seconds: 4)}) async {
    final completer = Completer<String>();
    if (dead) {
      completer.complete(listenForOutErr);
    } else {
      _stdOutSub.onData(
        (data) {
          _stdOutSub.onData(null);
          completer.complete(data);
        },
      );
    }
    final resolved = await completer.future.timeout(
      timeOut,
      onTimeout: () {
        completer.complete(listenForOutErr);
        return completer.future;
      },
    );
    _stdOutSub.onData(null);
    return resolved;
  }

  bool kill() {
    return _process.kill();
  }
}
