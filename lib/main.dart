import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      // Define the initial route and the route map.
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/play': (context) => const GameScreen(),
      },
    ),
  );
}
