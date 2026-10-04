import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Scoreboard extends StatefulWidget {
  final int score;

  const Scoreboard({super.key, required this.score});

  @override
  State<Scoreboard> createState() => _ScoreboardState();
}

class _ScoreboardState extends State<Scoreboard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _lastScore = 0;

  @override
  void initState() {
    super.initState();
    _lastScore = widget.score;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant Scoreboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.score > _lastScore) {
      _lastScore = widget.score;
      _controller.forward(from: 0.0);
    } else if (widget.score < _lastScore) {
      _lastScore = widget.score;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Black outline text
          Text(
            '${widget.score}',
            style: GoogleFonts.pressStart2p(
              fontSize: 48,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 8
                ..color = Colors.black,
            ),
          ),
          // White fill text with subtle shadow
          Text(
            '${widget.score}',
            style: GoogleFonts.pressStart2p(
              fontSize: 48,
              color: Colors.white,
              shadows: const [
                Shadow(
                  offset: Offset(0, 4),
                  blurRadius: 2,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
