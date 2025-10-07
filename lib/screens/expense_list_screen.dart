import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'package:intl/intl.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseService _expenseService = ExpenseService();
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  bool _isLoading = true;
  String _sortBy = 'date'; // date, amount, category
  bool _isAscending = false;

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
      _filteredExpenses = expenses;
      _sortExpenses();
      _isLoading = false;
    });
  }

  void _sortExpenses() {
    setState(() {
      if (_sortBy == 'date') {
        _filteredExpenses.sort((a, b) => _isAscending 
            ? a.date.compareTo(b.date) 
            : b.date.compareTo(a.date));
      } else if (_sortBy == 'amount') {
        _filteredExpenses.sort((a, b) => _isAscending 
            ? a.amount.compareTo(b.amount) 
            : b.amount.compareTo(a.amount));
      } else if (_sortBy == 'category') {
        _filteredExpenses.sort((a, b) => _isAscending 
            ? a.category.compareTo(b.category) 
            : b.category.compareTo(a.category));
      }
    });
  }

  void _toggleSort(String sortType) {
    if (_sortBy == sortType) {
      setState(() {
        _isAscending = !_isAscending;
      });
    } else {
      setState(() {
        _sortBy = sortType;
        _isAscending = false;
      });
    }
    _sortExpenses();
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

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Delete Expense?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete this expense?'),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      expense.description,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _expenseService.deleteExpense(expense.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Expense deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _loadExpenses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Failed to delete expense'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  double _getTotalAmount() {
    return _filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF012B5B),
        elevation: 0,
        title: const Text(
          'My Expenses',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: _toggleSort,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18),
                      SizedBox(width: 10),
                      Text('Sort by Date'),
                      if (_sortBy == 'date') ...[
                        Spacer(),
                        Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'amount',
                  child: Row(
                    children: [
                      Icon(Icons.currency_rupee, size: 18),
                      SizedBox(width: 10),
                      Text('Sort by Amount'),
                      if (_sortBy == 'amount') ...[
                        Spacer(),
                        Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'category',
                  child: Row(
                    children: [
                      Icon(Icons.category, size: 18),
                      SizedBox(width: 10),
                      Text('Sort by Category'),
                      if (_sortBy == 'category') ...[
                        Spacer(),
                        Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                      ],
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF012B5B),
              ),
            )
          : _expenses.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Summary Card
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
                          Text(
                            'Total Expenses',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '₹${_getTotalAmount().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${_filteredExpenses.length} ${_filteredExpenses.length == 1 ? 'transaction' : 'transactions'}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Expense List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadExpenses,
                        color: Color(0xFF012B5B),
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = _filteredExpenses[index];
                            return _buildExpenseCard(expense);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          SizedBox(height: 20),
          Text(
            'No Expenses Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Start tracking your spending',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF012B5B),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.add),
            label: Text('Add First Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final categoryColor = _getCategoryColor(expense.category);
    
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 30),
            SizedBox(width: 10),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await _deleteExpense(expense);
        return false; // We handle deletion manually
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showExpenseDetails(expense),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: categoryColor,
                    size: 28,
                  ),
                ),
                
                SizedBox(width: 16),
                
                // Expense Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.category, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            expense.category,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM').format(expense.date),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF012B5B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('yyyy').format(expense.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(expense.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: _getCategoryColor(expense.category),
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${expense.id.substring(expense.id.length - 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              _buildDetailRow('Amount', '₹${expense.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Category', expense.category),
              _buildDetailRow('Description', expense.description),
              _buildDetailRow('Date', DateFormat('dd MMMM yyyy').format(expense.date)),
              _buildDetailRow('Added On', DateFormat('dd MMM yyyy, hh:mm a').format(expense.createdAt)),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteExpense(expense);
                      },
                      icon: Icon(Icons.delete),
                      label: Text('Delete'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF012B5B),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}