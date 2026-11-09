import 'package:flutter_test/flutter_test.dart';
import 'package:tuberculosis_mapping/main.dart';

void main() {
  testWidgets('TB Mapping smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TbMappingApp());
    expect(find.textContaining('TB'), findsWidgets);
  });
}
