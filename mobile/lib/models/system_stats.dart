class SystemStats {
  final int totalUsers;
  final int totalExpenses;
  final int totalIncomes;
  final int totalTransfers;
  final int totalCategories;
  final int activeCategories;
  final double totalExpenseAmountUsd;
  final double totalIncomeAmountUsd;

  const SystemStats({
    required this.totalUsers,
    required this.totalExpenses,
    required this.totalIncomes,
    required this.totalTransfers,
    required this.totalCategories,
    required this.activeCategories,
    required this.totalExpenseAmountUsd,
    required this.totalIncomeAmountUsd,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    return SystemStats(
      totalUsers: json['total_users'] ?? 0,
      totalExpenses: json['total_expenses'] ?? 0,
      totalIncomes: json['total_incomes'] ?? 0,
      totalTransfers: json['total_transfers'] ?? 0,
      totalCategories: json['total_categories'] ?? 0,
      activeCategories: json['active_categories'] ?? 0,
      totalExpenseAmountUsd: (json['total_expense_amount_usd'] as num?)?.toDouble() ?? 0,
      totalIncomeAmountUsd: (json['total_income_amount_usd'] as num?)?.toDouble() ?? 0,
    );
  }

  static SystemStats empty() {
    return const SystemStats(
      totalUsers: 0, totalExpenses: 0, totalIncomes: 0,
      totalTransfers: 0, totalCategories: 0, activeCategories: 0,
      totalExpenseAmountUsd: 0, totalIncomeAmountUsd: 0,
    );
  }
}
