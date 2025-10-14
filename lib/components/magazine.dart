/// A class to represent a magazine with a specific capacity and round count.
class Magazine {
  final int capacity;
  int currentRounds;

  Magazine({required this.capacity, this.currentRounds = 0});

  bool get isEmpty => currentRounds <= 0;
  bool get isFull => currentRounds >= capacity;
}