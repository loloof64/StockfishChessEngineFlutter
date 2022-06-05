# stockfish_chess_engine

Use Stockfish chess engine in your Flutter project.

This project is based on sources for Stockfish 15.


## For developpers

Don't forget to run command `dart run ffigen --config ffigen.yaml`.
More on https://pub.dev/packages/ffigen.

Then, in the generated file:
* add import to 'package:ffi/ffi.dart'
* replace occurrences of `ffi.Char` with `Utf8`.

## Credits

* Using source code from [Stockfish](https://stockfishchess.org).
* Using source code from [Flutter Stockfish](https://github.com/ArjanAswal/Stockfish).