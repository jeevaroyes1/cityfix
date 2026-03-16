import 'package:flutter_test/flutter_test.dart';
import 'package:cityfix/main.dart';

void main() {
  testWidgets('CityFixApp loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CityFixApp());

    // Verify that the app title is found or main widget exists
    expect(find.byType(CityFixApp), findsOneWidget);
  });
}

//