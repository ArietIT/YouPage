import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:eduapge2/main.dart' as app;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('smoke test', () {
    testWidgets('app boots without remote services', (tester) async {
      SharedPreferences.setMockInitialValues({
        'ice': false,
        'customEndpoint': '',
        'quickstart': false,
        'token': '',
      });

      runApp(const app.MyApp());
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('time helpers still work', (tester) async {
      final now = DateTime.now();
      final date = DateTime.parse('${now.year}-01-01 04:20');
      expect(date.hour, 4);
      expect(date.minute, 20);

      final day = DateFormat('d', 'en_US').format(now);
      expect(day.isNotEmpty, isTrue);
    });
  });
}
