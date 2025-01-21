// Taken from https://github.com/ArjanAswal/Stockfish/blob/master/lib/src/stockfish_state.dart

/// C++ engine state.
enum StockfishState {
  /// Engine has been stopped.
  disposed,

  /// An error occured (engine could not start).
  error,

  /// Engine is running.
  ready,

  /// Engine is starting.
  starting,
}
