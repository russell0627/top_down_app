import 'package:flutter/material.dart';
import '../components/magazine.dart';
import '../game.dart';

/// A Flutter widget that renders as an overlay on top of the game.
/// It displays the player's inventory, including magazines and loose ammo.
class InventoryOverlay extends StatelessWidget {
  final MyGame game;
  const InventoryOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final player = game.player;

    return Material(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Inventory',
                style: TextStyle(fontSize: 32, color: Colors.white),
              ),
              const SizedBox(height: 20),
              _buildMagazineInfo('Loaded', player.currentMagazine),
              const SizedBox(height: 20),
              const Text(
                'Spare Magazines',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              ...player.magazines
                  .map((mag) => _buildMagazineInfo('Spare', mag)),
              const SizedBox(height: 20),
              Text(
                'Loose Rounds: ${player.looseRounds}',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 40),
              const Text(
                "Press 'Q' to close",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagazineInfo(String label, Magazine? mag) {
    if (mag == null) {
      return Text(
        '$label: None',
        style: const TextStyle(fontSize: 18, color: Colors.white),
      );
    }
    return Text(
      '$label: ${mag.currentRounds} / ${mag.capacity}',
      style: const TextStyle(fontSize: 18, color: Colors.white),
    );
  }
}