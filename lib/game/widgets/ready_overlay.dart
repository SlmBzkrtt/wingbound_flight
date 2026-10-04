import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_mode.dart';

class ReadyOverlay extends StatelessWidget {
  final GameMode mode;
  final int highScore;
  final VoidCallback onStart;
  final VoidCallback onOpenMenu;

  const ReadyOverlay({
    super.key,
    this.mode = GameMode.classic,
    required this.highScore,
    required this.onStart,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isCyber = mode == GameMode.cyberNeon;
    final isSpace = mode == GameMode.spaceOrbit;
    final isConquest = mode == GameMode.conquest1453;
    final isDarkTheme = isCyber || isSpace || isConquest;

    return Stack(
      children: [
        // Main Screen Tap Area to Start Game (leaves top bar untouched)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onStart,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 70),

                  // Game Title
                  if (isCyber)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'CYBER WING',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 28,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 7
                              ..color = const Color(0xFF140A28),
                          ),
                        ),
                        Text(
                          'CYBER WING',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 28,
                            color: const Color(0xFF00F3FF),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 4),
                                blurRadius: 10,
                                color: Color(0xFFFF007F),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else if (isSpace)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'KARADELİK',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 26,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 7
                              ..color = const Color(0xFF0B051D),
                          ),
                        ),
                        Text(
                          'KARADELİK',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 26,
                            color: const Color(0xFFB388FF),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 4),
                                blurRadius: 10,
                                color: Color(0xFFFF6D00),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else if (isConquest)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '1453 FETİH',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 26,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 7
                              ..color = const Color(0xFF1A0808),
                          ),
                        ),
                        Text(
                          '1453 FETİH',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 26,
                            color: const Color(0xFFFFB300),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 4),
                                blurRadius: 10,
                                color: Color(0xFFC62828),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'WINGBOUND',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 30,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 8
                              ..color = const Color(0xFF2C2416),
                          ),
                        ),
                        Text(
                          'WINGBOUND',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 30,
                            color: const Color(0xFFF7CF34),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 4),
                                color: Color(0xFFE5B01E),
                              ),
                              Shadow(
                                offset: Offset(0, 7),
                                color: Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 175),

                  // Space key badge & Tap instructions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isCyber
                          ? const Color(0xFF181236).withValues(alpha: 0.95)
                          : isSpace
                              ? const Color(0xFF130B2E).withValues(alpha: 0.95)
                              : isConquest
                                  ? const Color(0xFF1B0F12).withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCyber
                            ? const Color(0xFFFF007F)
                            : isSpace
                                ? const Color(0xFFB388FF)
                                : isConquest
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF2C2416),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isCyber
                              ? const Color(0xFFFF007F).withValues(alpha: 0.3)
                              : isSpace
                                  ? const Color(0xFFB388FF).withValues(alpha: 0.35)
                                  : isConquest
                                      ? const Color(0xFFE53935).withValues(alpha: 0.35)
                                      : Colors.black26,
                          offset: const Offset(0, 5),
                          blurRadius: isDarkTheme ? 10 : 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCyber
                                    ? const Color(0xFF00F3FF)
                                    : isSpace
                                        ? const Color(0xFFB388FF)
                                        : isConquest
                                            ? const Color(0xFFFFB300)
                                            : const Color(0xFFEEEEEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'SPACE',
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'VEYA TIKLA',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 11,
                                color: isDarkTheme ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isCyber
                              ? '⚡ Havada 2 kez bas = Çift Zıplama & Ateş!'
                              : isSpace
                                  ? '🚀 Bas = İtici Roketi Ateşle & Asteroit Geçidinden Süzül!'
                                  : isConquest
                                      ? '⚓ Bas = Dümen Kır (Sancak↔İskele) & Top Ateşle!'
                                      : 'Zıplamak & Başlamak İçin',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: isCyber
                                ? const Color(0xFF00F3FF)
                                : isSpace
                                    ? const Color(0xFF84FFFF)
                                    : isConquest
                                        ? const Color(0xFFFFD54F)
                                        : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (highScore > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCyber
                            ? const Color(0xFF2A154A)
                            : isSpace
                                ? const Color(0xFF1F1147)
                                : isConquest
                                    ? const Color(0xFF2B1010)
                                    : const Color(0xFFE8C374),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCyber
                              ? const Color(0xFF00F3FF)
                              : isSpace
                                  ? const Color(0xFFB388FF)
                                  : isConquest
                                      ? const Color(0xFFD4AF37)
                                      : const Color(0xFF553817),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'EN İYİ SKOR: $highScore',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 11,
                          color: isCyber
                              ? const Color(0xFF00F3FF)
                              : isSpace
                                  ? const Color(0xFFB388FF)
                                  : isConquest
                                      ? const Color(0xFFD4AF37)
                                      : const Color(0xFF33200B),
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // Top Navigation Bar (Layered above tap area so it ALWAYS receives clicks)
        Positioned(
          top: 45,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Active Mode Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCyber
                      ? const Color(0xFF221144)
                      : isSpace
                          ? const Color(0xFF1B0E3A)
                          : isConquest
                              ? const Color(0xFF2E0F12)
                              : Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCyber
                        ? const Color(0xFF00F3FF)
                        : isSpace
                            ? const Color(0xFFB388FF)
                            : isConquest
                                ? const Color(0xFFE53935)
                                : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isCyber
                      ? 'CYBER NEON ⚡'
                      : isSpace
                          ? 'KARADELİK 🕳️'
                          : isConquest
                              ? 'HALİÇ 1453 ⚓'
                              : 'KLASİK MOD 🐣',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8,
                    color: isCyber
                        ? const Color(0xFF00F3FF)
                        : isSpace
                            ? const Color(0xFF84FFFF)
                            : isConquest
                                ? const Color(0xFFFFD54F)
                                : Colors.white,
                  ),
                ),
              ),

              // Mode Change Button (Direct clickable button with no interference)
              ElevatedButton.icon(
                onPressed: onOpenMenu,
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: Text(
                  'MOD DEĞİŞTİR [M]',
                  style: GoogleFonts.pressStart2p(fontSize: 8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCyber
                      ? const Color(0xFFFF007F)
                      : isSpace
                          ? const Color(0xFF6200EA)
                          : isConquest
                              ? const Color(0xFFC62828)
                              : Colors.white,
                  foregroundColor: isDarkTheme ? Colors.white : Colors.black87,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isCyber
                          ? const Color(0xFF00F3FF)
                          : isSpace
                              ? const Color(0xFFB388FF)
                              : isConquest
                                  ? const Color(0xFFD4AF37)
                                  : Colors.black87,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
