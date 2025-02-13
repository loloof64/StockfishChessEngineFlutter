## 0.8.1

- Bug fix : we can stop and restart Stockfish. (Also useful for Flutter applications live reload)
- Removed the use of WindowManager on mobile targets.

## 0.8.0

- Only download and work with the small NNUE on mobile devices (Android/IPhone)

## 0.7.1

- Fix for Windows : the plugin did not compile

## 0.7.0

- Adding code for MacOs and IOS (have not been tested)
- Using Stockfish 17 source code
- Adding Stockfish error stream
- Proper handling of Stockfish I/O in native code
- Proper disposal of Stockfish isolates

## 0.6.0

- Bug fix for windows (only tested on Windows 11) : the library had the wrong path for the built dll.

## 0.5.0

- get build updated so that the code compiles fine
- bump ndk version
- use java 17 instead of java 8
- add namespace in build.gradle

## 0.4.1

- Upgraded some dependencies versions

## 0.4.0

- We don't encounter issue when using a logger and this package.

## 0.3.2

- Update Readme file with an advice to use chess package along with this package.

## 0.3.0

- Bug fix : the plugin did not load correctly on Windows.

## 0.2.0

- Bug fix : the plugin did not load correctly on Linux.

## 0.1.2

- Updates for static analysis on the server

## 0.1.0

- Initial release
