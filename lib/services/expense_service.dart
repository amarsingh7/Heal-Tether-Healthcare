import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseService {
  static const String _expensesKey = 'expenses_list';

  // Save a new expense
  Future<bool> saveExpense(Expense expense) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Expense> expenses = await getAllExpenses();
      expenses.add(expense);
      
      // Convert to JSON and save
      final String encodedData = jsonEncode(
        expenses.map((e) => e.toJson()).toList(),
      );
      
      return await prefs.setString(_expensesKey, encodedData);
    } catch (e) {
      print('Error saving expense: $e');
      return false;
    }
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? expensesString = prefs.getString(_expensesKey);
      
      if (expensesString == null || expensesString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonData = jsonDecode(expensesString);
      return jsonData.map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      print('Error loading expenses: $e');
      return [];
    }
  }

  // Delete an expense by id
  Future<bool> deleteExpense(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Expense> expenses = await getAllExpenses();
      expenses.removeWhere((expense) => expense.id == id);
      
      final String encodedData = jsonEncode(
        expenses.map((e) => e.toJson()).toList(),
      );
      
      return await prefs.setString(_expensesKey, encodedData);
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  // Get total expenses
  Future<double> getTotalExpenses() async {
    final expenses = await getAllExpenses();
    // Provide explicit generic and parameter types to avoid FutureOr<double>
    // inference issues from the analyzer.
    return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  // Get expenses by category
  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getAllExpenses();
    Map<String, double> categoryTotals = {};
    
    for (var expense in expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    
    return categoryTotals;
  }

  // Clear all expenses (for testing/reset)
  Future<bool> clearAllExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_expensesKey);
    } catch (e) {
      print('Error clearing expenses: $e');
      return false;
    }
  }
}