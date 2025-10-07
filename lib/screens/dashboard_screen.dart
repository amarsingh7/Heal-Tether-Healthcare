
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    final expenses = await _expenseService.getAllExpenses();
    
    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  List<Expense> _getFilteredExpenses() {
    final now = DateTime.now();
    
    switch (_selectedPeriod) {
      case 'Today':
        return _expenses.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month && 
          e.date.day == now.day
        ).toList();
      
      case 'This Week':
        final weekAgo = now.subtract(Duration(days: 7));
        return _expenses.where((e) => e.date.isAfter(weekAgo)).toList();
      
      case 'This Month':
        return _expenses.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month
        ).toList();
      
      case 'This Year':
        return _expenses.where((e) => e.date.year == now.year).toList();
      
      default:
        return _expenses;
    }
  }

  double _getTotalAmount() {
    final filtered = _getFilteredExpenses();
    return filtered.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> _getCategoryBreakdown() {
    final filtered = _getFilteredExpenses();
    Map<String, double> breakdown = {};
    
    for (var expense in filtered) {
      breakdown[expense.category] = 
          (breakdown[expense.category] ?? 0.0) + expense.amount;
    }
    
    return breakdown;
  }

  Map<String, double> _getDailySpending() {
    final filtered = _getFilteredExpenses();
    Map<String, double> daily = {};
    
    for (var expense in filtered) {
      final dateKey = DateFormat('dd MMM').format(expense.date);
      daily[dateKey] = (daily[dateKey] ?? 0.0) + expense.amount;
    }
    
    return daily;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Dining':
        return Colors.orange;
      case 'Transportation':
        return Colors.blue;
      case 'Shopping':
        return Colors.pink;
      case 'Entertainment':
        return Colors.purple;
      case 'Bills & Utilities':
        return Colors.red;
      case 'Healthcare':
        return Colors.green;
      case 'Education':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Dining':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_car;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills & Utilities':
        return Icons.receipt_long;
      case 'Healthcare':
        return Icons.medical_services;
      case 'Education':
        return Icons.school;
      default:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _getFilteredExpenses();
    final totalAmount = _getTotalAmount();
    final categoryBreakdown = _getCategoryBreakdown();
    final dailySpending = _getDailySpending();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF012B5B),
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF012B5B)))
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              color: Color(0xFF012B5B),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header with Period Selector
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Color(0xFF012B5B),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.analytics, color: Colors.white, size: 50),
                          SizedBox(height: 10),
                          Text(
                            'Spending Overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 15),
                          // Period Selector
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: ['Today', 'This Week', 'This Month', 'This Year']
                                  .map((period) => _buildPeriodChip(period))
                                  .toList(),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${filteredExpenses.length} transactions',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats
                          _buildQuickStats(filteredExpenses),
                          
                          SizedBox(height: 20),
                          
                          // Category Breakdown
                          if (categoryBreakdown.isNotEmpty) ...[
                            _buildSectionTitle('Category Breakdown'),
                            SizedBox(height: 16),
                            _buildPieChart(categoryBreakdown, totalAmount),
                            SizedBox(height: 16),
                            _buildCategoryList(categoryBreakdown, totalAmount),
                            SizedBox(height: 20),
                          ],
                          
                          // Daily Spending Chart
                          if (dailySpending.isNotEmpty) ...[
                            _buildSectionTitle('Spending Trend'),
                            SizedBox(height: 16),
                            _buildBarChart(dailySpending),
                            SizedBox(height: 20),
                          ],
                          
                          // Top Expenses
                          if (filteredExpenses.isNotEmpty) ...[
                            _buildSectionTitle('Top Expenses'),
                            SizedBox(height: 16),
                            _buildTopExpenses(filteredExpenses),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = period == _selectedPeriod;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: isSelected ? Color(0xFF012B5B) : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(List<Expense> expenses) {
    final avgExpense = expenses.isEmpty ? 0.0 : _getTotalAmount() / expenses.length;
    final maxExpense = expenses.isEmpty ? 0.0 : expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final minExpense = expenses.isEmpty ? 0.0 : expenses.map((e) => e.amount).reduce((a, b) => a < b ? a : b);

    return Row(
      children: [
        Expanded(child: _buildStatCard('Average', '₹${avgExpense.toStringAsFixed(0)}', Icons.analytics, Colors.blue)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Highest', '₹${maxExpense.toStringAsFixed(0)}', Icons.arrow_upward, Colors.red)),
        SizedBox(width: 12),
        Expanded(child: _buildStatCard('Lowest', '₹${minExpense.toStringAsFixed(0)}', Icons.arrow_downward, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> breakdown, double total) {
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: sortedEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            final amount = entry.value.value;
            final percentage = (amount / total * 100);

            return PieChartSectionData(
              value: amount,
              title: '${percentage.toStringAsFixed(1)}%',
              color: _getCategoryColor(category),
              radius: 60,
              titleStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> breakdown, double total) {
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: sortedEntries.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = (amount / total * 100);

          return ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor(category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
                size: 20,
              ),
            ),
            title: Text(
              category,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(_getCategoryColor(category)),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF012B5B),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> dailySpending) {
    final entries = dailySpending.entries.toList();
    if (entries.length > 7) {
      entries.removeRange(0, entries.length - 7); // Show last 7 days
    }

    final maxAmount = entries.isEmpty ? 0.0 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount * 1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        entries[value.toInt()].key,
                        style: TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: Color(0xFF012B5B),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopExpenses(List<Expense> expenses) {
    final topExpenses = expenses.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final displayExpenses = topExpenses.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: displayExpenses.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: _getCategoryColor(expense.category),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              expense.description,
              style: TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${expense.category} • ${DateFormat('dd MMM').format(expense.date)}',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF012B5B),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}