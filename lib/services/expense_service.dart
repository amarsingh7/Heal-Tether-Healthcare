import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import 'dart:developer' as developer;

class ExpenseService {
  static const String _expensesKey = 'expenses_list';

  /// A helper method to safely get the SharedPreferences instance.
  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      developer.log('Error getting SharedPreferences instance: $e');
      return null;
    }
  }

  // Save a new expense
  Future<bool> saveExpense(Expense expense) async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return false;
    }

    try {
      final List<Expense> expenses = await getAllExpenses();
      expenses.add(expense);

      final String encodedData = jsonEncode(
        expenses.map((e) => e.toJson()).toList(),
      );

      return await prefs.setString(_expensesKey, encodedData);
    } catch (e) {
      developer.log('Error saving expense: $e');
      return false;
    }
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return [];
    }

    final String? expensesString = prefs.getString(_expensesKey);

    if (expensesString == null || expensesString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonData = jsonDecode(expensesString);
      return jsonData.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      developer.log('Error decoding expenses JSON: $e');
      return [];
    }
  }

  // Delete an expense by id
  Future<bool> deleteExpense(String id) async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return false;
    }

    try {
      List<Expense> expenses = await getAllExpenses();
      if (expenses.isEmpty) {
        return false;
      }

      expenses.removeWhere((expense) => expense.id == id);

      final String encodedData = jsonEncode(
        expenses.map((e) => e.toJson()).toList(),
      );

      return await prefs.setString(_expensesKey, encodedData);
    } catch (e) {
      developer.log('Error deleting expense: $e');
      return false;
    }
  }

  // Get total expenses
  Future<double> getTotalExpenses() async {
    final expenses = await getAllExpenses();
    return expenses.fold<double>(
      0.0,
      (double sum, Expense expense) => sum + expense.amount,
    );
  }

  // Get expenses by category
  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getAllExpenses();
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }

    return categoryTotals;
  }

  // Clear all expenses (for testing/reset)
  Future<bool> clearAllExpenses() async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return false;
    }

    try {
      return await prefs.remove(_expensesKey);
    } catch (e) {
      developer.log('Error clearing expenses: $e');
      return false;
    }
  }
}
