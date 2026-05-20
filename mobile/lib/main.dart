import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/users_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/unread_notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddExpenseScreen(),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final expenseId = state.extra as int?;
                  return AddExpenseScreen(expenseId: expenseId);
                },
              ),
            ]
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Expense Tracker',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScaffoldWithBottomNavBar extends ConsumerWidget {
  final Widget child;
  const ScaffoldWithBottomNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final showUsersTab = user != null && user.role.name != 'user';

    int currentIndex = _calculateSelectedIndex(context, showUsersTab);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context, showUsersTab),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Expenses'),
          BottomNavigationBarItem(
            icon: Consumer(
              builder: (context, ref, _) {
                final unreadCount = ref.watch(unreadNotificationProvider);
                return Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                  child: const Icon(Icons.notifications_none),
                );
              },
            ),
            label: 'Notifications',
          ),
          if (showUsersTab)
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context, bool showUsersTab) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/expenses')) return 1;
    if (location.startsWith('/notifications')) return 2;
    if (showUsersTab) {
      if (location.startsWith('/users')) return 3;
      if (location.startsWith('/profile')) return 4;
    } else {
      if (location.startsWith('/profile')) return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool showUsersTab) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/expenses');
        break;
      case 2:
        context.go('/notifications');
        break;
      case 3:
        if (showUsersTab) {
          context.go('/users');
        } else {
          context.go('/profile');
        }
        break;
      case 4:
        if (showUsersTab) {
          context.go('/profile');
        }
        break;
    }
  }
}
