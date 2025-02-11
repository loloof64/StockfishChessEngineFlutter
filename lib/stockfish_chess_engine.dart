// Using code from https://github.com/jusax23/flutter_stockfish_plugin
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';

import 'stockfish_chess_engine_bindings_generated.dart';
import 'stockfish_chess_engine_state.dart';

const String _libName = 'stockfish_chess_engine';
//const String _releaseType = kDebugMode ? 'Debug' : 'Release';

/// The dynamic library in which the symbols for [StockfishChessEngineBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.process();
    //return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  if (Platform.isLinux) {
    return DynamicLibrary.open(
        '${File(Platform.resolvedExecutable).parent.parent.path}/plugins/stockfish_chess_engine/shared/lib$_libName.so');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final StockfishChessEngineBindings _bindings =
    StockfishChessEngineBindings(_dylib);

/// A wrapper for C++ engine.
class Stockfish {
  final Completer<Stockfish>? completer;

  final _state = _StockfishState();
  final _stdoutController = StreamController<String>.broadcast();
  final _stderrController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();
  final _stderrPort = ReceivePort();

  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;
  late StreamSubscription _stderrSubscription;

  Stockfish._({this.completer}) {
    _mainSubscription =
        _mainPort.listen((message) => _cleanUp(message is int ? message : 1));
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _stdoutController.sink.add(message);
      } else {
        developer.log('The stdout isolate sent $message', name: 'Stockfish');
      }
    });
    _stderrSubscription = _stderrPort.listen((message) {
      if (message is String) {
        _stderrController.sink.add(message);
      } else {
        developer.log('The stderr isolate sent $message', name: 'Stockfish');
      }
    });
    compute(_spawnIsolates, [_mainPort.sendPort, _stdoutPort.sendPort, _stderrPort.sendPort]).then(
      (success) {
        final state = success ? StockfishState.ready : StockfishState.error;
        _state._setValue(state);
        if (state == StockfishState.ready) {
          completer?.complete(this);
        }
      },
      onError: (error) {
        developer.log('The init isolate encountered an error $error',
            name: 'Stockfish');
        _cleanUp(1);
      },
    );
  }

  static Stockfish? _instance;

  /// Creates a C++ engine.
  ///
  /// This may throws a [StateError] if an active instance is being used.
  /// Owner must [dispose] it before a new instance can be created.
  factory Stockfish() {
    if (_instance != null) {
      throw StateError('Multiple instances are not supported, yet.');
    }

    _instance = Stockfish._();
    return _instance!;
  }

  /// The current state of the underlying C++ engine.
  ValueListenable<StockfishState> get state => _state;

  /// The standard output stream.
  Stream<String> get stdout => _stdoutController.stream;

  /// The standard error stream.
  Stream<String> get stderr => _stderrController.stream;

  /// The standard input sink.
  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != StockfishState.ready) {
      throw StateError('Stockfish is not ready ($stateValue)');
    }

    final unicodePointer = '$line\n'.toNativeUtf8();
    final pointer = unicodePointer.cast<Char>();
    _bindings.stockfish_stdin_write(pointer);
    calloc.free(unicodePointer);
  }

  /// Stops the C++ engine.
  void dispose() {
    final stateValue = _state.value;
    if (stateValue == StockfishState.ready) {
      stdin = 'quit';
    }
    _cleanUp(0);
  }

  void _cleanUp(int exitCode) {
    _stderrController.close();
    _stdoutController.close();

    _mainSubscription.cancel();
    _stdoutSubscription.cancel();
    _stderrSubscription.cancel();

    _state._setValue(
        exitCode == 0 ? StockfishState.disposed : StockfishState.error);

    _instance = null;
  }
}

/// Creates a C++ engine asynchronously.
///
/// This method is different from the factory method [Stockfish] that
/// it will wait for the engine to be ready before returning the instance.
Future<Stockfish> stockfishAsync() {
  if (Stockfish._instance != null) {
    return Future.error(StateError('Only one instance can be used at a time'));
  }

  final completer = Completer<Stockfish>();
  Stockfish._instance = Stockfish._(completer: completer);
  return completer.future;
}

class _StockfishState extends ChangeNotifier
    implements ValueListenable<StockfishState> {
  StockfishState _value = StockfishState.starting;

  @override
  StockfishState get value => _value;

  _setValue(StockfishState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}

void _isolateMain(SendPort mainPort) {
  final exitCode = _bindings.stockfish_main();
  mainPort.send(exitCode);

  developer.log('nativeMain returns $exitCode', name: 'Stockfish');
}

void _isolateStdout(SendPort stdoutPort) async {
  String previous = '';

  while (true) {
    ///////////////////////////////
    developer.log('Previous in stdout [$previous]', name: 'Stockfish');
    ///////////////////////////////
    final pointer = _bindings.stockfish_stdout_read();

    if (pointer.address == 0) {
      developer.log('nativeStdoutRead returns NULL', name: 'Stockfish');
      return;
    }

    Uint8List newContentCharList;

    final newContentLength = pointer.cast<Utf8>().length;
    newContentCharList = Uint8List.view(
        pointer.cast<Uint8>().asTypedList(newContentLength).buffer,
        0,
        newContentLength);

    final newContent = utf8.decode(newContentCharList);

    ///////////////////////////////
    developer.log('NewContent in stdout [$newContent]', name: 'Stockfish');
    ///////////////////////////////

    final data = previous + newContent;
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
    }

  }
}

void _isolateStderr(SendPort stderrPort) async {
  String previous = '';

  while (true) {
    final pointer = _bindings.stockfish_stderr_read();

    if (pointer.address == 0) {
      developer.log('nativeStderrRead returns NULL', name: 'Stockfish');
      return;
    }

    Uint8List newContentCharList;

    final newContentLength = pointer.cast<Utf8>().length;
    newContentCharList = Uint8List.view(
        pointer.cast<Uint8>().asTypedList(newContentLength).buffer,
        0,
        newContentLength);

    final newContent = utf8.decode(newContentCharList);

    final data = previous + newContent;
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stderrPort.send(line);
    }
  }
}

Future<bool> _spawnIsolates(List<SendPort> mainAndStdoutAndStdErr) async {
  try {
    await Isolate.spawn(_isolateStderr, mainAndStdoutAndStdErr[2]);
  } catch (error) {
    developer.log('Failed to spawn stderr isolate: $error', name: 'Stockfish');
    return false;
  }

  try {
    await Isolate.spawn(_isolateStdout, mainAndStdoutAndStdErr[1]);
  } catch (error) {
    developer.log('Failed to spawn stdout isolate: $error', name: 'Stockfish');
    return false;
  }

  try {
    await Isolate.spawn(_isolateMain, mainAndStdoutAndStdErr[0]);
  } catch (error) {
    developer.log('Failed to spawn main isolate: $error', name: 'Stockfish');
    return false;
  }

  return true;
}
