import 'package:flutter_test/flutter_test.dart';
import 'package:the_builder_pros/main_app.dart';

void main() {
  testWidgets('shows theBuilderPros home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Jordan Rivers'), findsOneWidget);
    expect(find.text('Followed Apps'), findsOneWidget);
  });
}
