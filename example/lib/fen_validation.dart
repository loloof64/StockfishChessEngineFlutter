import 'package:chess/chess.dart';

bool isStrictlyValidFEN(String fen) {
  Chess chess;
  chess = Chess();
  if (!chess.load(fen)) return false;

  final board = chess.fen.split(' ')[0];

  Map<String, int> pieceCounts = {
    'P': 'P'.allMatches(board).length,
    'N': 'N'.allMatches(board).length,
    'B': 'B'.allMatches(board).length,
    'R': 'R'.allMatches(board).length,
    'Q': 'Q'.allMatches(board).length,
    'K': 'K'.allMatches(board).length,
    'p': 'p'.allMatches(board).length,
    'n': 'n'.allMatches(board).length,
    'b': 'b'.allMatches(board).length,
    'r': 'r'.allMatches(board).length,
    'q': 'q'.allMatches(board).length,
    'k': 'k'.allMatches(board).length,
  };

  Map<String, int> pieceLimits = {
    'P': 8,
    'N': 10,
    'B': 10,
    'R': 10,
    'Q': 9,
    'K': 1,
    'p': 8,
    'n': 10,
    'b': 10,
    'r': 10,
    'q': 9,
    'k': 1,
  };

  for (String piece in pieceCounts.keys) {
    if (pieceCounts[piece]! > pieceLimits[piece]!) {
      return false;
    }
  }

  return true;
}
