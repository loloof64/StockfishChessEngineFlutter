import 'dart:async';
import 'dart:io';

import 'package:editable_chess_board/editable_chess_board.dart';
import 'package:window_manager/window_manager.dart';
import './edit_position_page.dart';
import './fen_validation.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simple_chess_board/widgets/chessboard.dart';

import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';
import 'package:stockfish_chess_engine/stockfish_chess_engine_state.dart';

void main() {
  if (Platform.isAndroid || Platform.isIOS) {
    runApp(MaterialApp(
      home: MobileApp(),
    ));
  } else {
    WidgetsFlutterBinding.ensureInitialized();
    windowManager.ensureInitialized().then((_) {
      runApp(MaterialApp(
        home: DesktopApp(),
      ));
    });
  }
}

class MobileApp extends StatefulWidget {
  const MobileApp({super.key});

  @override
  MobileAppState createState() => MobileAppState();
}

class MobileAppState extends State<MobileApp> with WidgetsBindingObserver {
  late Stockfish _stockfish;
  String _fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  late StreamSubscription _stockfishOutputSubsciption;
  late StreamSubscription _stockfishErrorSubsciption;
  var _timeMs = 1000.0;
  var _nextMove = '';
  var _stockfishOutputText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _doStartStockfish();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startStockfishIfNecessary();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopStockfish().then((_) {});
    }
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
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!context.mounted) return;
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
    if (_stockfish.state.value == StockfishState.ready ||
        _stockfish.state.value == StockfishState.starting) {
      return;
    }
    setState(() {
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

class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key});

  @override
  DesktopAppState createState() => DesktopAppState();
}

class DesktopAppState extends State<DesktopApp>
    with WidgetsBindingObserver, WindowListener {
  late Stockfish _stockfish;
  String _fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  late StreamSubscription _stockfishOutputSubsciption;
  late StreamSubscription _stockfishErrorSubsciption;
  var _timeMs = 1000.0;
  var _nextMove = '';
  var _stockfishOutputText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WindowManager.instance.addListener(this);
    _doStartStockfish();
  }

  @override
  void dispose() {
    WindowManager.instance.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startStockfishIfNecessary();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopStockfish().then((_) {});
    }
  }

  @override
  void onWindowClose() {
    _stopStockfish().then((_) {});
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
    await Future.delayed(const Duration(milliseconds: 100));
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
    if (_stockfish.state.value == StockfishState.ready ||
        _stockfish.state.value == StockfishState.starting) {
      return;
    }
    setState(() {
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
