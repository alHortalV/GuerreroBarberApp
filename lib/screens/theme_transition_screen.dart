import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ThemeTransitionScreen extends StatefulWidget {
  final bool toDark;
  final VoidCallback onFinish;
  const ThemeTransitionScreen({super.key, required this.toDark, required this.onFinish});

  @override
  State<ThemeTransitionScreen> createState() => _ThemeTransitionScreenState();
}

class _ThemeTransitionScreenState extends State<ThemeTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.forward();
    Future.delayed(const Duration(seconds: 1), widget.onFinish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = widget.toDark;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final bgColor = Color.lerp(
            Colors.blue[200],
            Colors.indigo[900],
            t,
          );
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgColor ?? Colors.blue,
                  isDark ? Colors.black : Colors.white,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Sol/Luna animados
                Align(
                  alignment: Alignment(0, -0.6),
                  child: AnimatedSwitcher(
                    duration: 600.ms,
                    child: isDark
                        ? Icon(Icons.nightlight_round, key: const ValueKey('moon'), size: 80, color: Colors.amber[200])
                        : Icon(Icons.wb_sunny, key: const ValueKey('sun'), size: 80, color: Colors.amber),
                  ),
                ),
                // Estrellas solo en modo noche
                if (isDark)
                  ...List.generate(12, (i) => Positioned(
                        left: 30.0 + i * 20.0,
                        top: 60.0 + (i % 3) * 30.0,
                        child: FadeTransition(
                          opacity: _controller,
                          child: Icon(Icons.star, size: 12, color: Colors.white.withOpacity(0.7)),
                        ),
                      )),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cambiando tema a',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isDark ? 'Oscuro' : 'Claro',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amber[200] : Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 