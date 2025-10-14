import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  void _onGameOver() {
    // When the game is over, navigate back to the home screen.
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The GameWidget is the widget that runs the Flame game.
      body: GameWidget(game: MyGame(onGameOver: _onGameOver)),
    );
  }
}