import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:stockfish/stockfish.dart';

void main() {
  runApp(const MyApp());
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
    Logger().i(output);
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

  void _computeNextMove() {
    _stockfish.stdin = 'position fen ${_fenController.text}';
    _stockfish.stdin = 'go movetime ${_timeMs.toInt()}';
  }

  void _resetStockfishInstance() async {
    _stockfishOutputSubsciption.cancel();
    _stockfish.stdin = 'quit';
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _stockfish = Stockfish();
      _stockfishOutputSubsciption =
          _stockfish.stdout.listen(_readStockfishOutput);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
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
          ElevatedButton(
            onPressed: _computeNextMove,
            child: const Text('Search next move'),
          ),
          Text('Best move: $_nextMove'),
          ElevatedButton(
            onPressed: _resetStockfishInstance,
            child: const Text('Reset Stockfish instance'),
          ),
        ],
      ),
    );
  }
}
