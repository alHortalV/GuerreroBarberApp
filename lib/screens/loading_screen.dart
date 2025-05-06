import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingScreen extends StatefulWidget {
  final String text;
  const LoadingScreen({super.key, this.text = 'Cargando aplicación...'});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.forward();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : colorScheme.surface;
    final textColor = isDark ? Colors.white : colorScheme.primary;
    final iconColor = isDark ? Colors.white : colorScheme.primary;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tijeras animadas: giro y rebote
              Animate(
                effects: [
                  RotateEffect(duration: 800.ms, curve: Curves.easeInOut),
                  MoveEffect(
                    begin: const Offset(0, 0),
                    end: const Offset(0, -20),
                    duration: 600.ms,
                    curve: Curves.easeInOut,
                    delay: 200.ms,
                  ),
                ],
                child: Icon(Icons.content_cut, size: 80, color: iconColor),
                onPlay: (controller) => controller.repeat(reverse: true),
              ),
              const SizedBox(height: 24),
              // Texto animado
              Animate(
                effects: [
                  FadeEffect(duration: 600.ms),
                  SlideEffect(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                    duration: 600.ms,
                  ),
                ],
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Spinner animado
              Animate(
                effects: [FadeEffect(duration: 600.ms, delay: 200.ms)],
                child: CircularProgressIndicator(
                  color: isDark ? Colors.white : colorScheme.primary,
                  strokeWidth: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 