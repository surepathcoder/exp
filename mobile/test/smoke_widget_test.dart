import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/models/project.dart';
import 'package:expense_tracker/models/enums.dart';
import 'package:expense_tracker/utils/validators.dart';

/// Smoke tests for the Flutter app: verify core widgets render without crashing.
/// These tests use the MaterialApp wrapper and check presence of essential UI
/// elements without mocking providers (testing isolated widget shells).

// Helper: wrap a widget in MaterialApp for rendering
Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // ================================================================== //
  // 1. Basic scaffold / text widget renders                             //
  // ================================================================== //
  group('App bootstrap smoke', () {
    testWidgets('MaterialApp wrapping a Text renders successfully', (tester) async {
      await tester.pumpWidget(wrap(const Text('Expense Tracker')));
      expect(find.text('Expense Tracker'), findsOneWidget);
    });

    testWidgets('Scaffold renders without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: null,
            body: Center(child: Text('Dashboard')),
          ),
        ),
      );
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  // ================================================================== //
  // 2. Login form fields render                                         //
  // ================================================================== //
  group('Login form smoke', () {
    testWidgets('Email and password fields render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextFormField(
                  key: const Key('email_field'),
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: Validators.email,
                ),
                TextFormField(
                  key: const Key('password_field'),
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: Validators.password,
                ),
                ElevatedButton(
                  key: const Key('login_btn'),
                  onPressed: () {},
                  child: const Text('LOGIN'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_btn')), findsOneWidget);
    });

    testWidgets('Login button is tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('login_btn'),
              onPressed: () => tapped = true,
              child: const Text('LOGIN'),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('login_btn')));
      expect(tapped, isTrue);
    });
  });

  // ================================================================== //
  // 3. Expense card renders data                                        //
  // ================================================================== //
  group('Expense data display smoke', () {
    final expense = Expense(
      id: 1,
      amount: 75.00,
      currency: 'USD',
      category: 'Transport',
      date: DateTime(2025, 6, 1),
    );

    testWidgets('Expense amount is displayed', (tester) async {
      await tester.pumpWidget(
        wrap(
          Card(
            child: ListTile(
              title: Text('\$${expense.amount.toStringAsFixed(2)}'),
              subtitle: Text(expense.category),
            ),
          ),
        ),
      );
      expect(find.text('\$75.00'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
    });

    testWidgets('Expense note is shown when present', (tester) async {
      final withNote = expense.copyWith(note: 'Bus fare');
      await tester.pumpWidget(wrap(Text(withNote.note ?? '')));
      expect(find.text('Bus fare'), findsOneWidget);
    });
  });

  // ================================================================== //
  // 4. Wallet card renders                                              //
  // ================================================================== //
  group('Wallet display smoke', () {
    final walletJson = {
      'id': 1,
      'name': 'My Cash',
      'type': 'cash',
      'currency': 'USD',
      'opening_balance': 500.0,
      'balance': 320.0,
      'icon': 'wallet',
      'color': '#3D1B5B',
      'is_active': true,
      'user_id': 1,
      'created_at': '2025-01-01T00:00:00',
    };

    testWidgets('Wallet name is displayed', (tester) async {
      final wallet = Wallet.fromJson(walletJson);
      await tester.pumpWidget(wrap(Text(wallet.name)));
      expect(find.text('My Cash'), findsOneWidget);
    });

    testWidgets('Wallet balance is displayed', (tester) async {
      final wallet = Wallet.fromJson(walletJson);
      await tester.pumpWidget(
        wrap(Text('Balance: ${wallet.balance.toStringAsFixed(2)}')),
      );
      expect(find.text('Balance: 320.00'), findsOneWidget);
    });
  });

  // ================================================================== //
  // 5. Project status chip renders                                      //
  // ================================================================== //
  group('Project status display smoke', () {
    testWidgets('Active project shows ACTIVE label', (tester) async {
      await tester.pumpWidget(
        wrap(Chip(label: Text(ProjectStatus.active.name.toUpperCase()))),
      );
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('Completed project shows COMPLETED label', (tester) async {
      await tester.pumpWidget(
        wrap(Chip(label: Text(ProjectStatus.completed.name.toUpperCase()))),
      );
      expect(find.text('COMPLETED'), findsOneWidget);
    });
  });

  // ================================================================== //
  // 6. Role badge renders correctly                                     //
  // ================================================================== //
  group('UserRole badge smoke', () {
    testWidgets('SuperAdmin badge renders', (tester) async {
      final role = UserRole.superadmin;
      await tester.pumpWidget(
        wrap(
          Chip(
            label: Text(role.name.toUpperCase()),
            backgroundColor: Colors.purple.shade100,
          ),
        ),
      );
      expect(find.text('SUPERADMIN'), findsOneWidget);
    });

    testWidgets('User role badge renders', (tester) async {
      final role = UserRole.user;
      await tester.pumpWidget(
        wrap(Chip(label: Text(role.name.toUpperCase()))),
      );
      expect(find.text('USER'), findsOneWidget);
    });
  });

  // ================================================================== //
  // 7. Drawer items render                                              //
  // ================================================================== //
  group('Navigation drawer smoke', () {
    testWidgets('Essential navigation labels exist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: Drawer(
              child: ListView(
                children: const [
                  ListTile(title: Text('BALANCE')),
                  ListTile(title: Text('TRANSACTIONS')),
                  ListTile(title: Text('PROJECTS')),
                  ListTile(title: Text('REPORTS')),
                  ListTile(title: Text('MY SETTINGS')),
                ],
              ),
            ),
            body: const Center(child: Text('Dashboard')),
          ),
        ),
      );
      final ScaffoldState scaffold = tester.firstState(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pump();
      expect(find.text('BALANCE'), findsOneWidget);
      expect(find.text('TRANSACTIONS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
    });
  });

  // ================================================================== //
  // 8. Dialog render smoke                                              //
  // ================================================================== //
  group('Dialog display smoke', () {
    testWidgets('AlertDialog renders title and action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Item'),
                      actions: [
                        TextButton(onPressed: () {}, child: const Text('CANCEL')),
                        TextButton(onPressed: () {}, child: const Text('DELETE')),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
    });
  });
}
