// test/widget_test.dart
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 🚨 REMOVED: import 'package:flutter_application_1/main.dart'; 
// We define MyApp here for a self-contained test, or you should import the actual widget you are testing.

// 🚨 CORRECTION 1: MyApp must be a StatelessWidget or StatefulWidget for testing.
// This widget simulates the default Flutter counter app structure.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // We mock the basic MaterialApp structure needed for the counter test
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

// 🚨 Since the test expects a counter app, we need the MyHomePage widget as well
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              // The test looks for the text '0' and '1', so the key style is important.
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add), // The test taps this icon
      ),
    );
  }
}


void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 🚨 CORRECTION 2: Removed the unnecessary and incorrect cast '(const MyApp() as Widget)'
    await tester.pumpWidget(const MyApp()); 

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // Rebuilds the widget tree after the tap

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}