# stockfish_chess_engine

Use Stockfish chess engine in your Flutter project.

This project is based on sources for Stockfish 16.

Note : I apologize for not releasing for IOS nor Mac, because I can't test on those machines.
I'm open to pull request if someone can help me.

## Usage

```dart
final stockfish = new Stockfish()

// Create a subscribtion on stdout : subscription that you'll have to cancel before disposing Stockfish.
final stockfishSubscription = stockfish.stdout.listen((message) {
    print(message);
});

// Get Stockfish ready
stockfish.stdin = 'isready'

// Send you commands to Stockfish stdin
stockfish.stdin = 'position startpos' // set up start position
stockfish.stdin = 'position fen rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2' // set up custom position
stockfish.stdin = 'go movetime 1500' // search move for at most 1500ms

// Don't remember to dispose Stockfish when you're done.
stockfishSubscription.cancel();
stockfish.dispose();
```

You can see an example usage in example folder.

## Important notes

* You **must** check the position validity before sending it to stdin, otherwise program will crash on illegal position ! For that, you can use the [chess](https://pub.dev/packages/chess) package.

* As the library creates two isolates, you must dispose Stockfish before perfoming an hot reload / hot restart, and then creating a new Stockfish instance.

## For stockfish chess engine developpers

1. Run `flutter pub get`.
2. Uncomment line `#define _ffigen` on top of src/stockfish.h (for the ffi generation to pass).
3. Run command `flutter pub run ffigen --config ffigen.yaml`.
More on https://pub.dev/packages/ffigen for the prerequesites per OS.
4. Comment line `#define _ffigen` in src/stockfish.h (otherwise Stockfish engine compilation will pass but be incorrect).
5. In the file lib/stockfish_bindings_generated.dart, add the following import line : `import 'package:ffi/ffi.dart';`
6. In the same file, replace Pointer<ffi.Char> by Pointer<Utf8>

### Changing the downloaded NNUE file

1. Go to [Stockfish NNUE files page](https://tests.stockfishchess.org/nns) and select a reference from the list.
2. Modify CMakeLists.txt, by replacing lines starting by `set (NNUE_NAME )` by setting your reference name, without any quote.
3. Modify the reference name in `evaluate.h` in the line containing `#define EvalFileDefaultName   `, by setting your nnue file name, with the quotes of course.
4. Don't forget to clean project before building again (`flutter clean` then `flutter pub get`).

## Credits

* Using source code from [Stockfish](https://stockfishchess.org).
* Using source code from [Flutter Stockfish](https://github.com/ArjanAswal/Stockfish).
* Using source code from [Flutter Stockfish Plugin](https://github.com/jusax23/flutter_stockfish_plugin)