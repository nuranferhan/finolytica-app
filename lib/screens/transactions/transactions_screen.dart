import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/transaction_card.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../services/transaction_service.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with TickerProviderStateMixin {
  final HomeController homeController = Get.find();
  final TransactionService _transactionService = TransactionService();
  
  late TabController _tabController;
  String selectedFilter = 'all'; // 'all', 'income', 'expense'
  CategoryModel? selectedCategoryFilter;
  
  List<CategoryModel> allCategories = [];
  bool isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      allCategories = await _transactionService.getAllCategories();
    } catch (e) {
      print('Kategori yükleme hatası: $e');
    } finally {
      setState(() => isLoadingCategories = false);
    }
  }

  List<TransactionModel> get filteredTransactions {
    var transactions = homeController.transactions.toList();
    
    if (selectedFilter == 'income') {
      transactions = transactions.where((t) => t.isIncome).toList();
    } else if (selectedFilter == 'expense') {
      transactions = transactions.where((t) => t.isExpense).toList();
    }
    
    if (selectedCategoryFilter != null) {
      transactions = transactions.where((t) => t.categoryId == selectedCategoryFilter!.id).toList();
    }
    
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    return transactions;
  }

  String _getAddTransactionRoute() {
    switch (selectedFilter) {
      case 'income':
        return '/add_transaction?type=income';
      case 'expense':
        return '/add_transaction?type=expense';
      default:
        return '/add_transaction?type=expense'; 
    }
  }

  String _getEmptyMessage() {
    if (selectedCategoryFilter != null) {
      return 'Bu kategoride işlem yok';
    }
    
    switch (selectedFilter) {
      case 'income':
        return 'Henüz gelir işlemi yok';
      case 'expense':
        return 'Henüz gider işlemi yok';
      default:
        return 'Henüz işlem yok';
    }
  }

  String _getButtonText() {
    switch (selectedFilter) {
      case 'income':
        return 'Gelir Ekle';
      case 'expense':
        return 'Gider Ekle';
      default:
        return 'İşlem Ekle';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'İşlemler',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: isDark ? Color(0xFF1E1E1E) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.primaryColor,
              labelColor: theme.primaryColor,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              tabs: [
                Tab(text: 'Tümü'),
                Tab(text: 'Gelirler'),
                Tab(text: 'Giderler'),
              ],
              onTap: (index) {
                setState(() {
                  selectedFilter = ['all', 'income', 'expense'][index];
                  selectedCategoryFilter = null; // Kategori filtresini sıfırla
                });
              },
            ),
          ),
        ),
        actions: [
          PopupMenuButton<CategoryModel?>(
            icon: Icon(
              Icons.filter_list,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: 'Kategori Filtresi',
            color: isDark ? Color(0xFF2C2C2C) : Colors.white,
            onSelected: (CategoryModel? category) {
              setState(() {
                selectedCategoryFilter = category;
              });
            },
            itemBuilder: (context) {
              List<PopupMenuEntry<CategoryModel?>> items = [
                PopupMenuItem<CategoryModel?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.clear, 
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Tüm Kategoriler',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuDivider(),
              ];
              
              List<CategoryModel> categoriesToShow = allCategories;
              if (selectedFilter == 'income') {
                categoriesToShow = allCategories.where((c) => c.isIncomeCategory).toList();
              } else if (selectedFilter == 'expense') {
                categoriesToShow = allCategories.where((c) => c.isExpenseCategory).toList();
              }
              
              for (var category in categoriesToShow) {
                items.add(
                  PopupMenuItem<CategoryModel?>(
                    value: category,
                    child: Row(
                      children: [
                        Text(category.icon ?? '📊', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (selectedCategoryFilter?.id == category.id)
                          Icon(Icons.check, color: theme.primaryColor),
                      ],
                    ),
                  ),
                );
              }
              
              return items;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Aktif filtre göstergesi
          if (selectedCategoryFilter != null)
            Container(
              width: double.infinity,
              color: theme.primaryColor.withOpacity(0.1),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(selectedCategoryFilter!.icon ?? '📊'),
                  SizedBox(width: 8),
                  Text(
                    '${selectedCategoryFilter!.name} kategorisi',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => selectedCategoryFilter = null),
                    child: Icon(
                      Icons.close, 
                      size: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: Obx(() {
              if (homeController.isLoading.value || isLoadingCategories) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                );
              }
              
              final transactions = filteredTransactions;
              
              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long, 
                        size: 64, 
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        _getEmptyMessage(),
                        style: TextStyle(
                          fontSize: 18, 
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'İlk işleminizi ekleyerek başlayın!',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Get.toNamed(_getAddTransactionRoute()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _getButtonText(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  await homeController.refreshTransactions();
                  await _loadCategories();
                },
                color: theme.primaryColor,
                backgroundColor: isDark ? Color(0xFF2C2C2C) : Colors.white,
                child: ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: transactions.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    
                    return TransactionCard(
                      transaction: transaction,
                      onTap: () => _showTransactionDetails(context, transaction),
                      onDelete: () => _showDeleteConfirmation(context, transaction),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(_getAddTransactionRoute()),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        tooltip: 'Yeni İşlem Ekle',
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel transaction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                // Kategori ikonu ve rengi
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: transaction.category?.color != null 
                        ? Color(int.parse(transaction.category!.color!)).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.category?.icon ?? '📊',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        transaction.category?.name ?? 'Kategori Yok',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  transaction.type == 'income' ? Icons.trending_up : Icons.trending_down,
                  color: transaction.type == 'income' ? Colors.green : Colors.red,
                  size: 28,
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDetailRow('Tutar', '₺${transaction.amount.toStringAsFixed(2)}', isDark),
            _buildDetailRow('Tür', transaction.type == 'income' ? 'Gelir' : 'Gider', isDark),
            _buildDetailRow('Kategori', transaction.category?.name ?? 'Kategori Yok', isDark),
            _buildDetailRow('Tarih', _formatDate(transaction.date), isDark),
            if (transaction.description != null && transaction.description!.isNotEmpty)
              _buildDetailRow('Açıklama', transaction.description!, isDark),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      'Kapat',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Düzenle'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TransactionModel transaction) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'İşlemi Sil',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Bu işlemi silmek istediğinizden emin misiniz?',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              homeController.deleteTransaction(transaction.id!);
              Navigator.pop(context);
              Get.snackbar(
                'Başarılı', 
                'İşlem silindi',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            },
            child: Text(
              'Sil', 
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}