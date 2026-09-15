import 'package:flutter_test/flutter_test.dart';

import 'package:resivyn/app.dart';

void main() {
  testWidgets('app renders login screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ResivynApp());
    await tester.pump();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
