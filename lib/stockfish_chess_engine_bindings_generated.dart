// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for `src/stockfish_chess_engine.h`.
///
/// Regenerate bindings with `dart run ffigen --config ffigen.yaml`.
///
class StockfishChessEngineBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  StockfishChessEngineBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  StockfishChessEngineBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  /// Stockfish main loop.
  int stockfish_main() {
    return _stockfish_main();
  }

  late final _stockfish_mainPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('stockfish_main');
  late final _stockfish_main = _stockfish_mainPtr.asFunction<int Function()>();

  /// Writing to Stockfish STDIN.
  int stockfish_stdin_write(
    ffi.Pointer<ffi.Char> data,
  ) {
    return _stockfish_stdin_write(
      data,
    );
  }

  late final _stockfish_stdin_writePtr =
      _lookup<ffi.NativeFunction<ssize_t Function(ffi.Pointer<ffi.Char>)>>(
          'stockfish_stdin_write');
  late final _stockfish_stdin_write = _stockfish_stdin_writePtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  /// Reading Stockfish STDOUT.
  ffi.Pointer<ffi.Char> stockfish_stdout_read() {
    return _stockfish_stdout_read();
  }

  late final _stockfish_stdout_readPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'stockfish_stdout_read');
  late final _stockfish_stdout_read =
      _stockfish_stdout_readPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  /// Reading Stockfish STDERR.
  ffi.Pointer<ffi.Char> stockfish_stderr_read() {
    return _stockfish_stderr_read();
  }

  late final _stockfish_stderr_readPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'stockfish_stderr_read');
  late final _stockfish_stderr_read =
      _stockfish_stderr_readPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();
}

typedef ssize_t = __ssize_t;
typedef __ssize_t = ffi.Long;
typedef Dart__ssize_t = int;
