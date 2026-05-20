import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class ShoppingListTemplate {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> items;

  const ShoppingListTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.items,
  });
}

const List<ShoppingListTemplate> builtInShoppingListTemplates = [
  ShoppingListTemplate(
    name: 'Weekly Groceries',
    description: 'Everyday staples for a weekly grocery run.',
    icon: Icons.shopping_basket_outlined,
    color: AppColors.primaryGreen,
    items: [
      'Milk',
      'Eggs',
      'Bread',
      'Rice',
      'Vegetables',
      'Fruit',
      'Chicken',
      'Snacks',
    ],
  ),
  ShoppingListTemplate(
    name: 'Party Supplies',
    description: 'Food, drinks, and essentials for hosting guests.',
    icon: Icons.celebration_outlined,
    color: AppColors.basketOrange,
    items: [
      'Paper plates',
      'Cups',
      'Napkins',
      'Ice',
      'Drinks',
      'Chips',
      'Dessert',
      'Trash bags',
    ],
  ),
  ShoppingListTemplate(
    name: 'Household Essentials',
    description: 'Restock cleaning supplies and home basics.',
    icon: Icons.home_outlined,
    color: Colors.teal,
    items: [
      'Laundry detergent',
      'Dish soap',
      'Paper towels',
      'Toilet paper',
      'Trash bags',
      'Sponges',
      'All-purpose cleaner',
    ],
  ),
  ShoppingListTemplate(
    name: 'Travel Packing',
    description: 'Pack the must-haves before your next trip.',
    icon: Icons.luggage_outlined,
    color: Colors.indigo,
    items: [
      'Passport or ID',
      'Phone charger',
      'Toiletries',
      'Medication',
      'Change of clothes',
      'Travel snacks',
      'Sunglasses',
    ],
  ),
  ShoppingListTemplate(
    name: 'Baby & Kids Essentials',
    description: 'Common supplies for babies and kids.',
    icon: Icons.child_friendly_outlined,
    color: Colors.pink,
    items: [
      'Diapers',
      'Wipes',
      'Formula or snacks',
      'Kids toothpaste',
      'Bath soap',
      'Laundry detergent',
      'Tissues',
    ],
  ),
];
