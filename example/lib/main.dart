import 'dart:async';

import 'package:editable_chess_board/editable_chess_board.dart';
import './edit_position_page.dart';
import './fen_validation.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simple_chess_board/widgets/chessboard.dart';
import 'package:window_manager/window_manager.dart';

import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';
import 'package:stockfish_chess_engine/stockfish_chess_engine_state.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WindowListener {
  late Stockfish _stockfish;
  String _fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  late StreamSubscription _stockfishOutputSubsciption;
  late StreamSubscription _stockfishErrorSubsciption;
  var _timeMs = 1000.0;
  var _nextMove = '';
  var _stockfishOutputText = '';

  @override
  void initState() {
    windowManager.addListener(this);
    _doStartStockfish();
    super.initState();
    windowManager.setPreventClose(true).then((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _stopStockfish();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await _stopStockfish();
    await windowManager.close();
  }

  void _readStockfishOutput(String output) {
    // At least now, stockfish is ready : update UI.
    setState(() {
      _stockfishOutputText += "$output\n";
    });
    if (output.startsWith('bestmove')) {
      final parts = output.split(' ');
      setState(() {
        _nextMove = parts[1];
      });
    }
  }

  void _readStockfishError(String error) {
    // At least now, stockfish is ready : update UI.
    setState(() {
      debugPrint("@@@$error@@@");
    });
  }

  void _editPosition(BuildContext context) async {
    final initialFen = isStrictlyValidFEN(_fen)
        ? _fen
        : 'RNBQKBNR/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    final controller = PositionController(initialFen);
    final resultFen = await Navigator.of(context)
        .push(MaterialPageRoute<String>(builder: (context) {
      return EditPositionPage(
        positionController: controller,
      );
    }));
    if (resultFen != null) {
      setState(() {
        _fen = resultFen;
      });
      if (!isStrictlyValidFEN(_fen)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Illegal position : so no changes made !'),
          backgroundColor: Colors.red,
        ));
        setState(() {
          _fen = initialFen;
        });
      }
    }
  }

  void _updateThinkingTime(double newValue) {
    setState(() {
      _timeMs = newValue;
    });
  }

  void _computeNextMove() {
    if (!isStrictlyValidFEN(_fen)) {
      final message = "Illegal position: '$_fen' !\n";
      setState(() {
        _stockfishOutputText = message;
      });
      return;
    }
    setState(() {
      _stockfishOutputText = '';
    });
    _stockfish.stdin = 'position fen $_fen';
    _stockfish.stdin = 'go movetime ${_timeMs.toInt()}';
  }

  Future<void> _stopStockfish() async {
    if (_stockfish.state.value == StockfishState.disposed ||
        _stockfish.state.value == StockfishState.error) {
      return;
    }
    _stockfishErrorSubsciption.cancel();
    _stockfishOutputSubsciption.cancel();
    _stockfish.dispose();
    await Future.delayed(const Duration(seconds: 2));
    setState(() {});
  }

  void _doStartStockfish() async {
    _stockfish = Stockfish();
    _stockfishOutputSubsciption =
        _stockfish.stdout.listen(_readStockfishOutput);
    setState(() {
      _stockfishOutputText = '';
    });
    _stockfishErrorSubsciption = _stockfish.stderr.listen(_readStockfishError);
    await Future.delayed(const Duration(milliseconds: 1500));
    _stockfish.stdin = 'uci';
    await Future.delayed(const Duration(milliseconds: 3000));
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
              SizedBox(
                width: 130,
                height: 130,
                child: SimpleChessBoard(
                  engineThinking: false,
                  fen: _fen,
                  whitePlayerType: PlayerType.computer,
                  blackPlayerType: PlayerType.computer,
                  blackSideAtBottom: false,
                  cellHighlights: {},
                  chessBoardColors: ChessBoardColors(),
                  onMove: ({required move}) => {},
                  onPromote: () => Future.value(null),
                  onPromotionCommited:
                      ({required moveDone, required pieceType}) => {},
                  onTap: ({required cellCoordinate}) => {},
                ),
              ),
              ElevatedButton(
                onPressed: () => _editPosition(context),
                child: const Text('Edit position'),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 850.0,
                  height: 300.0,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2.0,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _stockfishOutputText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
