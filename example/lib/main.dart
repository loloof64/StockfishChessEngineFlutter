import 'package:flutter/material.dart';

import 'package:stockfish_chess_engine/stockfish_chess_engine.dart'
    as stockfish_chess_engine;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: null,
    );
  }
}
