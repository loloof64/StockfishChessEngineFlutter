// Using code from https://github.com/ArjanAswal/Stockfish/blob/master/lib/src/stockfish.dart

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';

import 'stockfish_bindings_generated.dart';
import 'stockfish_state.dart';

const String _libName = 'stockfish';

/// The dynamic library in which the symbols for [StockfishChessEngineBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
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
  final _stdoutPort = ReceivePort();

  late StreamSubscription _stdoutSubscription;

  Stockfish._({this.completer}) {
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _stdoutController.sink.add(message);
      } else {
        developer.log('The stdout isolate sent $message', name: 'Stockfish');
      }
    });
    compute(_spawnIsolate, _stdoutPort.sendPort).then(
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

  /// The standard input sink.
  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != StockfishState.ready) {
      throw StateError('Stockfish is not ready ($stateValue)');
    }

    final unicodePointer = '$line\n'.toNativeUtf8();
    final pointer = unicodePointer.cast<Char>();
    _bindings.stockfish_process_command(pointer);
    calloc.free(unicodePointer);
  }

  /// Stops the C++ engine.
  void dispose() {
    stdin = 'quit';
  }

  void _cleanUp(int exitCode) {
    _stdoutController.close();

    _stdoutSubscription.cancel();

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

void _isolateStdout(SendPort stdoutPort) {
  String previous = '';

  outerLoop:
  while (true) {
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

    final data = previous + newContent;
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
      if (line.trim() == "quit") {
        break outerLoop;
      }
    }
  }

  _bindings.stockfish_release();
}

Future<bool> _spawnIsolate(SendPort stdout) async {
  _bindings.stockfish_init();

  try {
    await Isolate.spawn(_isolateStdout, stdout);
  } catch (error) {
    developer.log('Failed to spawn stdout isolate: $error', name: 'Stockfish');
    return false;
  }

  return true;
}
