import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_mode.dart';

class GameOverDialog extends StatelessWidget {
  final GameMode mode;
  final int score;
  final int bestScore;
  final bool isNewHighScore;
  final VoidCallback onRestart;
  final VoidCallback onReturnToMenu;

  const GameOverDialog({
    super.key,
    this.mode = GameMode.classic,
    required this.score,
    required this.bestScore,
    required this.isNewHighScore,
    required this.onRestart,
    required this.onReturnToMenu,
  });

  Widget _buildMedal() {
    Color medalColor;
    Color medalBorder;
    String medalLabel;

    if (score >= 40) {
      medalColor = const Color(0xFFE5E4E2); // Platinum
      medalBorder = const Color(0xFF9E9E9E);
      medalLabel = '💎';
    } else if (score >= 30) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalBorder = const Color(0xFFD4AF37);
      medalLabel = '🥇';
    } else if (score >= 20) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalBorder = const Color(0xFF8A8A8A);
      medalLabel = '🥈';
    } else if (score >= 10) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalBorder = const Color(0xFF8B4513);
      medalLabel = '🥉';
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black12,
          border: Border.all(color: Colors.black26, width: 2),
        ),
        child: const Center(
          child: Text('—', style: TextStyle(fontSize: 20, color: Colors.black38)),
        ),
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medalColor,
        border: Border.all(color: medalBorder, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 3),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          medalLabel,
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCyber = mode == GameMode.cyberNeon;
    final isSpace = mode == GameMode.spaceOrbit;
    final isConquest = mode == GameMode.conquest1453;
    final isDarkCard = isCyber || isSpace || isConquest;

    final cardBg = isCyber
        ? const Color(0xFF14102C)
        : isSpace
            ? const Color(0xFF120B29)
            : isConquest
                ? const Color(0xFF220E10)
                : const Color(0xFFDED895);
    final cardBorder = isCyber
        ? const Color(0xFF00F3FF)
        : isSpace
            ? const Color(0xFFB388FF)
            : isConquest
                ? const Color(0xFFFFB300)
                : const Color(0xFF553817);
    final textColor = isDarkCard ? Colors.white : Colors.black87;
    final labelColor = isCyber
        ? const Color(0xFFFF007F)
        : isSpace
            ? const Color(0xFF84FFFF)
            : isConquest
                ? const Color(0xFFD4AF37)
                : const Color(0xFFE56E26);
    final buttonBg = isCyber
        ? const Color(0xFFFF007F)
        : isSpace
            ? const Color(0xFF6200EA)
            : isConquest
                ? const Color(0xFFC62828)
                : const Color(0xFF539B1A);
    final buttonBorder = isCyber
        ? const Color(0xFF00F3FF)
        : isSpace
            ? const Color(0xFFB388FF)
            : isConquest
                ? const Color(0xFFD4AF37)
                : const Color(0xFF2C4413);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "OYUN BİTTİ" Title
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'OYUN BİTTİ',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 28,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 6
                      ..color = isCyber
                          ? const Color(0xFF150A2E)
                          : isSpace
                              ? const Color(0xFF0B051D)
                              : isConquest
                                  ? const Color(0xFF1A1008)
                                  : const Color(0xFF3B1D04),
                  ),
                ),
                Text(
                  'OYUN BİTTİ',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 28,
                    color: isCyber
                        ? const Color(0xFFFF007F)
                        : isSpace
                            ? const Color(0xFFB388FF)
                            : isConquest
                                ? const Color(0xFFD4AF37)
                                : const Color(0xFFF95B3C),
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 4),
                        color: isCyber
                            ? const Color(0xFF00F3FF).withValues(alpha: 0.5)
                            : isSpace
                                ? const Color(0xFFFF6D00).withValues(alpha: 0.5)
                                : Colors.black38,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Scorecard Panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: isCyber
                        ? const Color(0xFF00F3FF).withValues(alpha: 0.3)
                        : isSpace
                            ? const Color(0xFFB388FF).withValues(alpha: 0.35)
                            : isConquest
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                                : Colors.black38,
                    offset: const Offset(0, 6),
                    blurRadius: isDarkCard ? 16 : 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Medal section
                      Column(
                        children: [
                          Text(
                            'MADALYA',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 10,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildMedal(),
                        ],
                      ),

                      // Scores section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SKOR',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 11,
                              color: labelColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$score',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 22,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isNewHighScore && score > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'YENİ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Text(
                                'EN İYİ',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 11,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$bestScore',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 22,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Restart Button
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: buttonBorder, width: 2.5),
                ),
              ),
              child: Text(
                'YENİDEN OYNA',
                style: GoogleFonts.pressStart2p(
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Return to Mode Menu Button
            OutlinedButton(
              onPressed: onReturnToMenu,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.black26,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                side: const BorderSide(color: Colors.white38, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'MOD DEĞİŞTİR / MENÜ',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: Colors.white70,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Space key hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black45),
                  ),
                  child: Text(
                    'SPACE',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 8,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ile hemen devam et',
                  style: TextStyle(
                    color: isCyber ? Colors.white70 : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
