import 'package:eve_esui/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Eve shell renders the entry screen', (tester) async {
    await tester.pumpWidget(const EveApp());
    await tester.pump();
    expect(find.text('Eve'), findsOneWidget);
    expect(find.text('ESUI intelligent academic companion'), findsOneWidget);
  });
}
