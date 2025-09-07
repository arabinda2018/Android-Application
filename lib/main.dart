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
      body: AnimatedGradientBackground(
        child: Center(
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
                    MaterialPageRoute(builder: (_) => const DifficultyScreen()),
                  );
                },
                child: const Text("Start Game", style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
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
      body: AnimatedGradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Select Difficulty",
                style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              DifficultyButton(
                text: "Basic",
                speed: 0.02,
                paddleWidth: 140,
                context: context,
              ),
              DifficultyButton(
                text: "Intermediate",
                speed: 0.035,
                paddleWidth: 120,
                context: context,
              ),
              DifficultyButton(
                text: "Expert",
                speed: 0.05,
                paddleWidth: 100,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DifficultyButton extends StatelessWidget {
  final String text;
  final double speed;
  final double paddleWidth;
  final BuildContext context;
  const DifficultyButton({required this.text, required this.speed, required this.paddleWidth, required this.context, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => GameScreen(initialSpeed: speed, paddleWidth: paddleWidth),
            ),
          );
        },
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// -------------------- GAME SCREEN --------------------
class GameScreen extends StatefulWidget {
  final double initialSpeed;
  final double paddleWidth;
  const GameScreen({super.key, required this.initialSpeed, required this.paddleWidth});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
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

  // Particles
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    dx = widget.initialSpeed;
    dy = -widget.initialSpeed;
    paddleWidth = widget.paddleWidth;
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

    timer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (!isGameRunning) return;

      setState(() {
        // Move ball
        ballX += dx;
        ballY += dy;

        // Bounce off walls
        if (ballX <= -1 || ballX >= 1) {
          dx = -dx;
          _spawnParticles(ballX, ballY);
        }
        if (ballY <= -1) {
          dy = -dy;
          _spawnParticles(ballX, ballY);
        }

        // Paddle collision
        if (ballY >= 0.9 &&
            ballX >= paddleX - paddleWidth / 200 &&
            ballX <= paddleX + paddleWidth / 200) {
          dy = -dy;
          score++;
          _spawnParticles(ballX, ballY);

          if (score % 5 == 0) {
            dx *= 1.05;
            dy *= 1.05;
          }
        }

        // Game over
        if (ballY > 1) {
          timer.cancel();
          isGameRunning = false;

          if (score > highScore) {
            highScore = score;
            _saveHighScore(score);
          }
          _showGameOver();
        }

        // Update particles
        particles.forEach((p) => p.update());
        particles.removeWhere((p) => p.life <= 0);
      });
    });
  }

  void _spawnParticles(double x, double y) {
    for (int i = 0; i < 8; i++) {
      particles.add(Particle(
        x: x,
        y: y,
        dx: (Random().nextDouble() - 0.5) * 0.1,
        dy: (Random().nextDouble() - 0.5) * 0.1,
        color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
      ));
    }
  }

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
      particles.clear();
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
      body: AnimatedGradientBackground(
        child: GestureDetector(
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

              // Score
              Align(
                alignment: const Alignment(0, -0.95),
                child: Text(
                  "Score: $score | Best: $highScore",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),

              // Particles
              ...particles.map((p) => Align(
                    alignment: Alignment(p.x, p.y),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

/// -------------------- PARTICLE CLASS --------------------
class Particle {
  double x;
  double y;
  double dx;
  double dy;
  Color color;
  int life;

  Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.color,
    this.life = 20,
  });

  void update() {
    x += dx;
    y += dy;
    life--;
  }
}

/// -------------------- GENTLE ANIMATED BACKGROUND --------------------
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  const AnimatedGradientBackground({required this.child, super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Color?> colorAnim1;
  late Animation<Color?> colorAnim2;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // slower for gentle effect
    )..repeat(reverse: true);

    // Gentle pastel colors for less eye strain
    colorAnim1 = ColorTween(
      begin: Colors.blue.shade700,
      end: Colors.purple.shade700,
    ).animate(controller);

    colorAnim2 = ColorTween(
      begin: Colors.black87,
      end: Colors.blueGrey.shade900,
    ).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorAnim1.value!, colorAnim2.value!],
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
