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
  bool _isSearching = false;
  String _sortBy = 'date';
  bool _isAscending = false;
  
  // Search & Filter
  TextEditingController _searchController = TextEditingController();
  Set<String> _selectedCategories = {};
  DateTimeRange? _dateRange;
  double _minAmount = 0;
  double _maxAmount = 100000;

  final List<String> _allCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Healthcare',
    'Education',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _applyFilters() {
    setState(() {
      _filteredExpenses = _expenses.where((expense) {
        // Search filter
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            expense.description.toLowerCase().contains(searchTerm) ||
            expense.category.toLowerCase().contains(searchTerm);

        // Category filter
        final matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(expense.category);

        // Date range filter
        final matchesDate = _dateRange == null ||
            (expense.date.isAfter(_dateRange!.start.subtract(Duration(days: 1))) &&
                expense.date.isBefore(_dateRange!.end.add(Duration(days: 1))));

        // Amount filter
        final matchesAmount = expense.amount >= _minAmount &&
            expense.amount <= _maxAmount;

        return matchesSearch && matchesCategory && matchesDate && matchesAmount;
      }).toList();

      _sortExpenses();
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

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCategories.clear();
                              _dateRange = null;
                              _minAmount = 0;
                              _maxAmount = 100000;
                            });
                          },
                          child: Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories
                          Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _allCategories.map((category) {
                              final isSelected = _selectedCategories.contains(category);
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                                selectedColor: Color(0xFF012B5B).withOpacity(0.2),
                                checkmarkColor: Color(0xFF012B5B),
                              );
                            }).toList(),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Date Range
                          Text(
                            'Date Range',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          InkWell(
                            onTap: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Color(0xFF012B5B),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setModalState(() {
                                  _dateRange = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.date_range, color: Color(0xFF012B5B)),
                                  SizedBox(width: 12),
                                  Text(
                                    _dateRange == null
                                        ? 'Select date range'
                                        : '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}',
                                  ),
                                  Spacer(),
                                  if (_dateRange != null)
                                    IconButton(
                                      icon: Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setModalState(() {
                                          _dateRange = null;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Amount Range
                          Text(
                            'Amount Range',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Min',
                                    prefixText: '₹',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setModalState(() {
                                      _minAmount = double.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Max',
                                    prefixText: '₹',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setModalState(() {
                                      _maxAmount = double.tryParse(value) ?? 100000;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Apply Button
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF012B5B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Apply Filters',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Delete Expense?'),
            ],
          ),
          content: Text('Are you sure you want to delete this expense?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            content: Text('Expense deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadExpenses();
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('My Expenses', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: !_isSearching,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.filter_list , color: Colors.white),
                  if (_selectedCategories.isNotEmpty || _dateRange != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_selectedCategories.length + (_dateRange != null ? 1 : 0)}',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFilterDialog,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.sort, color: Colors.white),
              onSelected: _toggleSort,
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(value: 'date', child: Text('Sort by Date')),
                  PopupMenuItem(value: 'amount', child: Text('Sort by Amount')),
                  PopupMenuItem(value: 'category', child: Text('Sort by Category')),
                ];
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF012B5B)))
          : _expenses.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
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
                          Text('Total Expenses', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          SizedBox(height: 8),
                          Text(
                            '₹${_getTotalAmount().toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${_filteredExpenses.length} of ${_expenses.length} transactions',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
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
          Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[300]),
          SizedBox(height: 20),
          Text('No Expenses Yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: 10),
          Text('Start tracking your spending', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
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
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        await _deleteExpense(expense);
        return false;
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getCategoryIcon(expense.category), color: categoryColor, size: 28),
          ),
          title: Text(expense.description, style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${expense.category} • ${DateFormat('dd MMM yyyy').format(expense.date)}'),
          trailing: Text(
            '₹${expense.amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF012B5B)),
          ),
        ),
      ),
    );
  }
}