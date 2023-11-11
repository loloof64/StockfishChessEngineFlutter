// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// Bindings for `src/stockfish.h`.
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

  int stockfish_main() {
    return _stockfish_main();
  }

  late final _stockfish_mainPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('stockfish_main');
  late final _stockfish_main = _stockfish_mainPtr.asFunction<int Function()>();

  void stockfish_stdin_write(
    ffi.Pointer<Utf8> data,
  ) {
    return _stockfish_stdin_write(
      data,
    );
  }

  late final _stockfish_stdin_writePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<Utf8>)>>(
          'stockfish_stdin_write');
  late final _stockfish_stdin_write = _stockfish_stdin_writePtr
      .asFunction<void Function(ffi.Pointer<Utf8>)>();

  ffi.Pointer<Utf8> stockfish_stdout_read() {
    return _stockfish_stdout_read();
  }

  late final _stockfish_stdout_readPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<Utf8> Function()>>(
          'stockfish_stdout_read');
  late final _stockfish_stdout_read =
      _stockfish_stdout_readPtr.asFunction<ffi.Pointer<Utf8> Function()>();
}
