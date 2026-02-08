enum TransactionType { income, expense }

class WalletCategory {
  final String id;
  final String name;
  final String icon;
  final String color;

  const WalletCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory WalletCategory.fromJson(Map<String, dynamic> json) {
    return WalletCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'attach_money',
      color: json['color'] as String? ?? '#00FFFF',
    );
  }
}

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final String? categoryId;
  final String? categoryName;
  final String description;
  final String createdBy;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    this.categoryName,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryId: json['category'] as String?,
      categoryName: json['wallet_categories']?['name'] as String?,
      description: json['description'] as String? ?? '',
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'category': categoryId,
      'description': description,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
