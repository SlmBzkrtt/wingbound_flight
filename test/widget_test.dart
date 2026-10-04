import 'package:flutter_test/flutter_test.dart';
import 'package:wingbound_flight/main.dart';

void main() {
  testWidgets('WingBound mode selection menu navigation smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WingBoundApp());
    expect(find.text('WINGBOUND'), findsWidgets);
    expect(find.text('OYUN MODUNU SEÇ'), findsOneWidget);
    expect(find.text('KLASİK RETRO'), findsOneWidget);
    expect(find.text('CYBER NEON 2077'), findsOneWidget);

    // Tap Classic Mode
    await tester.tap(find.text('KLASİK RETRO'));
    await tester.pump();

    // Now in Ready State for Classic Mode
    expect(find.text('SPACE'), findsOneWidget);
    expect(find.text('MOD DEĞİŞTİR [M]'), findsOneWidget);

    // Tap MOD DEĞİŞTİR to return to menu
    await tester.tap(find.text('MOD DEĞİŞTİR [M]'));
    await tester.pump();

    // Verify back on Mode Select Screen
    expect(find.text('OYUN MODUNU SEÇ'), findsOneWidget);

    // Tap Cyber Neon Mode
    await tester.tap(find.text('CYBER NEON 2077'));
    await tester.pump();

    // Verify Cyber Ready State
    expect(find.text('CYBER WING'), findsWidgets);
    expect(find.text('MOD DEĞİŞTİR [M]'), findsOneWidget);
  });
}
