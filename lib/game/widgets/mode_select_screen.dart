import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_mode.dart';
import '../models/skin_model.dart';
import '../services/game_services.dart';

class ModeSelectScreen extends StatefulWidget {
  final int classicHighScore;
  final int cyberHighScore;
  final int spaceHighScore;
  final int conquestHighScore;
  final ValueChanged<GameMode> onSelectMode;

  const ModeSelectScreen({
    super.key,
    required this.classicHighScore,
    required this.cyberHighScore,
    this.spaceHighScore = 0,
    this.conquestHighScore = 0,
    required this.onSelectMode,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.digit1 ||
              event.logicalKey == LogicalKeyboardKey.numpad1) {
            widget.onSelectMode(GameMode.classic);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
              event.logicalKey == LogicalKeyboardKey.numpad2) {
            widget.onSelectMode(GameMode.cyberNeon);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
              event.logicalKey == LogicalKeyboardKey.numpad3) {
            widget.onSelectMode(GameMode.spaceOrbit);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
              event.logicalKey == LogicalKeyboardKey.numpad4) {
            widget.onSelectMode(GameMode.conquest1453);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title (Responsive FittedBox prevents overflow on narrow windows)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          'WINGBOUND',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 26,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 7
                              ..color = const Color(0xFF151922),
                          ),
                        ),
                        Text(
                          'WINGBOUND',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 26,
                            color: const Color(0xFFF7CF34),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 4),
                                color: Color(0xFFE5B01E),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'MULTI REALMS',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10,
                        color: const Color(0xFF00F3FF),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'OYUN MODUNU SEÇ',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10.5,
                    color: Colors.white70,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Option 1: Classic Mode Card
              _buildModeCard(
                mode: GameMode.classic,
                number: '1',
                title: 'KLASİK RETRO',
                tag: 'ORİJİNAL',
                tagColor: const Color(0xFF539B1A),
                description: 'Nostaljik yeşil borular, sarı kuş ve kademeli 4 seviye denge sistemi.',
                highScore: widget.classicHighScore,
                borderColor: const Color(0xFF73BF2E),
                glowColor: const Color(0xFF73BF2E).withValues(alpha: 0.3),
                iconWidget: const Text('🐣', style: TextStyle(fontSize: 28)),
                onTap: () => widget.onSelectMode(GameMode.classic),
              ),

              const SizedBox(height: 12),

              // Option 2: Cyber Neon Mode Card
              _buildModeCard(
                mode: GameMode.cyberNeon,
                number: '2',
                title: 'CYBER NEON 2077',
                tag: 'SAVAŞ & AKSİYON 🔥',
                tagColor: const Color(0xFFFF007F),
                description: 'Plazma Silahı, EMP Dalgası, Düşman Dronlar, Kalkanlar ve Lazer Kapıları!',
                highScore: widget.cyberHighScore,
                borderColor: const Color(0xFF00F3FF),
                glowColor: const Color(0xFFFF007F).withValues(alpha: 0.35),
                iconWidget: const Text('⚡', style: TextStyle(fontSize: 28)),
                onTap: () => widget.onSelectMode(GameMode.cyberNeon),
              ),

              const SizedBox(height: 12),

              // Option 3: Black Hole Space Orbit Mode Card
              _buildModeCard(
                mode: GameMode.spaceOrbit,
                number: '3',
                title: 'KARADELİK YÖRÜNGESİ',
                tag: 'DERİN UZAY 🕳️',
                tagColor: const Color(0xFF7C4DFF),
                description: 'Devasa Karadeliğin olay ufkunda jetpackli astronotla 360° yörünge, Süpernova Dalgası ve Zaman Bükülmesi!',
                highScore: widget.spaceHighScore,
                borderColor: const Color(0xFFB388FF),
                glowColor: const Color(0xFFFF9100).withValues(alpha: 0.35),
                iconWidget: const Text('🧑‍🚀', style: TextStyle(fontSize: 28)),
                onTap: () => widget.onSelectMode(GameMode.spaceOrbit),
              ),

              const SizedBox(height: 12),

              // Option 4: 1453 Conquest of Constantinople (Golden Horn Galley & Şahi Cannon)
              _buildModeCard(
                mode: GameMode.conquest1453,
                number: '4',
                title: '1453 FETİH: HALİÇ',
                tag: 'DENİZ & KUŞATMA ⚓',
                tagColor: const Color(0xFFC62828),
                description: 'Dikey deniz harekâtı! Osmanlı kalyonuna dümen ver, Haliç zincirlerini ve Rum ateşi gemilerini Şahi toplarıyla parçala!',
                highScore: widget.conquestHighScore,
                borderColor: const Color(0xFFE53935),
                glowColor: const Color(0xFFFFB300).withValues(alpha: 0.35),
                iconWidget: const Text('⛵', style: TextStyle(fontSize: 28)),
                onTap: () => widget.onSelectMode(GameMode.conquest1453),
              ),

              const SizedBox(height: 14),

              Text(
                'Tıklayabilir veya klavyeden [1] / [2] / [3] / [4] basabilirsin',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required GameMode mode,
    required String number,
    required String title,
    required String tag,
    required Color tagColor,
    required String description,
    required int highScore,
    required Color borderColor,
    required Color glowColor,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              offset: const Offset(0, 4),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Tag badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: iconWidget,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade300,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Kostüm / Filo Hangarı Seçici Çubuğu
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: RealmSkinCatalog.forMode(mode).map((skin) {
                final selectedIdx =
                    GameStorageService.instance.getSelectedSkin(mode);
                final isSelected = selectedIdx == skin.index;
                return GestureDetector(
                  onTap: () {
                    GameAudioService.instance.playJump(mode);
                    setState(() {
                      GameStorageService.instance
                          .saveSelectedSkin(mode, skin.index);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? skin.primaryColor.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? skin.primaryColor
                            : Colors.white.withValues(alpha: 0.18),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: skin.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: skin.secondaryColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          skin.name,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EN İYİ: $highScore',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 9.5,
                    color: Colors.amberAccent,
                  ),
                ),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: borderColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SEÇ',
                        style: GoogleFonts.pressStart2p(fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 10),
                    ],
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
