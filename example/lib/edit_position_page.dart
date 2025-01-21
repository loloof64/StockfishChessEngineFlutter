import 'package:editable_chess_board/editable_chess_board.dart';
import 'package:flutter/material.dart';

class EditPositionPage extends StatelessWidget {
  final PositionController positionController;
  const EditPositionPage({
    super.key,
    required this.positionController,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit position"),
      ),
      body: Column(
        children: [
          Expanded(
            child: EditableChessBoard(
              boardSize: isLandscape
                  ? deviceSize.height * 0.45
                  : deviceSize.width * 0.4,
              labels: Labels(
                playerTurnLabel: 'Turn',
                whitePlayerLabel: 'white',
                blackPlayerLabel: 'black',
                availableCastlesLabel: 'castles',
                whiteOOLabel: 'white OO',
                whiteOOOLabel: 'white OOO',
                blackOOLabel: 'black OO',
                blackOOOLabel: 'black OOO',
                enPassantLabel: 'en-passant square',
                drawHalfMovesCountLabel: 'draw half moves count',
                moveNumberLabel: 'move number',
                submitFieldLabel: 'submit',
                currentPositionLabel: 'current position',
                copyFenLabel: 'copy position',
                pasteFenLabel: 'paste position',
                resetPosition: 'reset position',
                standardPosition: 'standard position',
                erasePosition: 'erase position',
              ),
              controller: positionController,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(positionController.position);
            },
            child: Text('Validate position'),
          )
        ],
      ),
    );
  }
}
