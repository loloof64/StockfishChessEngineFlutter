import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:chess/chess.dart' as chess_lib;

import 'package:stockfish/stockfish.dart';
import 'package:stockfish/stockfish_state.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late Stockfish _stockfish;
  final _fenController = TextEditingController();
  late StreamSubscription _stockfishOutputSubsciption;
  var _timeMs = 1000.0;
  var _nextMove = '';

  @override
  void initState() {
    _stockfish = Stockfish();
    _stockfishOutputSubsciption =
        _stockfish.stdout.listen(_readStockfishOutput);
    super.initState();
  }

  @override
  void dispose() {
    _stockfishOutputSubsciption.cancel();
    super.dispose();
  }

  void _readStockfishOutput(String output) {
    debugPrint(output);
    // At least now, stockfish is ready : update UI.
    setState(() {});
    if (output.startsWith('bestmove')) {
      final parts = output.split(' ');
      setState(() {
        _nextMove = parts[1];
      });
    }
  }

  void _pasteFen() {
    FlutterClipboard.paste().then((value) {
      // Do what ever you want with the value.
      setState(() {
        _fenController.text = value;
      });
    });
  }

  void _updateThinkingTime(double newValue) {
    setState(() {
      _timeMs = newValue;
    });
  }

  // Checks that chess.js don't process
  bool _checkPositionKingsAndPawnsValidity() {
    final fen = _fenController.text;

    final boardPart = fen.split(' ')[0];

    /* Is white and black kings' count legal ? */
    final whiteKingCount =
        boardPart.split('').where((elem) => elem == 'K').length;
    final blackKingCount =
        boardPart.split('').where((elem) => elem == 'k').length;

    if (whiteKingCount != 1 || blackKingCount != 1) {
      return false;
    }

    /* Are both kings on neighbours cells ? */
    // Computes a kind of 'expanded' FEN : cells are translated as underscores,
    //  and removing all slashes.
    final expandedFen = boardPart.split('').fold<String>('', (accum, curr) {
      final digitValue = int.tryParse(curr);
      if (curr == '/') {
        return accum;
      } else if (digitValue != null) {
        var result = '';
        for (var i = 0; i < digitValue; i++) {
          result += '_';
        }
        return accum + result;
      } else {
        return accum + curr;
      }
    });
    final whiteKingIndex = expandedFen.indexOf('K');
    final blackKingIndex = expandedFen.indexOf('k');
    final whiteKingCoords = [whiteKingIndex % 8, whiteKingIndex ~/ 8];
    final blackKingCoords = [blackKingIndex % 8, blackKingIndex ~/ 8];

    final deltaX = (whiteKingCoords[0] - blackKingCoords[0]).abs();
    final deltaY = (whiteKingCoords[1] - blackKingCoords[1]).abs();

    final kingsTooClose = (deltaX <= 1) && (deltaY <= 1);
    if (kingsTooClose) {
      return false;
    }

    /* Any pawn on first or last rank ? */
    final firstRank = boardPart.split('/')[0];
    final lastRank = boardPart.split('/')[7];

    final whitePawnOnFirstRank = firstRank.contains('P');
    final blackPawnOnFirstRank = firstRank.contains('p');
    final whitePawnOnLastRank = lastRank.contains('P');
    final blackPawnOnLastRank = lastRank.contains('p');

    if (whitePawnOnFirstRank ||
        whitePawnOnLastRank ||
        blackPawnOnFirstRank ||
        blackPawnOnLastRank) {
      return false;
    }

    return true;
  }

  bool _validPosition() {
    if (!_checkPositionKingsAndPawnsValidity()) return false;
    final chess = chess_lib.Chess();
    return chess.load(_fenController.text);
  }

  void _computeNextMove() {
    if (!_validPosition()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Illegal position: ${_fenController.text} !'),
        ),
      );
      return;
    }
    _stockfish.stdin = 'position fen ${_fenController.text}';
    _stockfish.stdin = 'go movetime ${_timeMs.toInt()}';
  }

  void _stopStockfish() async {
    if (_stockfish.state.value == StockfishState.disposed ||
        _stockfish.state.value == StockfishState.error) {
      return;
    }
    _stockfishOutputSubsciption.cancel();
    _stockfish.stdin = 'quit';
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {});
  }

  void _doStartStockfish() async {
    _stockfish = Stockfish();
    _stockfishOutputSubsciption =
        _stockfish.stdout.listen(_readStockfishOutput);
    await Future.delayed(const Duration(milliseconds: 1100));
    _stockfish.stdin = 'isready';
  }

  void _startStockfishIfNecessary() {
    setState(() {
      if (_stockfish.state.value == StockfishState.ready ||
          _stockfish.state.value == StockfishState.starting) {
        return;
      }
      _doStartStockfish();
    });
  }

  Icon _getStockfishStatusIcon() {
    Color color;
    switch (_stockfish.state.value) {
      case StockfishState.ready:
        color = Colors.green;
        break;
      case StockfishState.disposed:
      case StockfishState.error:
        color = Colors.red;
        break;
      case StockfishState.starting:
        color = Colors.orange;
    }
    return Icon(MdiIcons.circle, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stockfish Chess Engine example"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _fenController,
                decoration: const InputDecoration(
                  hintText: 'Position FEN value',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: _pasteFen,
                child: const Text('Coller FEN'),
              ),
              Slider(
                value: _timeMs,
                onChanged: _updateThinkingTime,
                min: 500,
                max: 3000,
              ),
              Text('Thinking time : ${_timeMs.toInt()} millis'),
              ElevatedButton(
                onPressed: _computeNextMove,
                child: const Text('Search next move'),
              ),
              Text('Best move: $_nextMove'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _getStockfishStatusIcon(),
                  ElevatedButton(
                    onPressed: _startStockfishIfNecessary,
                    child: const Text('Start Stockfish'),
                  ),
                  ElevatedButton(
                    onPressed: _stopStockfish,
                    child: const Text('Stop Stockfish'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
