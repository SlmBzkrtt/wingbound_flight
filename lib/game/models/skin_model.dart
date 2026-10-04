import 'package:flutter/material.dart';
import 'game_mode.dart';

class RealmSkin {
  final int index;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  const RealmSkin({
    required this.index,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });
}

class RealmSkinCatalog {
  static const List<RealmSkin> classicSkins = [
    RealmSkin(
      index: 0,
      name: 'ALTIN SERÇE',
      primaryColor: Color(0xFFF5B700),
      secondaryColor: Color(0xFFFFD166),
      accentColor: Color(0xFFFFFCF2),
    ),
    RealmSkin(
      index: 1,
      name: 'ZÜMRÜT ANKA',
      primaryColor: Color(0xFF00C853),
      secondaryColor: Color(0xFF69F0AE),
      accentColor: Color(0xFFFFD54F),
    ),
    RealmSkin(
      index: 2,
      name: 'KIZIL ŞAHİN',
      primaryColor: Color(0xFFE53935),
      secondaryColor: Color(0xFFFF8A80),
      accentColor: Color(0xFFFFF8E1),
    ),
  ];

  static const List<RealmSkin> cyberSkins = [
    RealmSkin(
      index: 0,
      name: 'SİBER VALKÜR',
      primaryColor: Color(0xFF00F3FF),
      secondaryColor: Color(0xFFFF007F),
      accentColor: Color(0xFF1A1F35),
    ),
    RealmSkin(
      index: 1,
      name: 'NEON HAYALET',
      primaryColor: Color(0xFF00E676),
      secondaryColor: Color(0xFFB388FF),
      accentColor: Color(0xFF0F1926),
    ),
    RealmSkin(
      index: 2,
      name: 'ALTIN OVERDRIVE',
      primaryColor: Color(0xFFFFD54F),
      secondaryColor: Color(0xFFFF3D00),
      accentColor: Color(0xFF241715),
    ),
  ];

  static const List<RealmSkin> spaceSkins = [
    RealmSkin(
      index: 0,
      name: 'UFUK KAŞİFİ',
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFFCFD8DC),
      accentColor: Color(0xFFB388FF),
    ),
    RealmSkin(
      index: 1,
      name: 'NEBULA KRUVAZÖR',
      primaryColor: Color(0xFFE040FB),
      secondaryColor: Color(0xFFEA80FC),
      accentColor: Color(0xFFFFD54F),
    ),
    RealmSkin(
      index: 2,
      name: 'SOLAR NOVA',
      primaryColor: Color(0xFFFF9100),
      secondaryColor: Color(0xFFFFE082),
      accentColor: Color(0xFF00E5FF),
    ),
  ];

  static const List<RealmSkin> conquestSkins = [
    RealmSkin(
      index: 0,
      name: 'FATİH KADIRGASI',
      primaryColor: Color(0xFFC62828),
      secondaryColor: Color(0xFF6D4024),
      accentColor: Color(0xFFFFD54F),
    ),
    RealmSkin(
      index: 1,
      name: 'ALTIN SANCAK',
      primaryColor: Color(0xFF00695C),
      secondaryColor: Color(0xFF5D4037),
      accentColor: Color(0xFFFFD700),
    ),
    RealmSkin(
      index: 2,
      name: 'KARADENİZ KURDU',
      primaryColor: Color(0xFF1565C0),
      secondaryColor: Color(0xFF37474F),
      accentColor: Color(0xFFE0E0E0),
    ),
  ];

  static List<RealmSkin> forMode(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return classicSkins;
      case GameMode.cyberNeon:
        return cyberSkins;
      case GameMode.spaceOrbit:
        return spaceSkins;
      case GameMode.conquest1453:
        return conquestSkins;
    }
  }

  static RealmSkin getSkin(GameMode mode, int index) {
    final list = forMode(mode);
    return list[index.clamp(0, list.length - 1)];
  }
}
