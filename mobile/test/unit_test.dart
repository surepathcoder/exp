import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/income.dart';
import 'package:expense_tracker/models/wallet.dart';
import 'package:expense_tracker/models/project.dart';
import 'package:expense_tracker/models/audit_log.dart';
import 'package:expense_tracker/models/enums.dart';
import 'package:expense_tracker/models/system_settings.dart';
import 'package:expense_tracker/utils/validators.dart';

void main() {
  // ================================================================== //
  // 1. UNIT – Validators                                                //
  // ================================================================== //
  group('Validators – email', () {
    test('valid email returns null', () {
      expect(Validators.email('user@domain.com'), isNull);
    });

    test('empty email returns error', () {
      expect(Validators.email(''), isNotNull);
    });

    test('missing @ returns error', () {
      expect(Validators.email('userdomain.com'), isNotNull);
    });

    test('null returns error', () {
      expect(Validators.email(null), isNotNull);
    });
  });

  group('Validators – amount', () {
    test('valid positive amount returns null', () {
      expect(Validators.amount('100'), isNull);
    });

    test('zero is invalid', () {
      expect(Validators.amount('0'), isNotNull);
    });

    test('negative is invalid', () {
      expect(Validators.amount('-5'), isNotNull);
    });

    test('non-numeric is invalid', () {
      expect(Validators.amount('abc'), isNotNull);
    });

    test('null is invalid', () {
      expect(Validators.amount(null), isNotNull);
    });
  });

  group('Validators – password', () {
    test('6+ chars is valid', () {
      expect(Validators.password('secure1'), isNull);
    });

    test('5 chars is invalid', () {
      expect(Validators.password('abc12'), isNotNull);
    });

    test('empty is invalid', () {
      expect(Validators.password(''), isNotNull);
    });

    test('null is invalid', () {
      expect(Validators.password(null), isNotNull);
    });
  });

  // ================================================================== //
  // 2. UNIT – Expense model fromJson / toJson                          //
  // ================================================================== //
  group('Expense model', () {
    final sampleJson = {
      'id': 1,
      'amount': '150.50',
      'currency': 'USD',
      'category': 'Food',
      'date': '2025-06-01T10:00:00',
      'note': 'Lunch',
      'is_self_receipt': false,
      'payment_method': null,
      'location': null,
      'vendor': null,
      'project': null,
      'project_id': null,
      'photo_url': null,
      'user_id': 1,
      'wallet_id': null,
    };

    test('fromJson parses amount correctly', () {
      final expense = Expense.fromJson(sampleJson);
      expect(expense.amount, closeTo(150.50, 0.001));
    });

    test('fromJson parses currency', () {
      final expense = Expense.fromJson(sampleJson);
      expect(expense.currency, equals('USD'));
    });

    test('fromJson parses category', () {
      final expense = Expense.fromJson(sampleJson);
      expect(expense.category, equals('Food'));
    });

    test('fromJson parses date as DateTime', () {
      final expense = Expense.fromJson(sampleJson);
      expect(expense.date, isA<DateTime>());
    });

    test('fromJson handles null note', () {
      final json = {...sampleJson, 'note': null};
      final expense = Expense.fromJson(json);
      expect(expense.note, isNull);
    });

    test('fromJson handles integer amount', () {
      final json = {...sampleJson, 'amount': 200};
      final expense = Expense.fromJson(json);
      expect(expense.amount, closeTo(200.0, 0.001));
    });

    test('fromJson handles double amount', () {
      final json = {...sampleJson, 'amount': 99.99};
      final expense = Expense.fromJson(json);
      expect(expense.amount, closeTo(99.99, 0.001));
    });

    test('toJson includes all fields', () {
      final expense = Expense.fromJson(sampleJson);
      final json = expense.toJson();
      expect(json.containsKey('amount'), isTrue);
      expect(json.containsKey('currency'), isTrue);
      expect(json.containsKey('category'), isTrue);
      expect(json.containsKey('date'), isTrue);
    });

    test('copyWith replaces amount', () {
      final expense = Expense.fromJson(sampleJson);
      final updated = expense.copyWith(amount: 999.0);
      expect(updated.amount, closeTo(999.0, 0.001));
      expect(expense.amount, closeTo(150.50, 0.001));
    });

    test('Equatable props: two identical expenses are equal', () {
      final e1 = Expense.fromJson(sampleJson);
      final e2 = Expense.fromJson(sampleJson);
      expect(e1, equals(e2));
    });
  });

  // ================================================================== //
  // 3. UNIT – Wallet model fromJson                                     //
  // ================================================================== //
  group('Wallet model', () {
    final walletJson = {
      'id': 1,
      'name': 'My Bank',
      'type': 'bank',
      'currency': 'USD',
      'opening_balance': '1000.00',
      'balance': '750.50',
      'icon': 'bank',
      'color': '#3D1B5B',
      'is_active': true,
      'user_id': 1,
      'created_at': '2025-01-01T00:00:00',
    };

    test('fromJson parses name', () {
      final wallet = Wallet.fromJson(walletJson);
      expect(wallet.name, equals('My Bank'));
    });

    test('fromJson parses balance as double', () {
      final wallet = Wallet.fromJson(walletJson);
      expect(wallet.balance, closeTo(750.50, 0.001));
    });

    test('fromJson parses opening balance', () {
      final wallet = Wallet.fromJson(walletJson);
      expect(wallet.openingBalance, closeTo(1000.0, 0.001));
    });

    test('fromJson handles null balance → 0.0', () {
      final json = {...walletJson, 'balance': null};
      final wallet = Wallet.fromJson(json);
      expect(wallet.balance, equals(0.0));
    });

    test('fromJson parses is_active', () {
      final wallet = Wallet.fromJson(walletJson);
      expect(wallet.isActive, isTrue);
    });

    test('fromJson handles integer balance', () {
      final json = {...walletJson, 'balance': 500};
      final wallet = Wallet.fromJson(json);
      expect(wallet.balance, closeTo(500.0, 0.001));
    });
  });

  // ================================================================== //
  // 4. UNIT – Project model                                             //
  // ================================================================== //
  group('Project model', () {
    final projectJson = {
      'id': 1,
      'name': 'Youth Camp 2025',
      'description': 'Annual camp',
      'budget': 5000.0,
      'currency': 'USD',
      'status': 'active',
      'start_date': '2025-07-01T00:00:00',
      'end_date': '2025-07-10T00:00:00',
      'user_id': 1,
      'created_at': '2025-01-01T00:00:00',
    };

    test('fromJson parses name', () {
      final project = Project.fromJson(projectJson);
      expect(project.name, equals('Youth Camp 2025'));
    });

    test('fromJson parses status as enum', () {
      final project = Project.fromJson(projectJson);
      expect(project.status, equals(ProjectStatus.active));
    });

    test('fromJson parses budget', () {
      final project = Project.fromJson(projectJson);
      expect(project.budget, closeTo(5000.0, 0.001));
    });

    test('fromJson parses dates as DateTime', () {
      final project = Project.fromJson(projectJson);
      expect(project.startDate, isA<DateTime>());
      expect(project.endDate, isA<DateTime>());
    });

    test('projectStatusFromString: all statuses', () {
      expect(projectStatusFromString('upcoming'), equals(ProjectStatus.upcoming));
      expect(projectStatusFromString('active'), equals(ProjectStatus.active));
      expect(projectStatusFromString('completed'), equals(ProjectStatus.completed));
      expect(projectStatusFromString('expired'), equals(ProjectStatus.expired));
      expect(projectStatusFromString('cancelled'), equals(ProjectStatus.cancelled));
    });

    test('projectStatusFromString: unknown defaults to active', () {
      expect(projectStatusFromString('UNKNOWN'), equals(ProjectStatus.active));
    });

    test('ProjectStatus.name returns lowercase string', () {
      expect(ProjectStatus.active.name, equals('active'));
      expect(ProjectStatus.upcoming.name, equals('upcoming'));
    });

    test('copyWith replaces name only', () {
      final project = Project.fromJson(projectJson);
      final updated = project.copyWith(name: 'New Name');
      expect(updated.name, equals('New Name'));
      expect(updated.status, equals(ProjectStatus.active));
    });
  });

  // ================================================================== //
  // 5. UNIT – UserRole enum                                             //
  // ================================================================== //
  group('UserRole enum', () {
    test('roleFromString: user', () {
      expect(roleFromString('user'), equals(UserRole.user));
    });

    test('roleFromString: admin', () {
      expect(roleFromString('admin'), equals(UserRole.admin));
    });

    test('roleFromString: superadmin', () {
      expect(roleFromString('superadmin'), equals(UserRole.superadmin));
    });

    test('roleFromString: unknown defaults to user', () {
      expect(roleFromString('UNKNOWN'), equals(UserRole.user));
    });

    test('UserRole.name returns lowercase string (dart2js bug check)', () {
      // This is the critical regression – no extension shadows .name
      expect(UserRole.user.name, equals('user'));
      expect(UserRole.admin.name, equals('admin'));
      expect(UserRole.superadmin.name, equals('superadmin'));
    });
  });

  // ================================================================== //
  // 6. UNIT – SystemSettings model                                      //
  // ================================================================== //
  group('SystemSettings model', () {
    test('defaults() creates valid settings', () {
      final s = SystemSettings.defaults();
      expect(s.defaultCurrency, equals('USD'));
      expect(s.sessionTimeoutMinutes, equals(1440));
      expect(s.useLiveRates, isTrue);
    });

    test('fromJson parses app_name', () {
      final json = {
        'id': 1,
        'app_name': 'Migori Liclused',
        'default_currency': 'USD',
        'use_live_rates': false,
        'manual_rates': {'USD_TZS': 2500.0},
        'session_timeout_minutes': 480,
        'version': 2,
      };
      final s = SystemSettings.fromJson(json);
      expect(s.appName, equals('Migori Liclused'));
      expect(s.sessionTimeoutMinutes, equals(480));
      expect(s.useLiveRates, isFalse);
    });

    test('fromJson defaults on missing fields', () {
      final s = SystemSettings.fromJson({});
      expect(s.appName, equals('Expense Tracker'));
      expect(s.defaultCurrency, equals('USD'));
    });

    test('toUpdateJson includes version', () {
      final s = SystemSettings.defaults();
      final json = s.toUpdateJson(3);
      expect(json['version'], equals(3));
    });
  });

  // ================================================================== //
  // 7. UNIT – AuditLog model                                            //
  // ================================================================== //
  group('AuditLog model', () {
    final auditJson = {
      'id': 1,
      'user_id': 2,
      'user_email': 'admin@example.com',
      'action': 'update',
      'entity_type': 'expense',
      'entity_id': '5',
      'before_value': '{"amount": 100}',
      'after_value': '{"amount": 200}',
      'ip_address': '192.168.1.1',
      'created_at': '2025-06-01T12:00:00',
    };

    test('fromJson parses action', () {
      final log = AuditLog.fromJson(auditJson);
      expect(log.action, equals('update'));
    });

    test('fromJson parses entity_type', () {
      final log = AuditLog.fromJson(auditJson);
      expect(log.entityType, equals('expense'));
    });

    test('fromJson parses before/after values', () {
      final log = AuditLog.fromJson(auditJson);
      expect(log.beforeValue, contains('100'));
      expect(log.afterValue, contains('200'));
    });

    test('fromJson handles null ip_address', () {
      final json = {...auditJson, 'ip_address': null};
      final log = AuditLog.fromJson(json);
      expect(log.ipAddress, isNull);
    });

    test('toJson round-trips correctly', () {
      final log = AuditLog.fromJson(auditJson);
      final json = log.toJson();
      expect(json['action'], equals('update'));
      expect(json['user_email'], equals('admin@example.com'));
    });
  });
}
