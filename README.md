# stockfish_chess_engine

Use Stockfish chess engine in your Flutter project.

This project is based on sources for Stockfish 16.

## Usage

```dart
final stockfish = new Stockfish()

// Create a subscribtion on stdout : subscription that you'll have to cancel before disposing Stockfish.
final stockfishSubscription = stockfish.stdout.listen((message) {
    print(message);
});

// Create a subscribtion on stderr : subscription that you'll have to cancel before disposing Stockfish.
final stockfishErrorsSubscription = stockfish.stderr.listen((message) {
    print(message);
});

// Get Stockfish ready
stockfish.stdin = 'isready'

// Send you commands to Stockfish stdin
stockfish.stdin = 'position startpos' // set up start position
stockfish.stdin = 'position fen rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2' // set up custom position
stockfish.stdin = 'go movetime 1500' // search move for at most 1500ms

// Don't remember to dispose Stockfish when you're done.
stockfishErrorsSubscription.cancel();
stockfishSubscription.cancel();
stockfish.dispose();
```

You can see an example usage in example folder.

## Important notes

- You **must** check the position validity before sending it to stdin, otherwise program will crash on illegal position ! For that, you can use the [chess](https://pub.dev/packages/chess) package.

- As the library creates two isolates, you must dispose Stockfish before perfoming an hot reload / hot restart, and then creating a new Stockfish instance.

- If testing on IPhone simulator, consider disabling Impeller if the program fails to show UI : `flutter run --no-enable-impeller`

## For stockfish chess engine developpers

1. Adjust the path of "llvm-path" in file **ffigen.yaml** (linux users)
2. Run `flutter pub get`.
3. Uncomment line `#define _ffigen` on top of src/stockfish.h (for the ffi generation to pass).
4. Run command `dart run ffigen --config ffigen.yaml`.
   More on https://pub.dev/packages/ffigen for the prerequesites per OS.
5. Comment line `#define _ffigen` in src/stockfish.h (otherwise Stockfish engine compilation will pass but be incorrect).

### Changing Stockfish source files

If you need to upgrade Stockfish source files, create a folder **Stockfish** inside **src** folder, copy the **src** folder from the stockfish sources into the new **Stockfish** folder (and also replace the readme file for Stockfish).

Also you need to make some more adaptive works :

#### Adapting streams

- replace all calls to `cout << #SomeContent# << endl` by `fakeout << #SomeContent# << fakeendl` (without the std:: prefix if any) (And ajust also calls to `cout.rdbuf()` by `fakeout.rdbuf()`) **But do not replace calls to sync_cout** add include to **../../fixes/fixes.h** in all related files (and adjust the include path accordingly). Do the same for calls to `cout.#method#`. Don't forget to replace calls to `endl` (with or without std:: prefix) : once more just `endl`not `sync_endl`
- proceed accordingly for `cin` : replace by `fakein`
- and the same for `cerr`: replace by `fakeerr`
- in **misc.h** replace

```cpp
#define sync_cout std::cout << IO_LOCK
#define sync_endl std::endl << IO_UNLOCK
```

with

```cpp
#define sync_cout fakeout << IO_LOCK
#define sync_endl fakeendl << IO_UNLOCK
```

and include **../../fixes/fixes.h** (if not already done)

#### Adding main.h source file

Add the file **src/Stockfish/src/main.h** with the following content :
```cpp
#ifndef __MAIN_H__
#define __MAIN_H__

int main(int argc, char* argv[]);

#endif // __MAIN_H__
```

and replace **main.cpp** so that it includes this new file.

#### Copying code for ios and mac

Then, copy **src/Stockfish** folder to
- folder ios/Classes
- folder macos/Classes

#### Adapting the NNUE names

1. Copy the big and small nnue names from **src/Stockfish/src/evaluate.h**
2. Replace their names in file **src/CMakeLists.txt**
3. Also replace their names in file **ios/stockfish_chess_engine.podspec** and **macos/stockfish_chess_engine.podspec**

### Changing the downloaded NNUE file

1. Go to [Stockfish NNUE files page](https://tests.stockfishchess.org/nns) and select a reference from the list.
2. Modify CMakeLists.txt, by replacing lines starting by `set (NNUE_NAME )` by setting your reference name, without any quote.
3. Modify the reference name in `evaluate.h` in the line containing `#define EvalFileDefaultName   `, by setting your nnue file name, with the quotes of course.
4. Don't forget to clean project before building again (`flutter clean` then `flutter pub get`).

## Credits

- Using source code from [Stockfish](https://stockfishchess.org).
- Using source code from [Flutter Stockfish](https://github.com/ArjanAswal/Stockfish).
- Using source code from [Flutter Stockfish Plugin](https://github.com/jusax23/flutter_stockfish_plugin)
