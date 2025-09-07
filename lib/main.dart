import 'dart:async';
import 'package:flutter/material.dart';

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

/// The main game screen
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Ball properties
  double ballX = 0; // X position (-1 to 1)
  double ballY = 0; // Y position (-1 to 1)
  double ballSize = 30;

  // Ball movement speed
  double dx = 0.02;
  double dy = 0.025;

  // Paddle properties
  double paddleX = 0; // X position of paddle (-1 to 1)
  double paddleWidth = 120;
  double paddleHeight = 20;

  // Game state
  Timer? timer;
  bool isGameRunning = false;
  bool isPaused = false;

  // Score
  int score = 0;

  /// Starts or restarts the game
  void startGame() {
    isGameRunning = true;
    isPaused = false;
    score = 0;

    // Reset ball speed
    dx = 0.02;
    dy = 0.025;

    // Start a timer that updates the game every 16ms (~60fps)
    timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!isPaused) {
        setState(() {
          // Move the ball
          ballX += dx;
          ballY += dy;

          // Bounce off left/right walls
          if (ballX <= -1 || ballX >= 1) {
            dx = -dx;
          }

          // Bounce off the top wall
          if (ballY <= -1) {
            dy = -dy;
          }

          // Paddle collision
          if (ballY >= 0.9 &&
              ballX >= paddleX - paddleWidth / 200 &&
              ballX <= paddleX + paddleWidth / 200) {
            dy = -dy; // Bounce upward
            score++; // Increase score

            // Increase speed every 5 points
            if (score % 5 == 0) {
              dx *= 1.1;
              dy *= 1.1;
            }
          }

          // Game over if ball falls below paddle
          if (ballY > 1) {
            timer.cancel();
            isGameRunning = false;
            _showGameOver();
          }
        });
      }
    });
  }

  /// Shows Game Over dialog
  void _showGameOver() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Game Over!"),
        content: Text("Your score: $score"),
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

  /// Resets ball and paddle to center
  void resetGame() {
    setState(() {
      ballX = 0;
      ballY = 0;
      paddleX = 0;
      score = 0;
    });
    startGame();
  }

  /// Moves paddle based on finger drag (faster movement)
  void movePaddle(DragUpdateDetails details) {
    setState(() {
      // Make movement more sensitive by multiplying
      paddleX += (details.delta.dx * 2) / (MediaQuery.of(context).size.width);

      // Keep paddle inside screen
      if (paddleX < -1) paddleX = -1;
      if (paddleX > 1) paddleX = 1;
    });
  }

  /// Toggle pause/resume
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

            // Score (top center)
            Align(
              alignment: const Alignment(0, -0.95),
              child: Text(
                "Score: $score",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Play/Pause button (top right)
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
                      ? Icons.play_arrow // Before start
                      : isPaused
                          ? Icons.play_arrow // Resume
                          : Icons.pause, // Pause
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
