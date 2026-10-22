import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:sidhi_florals/screens/sign_in.dart';

void main() {
  testWidgets('Sign-in gate explains access', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInScreen()));
    expect(find.text('Sign in to your shop'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
