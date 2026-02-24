import 'package:flutter_test/flutter_test.dart';
import 'package:droob_alittihad/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const DroobAlittihadApp());
    expect(find.text('نموذج معاينة'), findsOneWidget);
  });
}
