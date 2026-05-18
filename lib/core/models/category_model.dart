class CategoryModel {
  final int? id;
  final String name;
  final String icon;    // emoji
  final String color;   // hex string
  final double? budget; // monthly budget limit, can be null

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'budget': budget,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) =>
      CategoryModel(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        color: map['color'],
        budget: map['budget'] != null
            ? (map['budget'] as num).toDouble()
            : null,
      );

  // Default categories inserted on first launch
  static List<CategoryModel> defaults() => [
        CategoryModel(
            name: 'Food', icon: '🍔', color: 'FF6B8A', budget: 5000),
        CategoryModel(
            name: 'Transport',
            icon: '🚗',
            color: '7C6FCD',
            budget: 3000),
        CategoryModel(
            name: 'Entertainment',
            icon: '🎮',
            color: 'FFB74D',
            budget: 2000),
        CategoryModel(
            name: 'Shopping',
            icon: '🛍️',
            color: '60B4FF',
            budget: 5000),
        CategoryModel(
            name: 'Health', icon: '💊', color: 'FF8C69', budget: 2000),
        CategoryModel(
            name: 'Utilities',
            icon: '💡',
            color: '00D4A0',
            budget: 3000),
        CategoryModel(
            name: 'Education',
            icon: '📚',
            color: 'B06FCD',
            budget: 2000),
        CategoryModel(
            name: 'Rent', icon: '🏠', color: '4DB6AC', budget: 15000),
        CategoryModel(
            name: 'Subscriptions',
            icon: '📱',
            color: 'FF6B8A',
            budget: 1000),
        CategoryModel(
            name: 'Income', icon: '💰', color: '00D4A0', budget: null),
        CategoryModel(
            name: 'Transfer',
            icon: '🔄',
            color: '8888AA',
            budget: null),
        CategoryModel(
            name: 'Other', icon: '📦', color: '555570', budget: null),
      ];

  // Quick lookup of emoji for a category name
  static String iconFor(String name) {
    const map = {
      'Food': '🍔',
      'Transport': '🚗',
      'Entertainment': '🎮',
      'Shopping': '🛍️',
      'Health': '💊',
      'Utilities': '💡',
      'Education': '📚',
      'Rent': '🏠',
      'Subscriptions': '📱',
      'Income': '💰',
      'Transfer': '🔄',
      'Other': '📦',
    };
    return map[name] ?? '📦';
  }
}