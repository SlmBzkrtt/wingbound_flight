import 'package:flutter/material.dart';

enum GameMode {
  classic,
  cyberNeon,
  spaceOrbit,
  conquest1453,
}

extension GameModeExtension on GameMode {
  String get title {
    switch (this) {
      case GameMode.classic:
        return 'KLASİK MOD';
      case GameMode.cyberNeon:
        return 'CYBER NEON';
      case GameMode.spaceOrbit:
        return 'KARADELİK YÖRÜNGESİ';
      case GameMode.conquest1453:
        return '1453 FETİH: HALİÇ';
    }
  }

  String get subtitle {
    switch (this) {
      case GameMode.classic:
        return 'Orijinal piksel şehir, sarı kuş ve klasik yeşil borular.';
      case GameMode.cyberNeon:
        return 'Synthwave neon dünya, kalkanlar, altın yıldızlar ve lazer kuleleri!';
      case GameMode.spaceOrbit:
        return 'Devasa Karadeliğin çekim alanında 360° uzay yörüngesi! İtici roketleri ateşle ve asteroit geçitlerinden süzül!';
      case GameMode.conquest1453:
        return 'Yağlı kızaklarla Haliç\'e inen Osmanlı Kalyonu! Zincirleri Şahi topuyla kır, Rum ateşi gemilerini batır!';
    }
  }

  String get tag {
    switch (this) {
      case GameMode.classic:
        return 'NOSTALJİK';
      case GameMode.cyberNeon:
        return 'YENİ NESİL 🔥';
      case GameMode.spaceOrbit:
        return 'DERİN UZAY 🕳️';
      case GameMode.conquest1453:
        return 'DESTANSI KUŞATMA ⚓';
    }
  }

  Color get primaryColor {
    switch (this) {
      case GameMode.classic:
        return const Color(0xFF73BF2E);
      case GameMode.cyberNeon:
        return const Color(0xFF00F3FF);
      case GameMode.spaceOrbit:
        return const Color(0xFFB388FF);
      case GameMode.conquest1453:
        return const Color(0xFFE53935);
    }
  }

  Color get secondaryColor {
    switch (this) {
      case GameMode.classic:
        return const Color(0xFFF7CF34);
      case GameMode.cyberNeon:
        return const Color(0xFFFF007F);
      case GameMode.spaceOrbit:
        return const Color(0xFFFF9100);
      case GameMode.conquest1453:
        return const Color(0xFFFFB300);
    }
  }
}
