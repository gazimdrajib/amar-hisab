import 'package:amar_hisab_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots into auth flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AmarHisabApp()));
    expect(find.byType(AmarHisabApp), findsOneWidget);
  });
}
