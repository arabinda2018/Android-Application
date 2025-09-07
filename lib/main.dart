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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              },
              child: const Text("Start Game", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- GAME SCREEN --------------------
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

  // Ball movement speed
  double dx = 0.02;
  double dy = 0.025;

  // Paddle properties
  double paddleX = 0;
  double paddleWidth = 120;
  double paddleHeight = 20;

  // Game state
  Timer? timer;
  bool isGameRunning = false;

  // Score
  int score = 0;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    startGame(); // Start the game once when screen opens
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

  /// Start or restart the game
  void startGame() {
    isGameRunning = true;
    score = 0;

    // Reset positions
    ballX = 0;
    ballY = 0;
    paddleX = 0;

    // Randomize initial direction
    dx = Random().nextBool() ? 0.02 : -0.02;
    dy = -0.025;

    timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!isGameRunning) return; // Stop updating if game over

      setState(() {
        // Move ball
        ballX += dx;
        ballY += dy;

        // Bounce off left/right walls
        if (ballX <= -1 || ballX >= 1) dx = -dx;

        // Bounce off top wall
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

        // Game over if ball falls below paddle
        if (ballY > 1) {
          timer.cancel();
          isGameRunning = false;

          // Save high score
          if (score > highScore) {
            highScore = score;
            _saveHighScore(score);
          }

          _showGameOver();
        }
      });
    });
  }

  /// Game Over dialog with Restart & Exit
  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Center(
          child: Text(
            "🎮 Game Over!",
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your Score: $score",
                style: const TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 10),
            Text("Best Score: $highScore",
                style: const TextStyle(color: Colors.greenAccent, fontSize: 20)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: const Text("Restart"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Back to Start screen
            },
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

            // Score display
            Align(
              alignment: const Alignment(0, -0.95),
              child: Text(
                "Score: $score | Best: $highScore",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
