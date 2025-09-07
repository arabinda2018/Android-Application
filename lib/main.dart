import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const BallBounceGame());
}

/// Root widget for the game
class BallBounceGame extends StatelessWidget {
  const BallBounceGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Ball properties
  double ballX = 0;
  double ballY = 0;
  double ballSize = 30;

  // Ball speed
  double dx = 0.02;
  double dy = 0.025;

  // Paddle
  double paddleX = 0;
  double paddleWidth = 120;
  double paddleHeight = 20;

  // Game state
  Timer? timer;
  bool isGameRunning = false;
  bool isPaused = false;

  // Score
  int score = 0;
  int highScore = 0; // 🎯 save old record

  @override
  void initState() {
    super.initState();
    _loadHighScore(); // load saved record
  }

  /// Load high score from storage
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt("highScore") ?? 0;
    });
  }

  /// Save high score to storage
  Future<void> _saveHighScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("highScore", newScore);
  }

  /// Start the game
  void startGame() {
    isGameRunning = true;
    isPaused = false;
    score = 0;

    dx = 0.02;
    dy = 0.025;

    timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!isPaused) {
        setState(() {
          // Move ball
          ballX += dx;
          ballY += dy;

          // Walls
          if (ballX <= -1 || ballX >= 1) dx = -dx;
          if (ballY <= -1) dy = -dy;

          // Paddle collision
          if (ballY >= 0.9 &&
              ballX >= paddleX - paddleWidth / 200 &&
              ballX <= paddleX + paddleWidth / 200) {
            dy = -dy;
            score++;

            if (score % 5 == 0) {
              dx *= 1.1;
              dy *= 1.1;
            }
          }

          // Game Over
          if (ballY > 1) {
            timer.cancel();
            isGameRunning = false;

            if (score > highScore) {
              highScore = score;
              _saveHighScore(score); // Save new record
            }

            _showGameOver();
          }
        });
      }
    });
  }

  void _showGameOver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Game Over!"),
        content: Text("Your score: $score\nBest: $highScore"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: const Text("Restart"),
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

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragUpdate: movePaddle,
        child: Stack(
          children: [
            // Ball
            Align(
              alignment: Alignment(ballX, ballY),
              child: Container(
                width: ballSize,
                height: ballSize,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Paddle
            Align(
              alignment: Alignment(paddleX, 0.95),
              child: Container(
                width: paddleWidth,
                height: paddleHeight,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Current Score
            Align(
              alignment: const Alignment(0, -0.95),
              child: Text(
                "Score: $score | Best: $highScore",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Play / Pause
            Align(
              alignment: const Alignment(0.9, -0.9),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {
                  if (!isGameRunning) {
                    startGame();
                  } else {
                    togglePause();
                  }
                },
                child: Icon(
                  !isGameRunning
                      ? Icons.play_arrow
                      : isPaused
                          ? Icons.play_arrow
                          : Icons.pause,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
