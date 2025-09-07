import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BallBounceGame());
}

/// Root widget
class BallBounceGame extends StatelessWidget {
  const BallBounceGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StartScreen(),
    );
  }
}

/// -------------------- START SCREEN --------------------
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Ball Bounce Game",
              style: TextStyle(
                fontSize: 32,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DifficultyScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Start Game", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- DIFFICULTY SELECTION --------------------
class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select Difficulty",
              style: TextStyle(
                fontSize: 28,
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            DifficultyButton(level: "Basic", dx: 0.02, dy: 0.025, paddleWidth: 120, speedFactor: 1.05),
            DifficultyButton(level: "Intermediate", dx: 0.03, dy: 0.035, paddleWidth: 100, speedFactor: 1.08),
            DifficultyButton(level: "Expert", dx: 0.04, dy: 0.045, paddleWidth: 80, speedFactor: 1.12),
          ],
        ),
      ),
    );
  }
}

class DifficultyButton extends StatelessWidget {
  final String level;
  final double dx, dy;
  final double paddleWidth;
  final double speedFactor;

  const DifficultyButton({
    super.key,
    required this.level,
    required this.dx,
    required this.dy,
    required this.paddleWidth,
    required this.speedFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(
                initialDx: dx,
                initialDy: dy,
                paddleWidth: paddleWidth,
                speedFactor: speedFactor,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(level, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

/// -------------------- GAME SCREEN --------------------
class GameScreen extends StatefulWidget {
  final double initialDx;
  final double initialDy;
  final double paddleWidth;
  final double speedFactor;

  const GameScreen({
    super.key,
    required this.initialDx,
    required this.initialDy,
    required this.paddleWidth,
    required this.speedFactor,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Ball properties
  double ballX = 0;
  double ballY = 0;
  double ballSize = 30;

  // Ball movement speed
  late double dx;
  late double dy;

  // Paddle properties
  double paddleX = 0;
  late double paddleWidth;
  double paddleHeight = 20;

  // Game state
  Timer? timer;
  bool isGameRunning = false;

  // Score
  int score = 0;
  int highScore = 0;

  late double speedFactor;

  @override
  void initState() {
    super.initState();
    dx = widget.initialDx;
    dy = widget.initialDy;
    paddleWidth = widget.paddleWidth;
    speedFactor = widget.speedFactor;

    _loadHighScore();
    startGame();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt("highScore") ?? 0;
    });
  }

  Future<void> _saveHighScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("highScore", newScore);
  }

  void startGame() {
    isGameRunning = true;
    score = 0;
    ballX = 0;
    ballY = 0;
    paddleX = 0;
    dx = widget.initialDx * (Random().nextBool() ? 1 : -1);
    dy = -widget.initialDy;

    timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!isGameRunning) return;

      setState(() {
        ballX += dx;
        ballY += dy;

        if (ballX <= -1 || ballX >= 1) dx = -dx;
        if (ballY <= -1) dy = -dy;

        // Paddle collision
        if (ballY >= 0.9 &&
            ballX >= paddleX - paddleWidth / 200 &&
            ballX <= paddleX + paddleWidth / 200) {
          dy = -dy;
          score++;
          dx *= speedFactor;
          dy *= speedFactor;
        }

        if (ballY > 1) {
          timer.cancel();
          isGameRunning = false;

          if (score > highScore) {
            highScore = score;
            _saveHighScore(score);
          }

          _showGameOver();
        }
      });
    });
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Center(
          child: Text("🎮 Game Over!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your Score: $score", style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 10),
            Text("Best Score: $highScore", style: const TextStyle(color: Colors.greenAccent, fontSize: 20)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Restart"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // back to StartScreen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      ballX = 0;
      ballY = 0;
      paddleX = 0;
      score = 0;
      isGameRunning = true;
      dx = widget.initialDx;
      dy = -widget.initialDy;
    });
    startGame();
  }

  void movePaddle(DragUpdateDetails details) {
    setState(() {
      paddleX += (details.delta.dx * 2) / (MediaQuery.of(context).size.width);
      if (paddleX < -1) paddleX = -1;
      if (paddleX > 1) paddleX = 1;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragUpdate: movePaddle,
        child: Stack(
          children: [
            Align(
              alignment: Alignment(ballX, ballY),
              child: Container(
                width: ballSize,
                height: ballSize,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            ),
            Align(
              alignment: Alignment(paddleX, 0.95),
              child: Container(
                width: paddleWidth,
                height: paddleHeight,
                decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.95),
              child: Text("Score: $score | Best: $highScore",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
