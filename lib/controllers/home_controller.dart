import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../core/supabase.dart';

class HomeController extends GetxController {
  final TransactionService _transactionService = TransactionService();
  
  var currentIndex = 0.obs;
  var transactions = <TransactionModel>[].obs;
  var balance = 0.0.obs;
  var monthlyIncome = 0.0.obs;
  var monthlyExpense = 0.0.obs;
  var isLoading = false.obs;
  
  // Analytics için tüm işlemler ve kategoriler
  var allTransactions = <TransactionModel>[].obs;
  var lastDataRefresh = DateTime.now().obs;
  
  @override
  void onInit() {
    super.onInit();
    
    SupabaseConfig.authStateChanges.listen((AuthState authState) {
      print('DEBUG: Auth state changed: ${authState.event}');
      
      if (authState.event == AuthChangeEvent.signedIn) {
        print('DEBUG: User signed in, clearing and reloading data...');
        clearAndReloadData();
      } else if (authState.event == AuthChangeEvent.signedOut) {
        print('DEBUG: User signed out, clearing data...');
        _clearAllData();
      }
    });
    
    loadDashboardData();
  }
  
  void changeTabIndex(int index) {
    currentIndex.value = index;
    
    if (index == 2) { // Analytics tab index'i
      _refreshAnalyticsData();
    }
  }
  
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      
      final currentUser = SupabaseConfig.currentUser;
      print('DEBUG loadDashboardData - Current user ID: ${currentUser?.id}');
      
      if (currentUser == null) {
        print('DEBUG: No user found, redirecting to login');
        Get.offAllNamed('/login');
        return;
      }
      
      await _transactionService.ensureUserHasCategories();
      
      transactions.value = await _transactionService.getRecentTransactions(limit: 10);
      print('DEBUG loadDashboardData - Loaded ${transactions.length} transactions');
      
      await _loadAllTransactions();
      
      _recalculateBalanceFromAllTransactions();
      
      lastDataRefresh.value = DateTime.now();
      
    } catch (e) {
      print('DEBUG loadDashboardData error: $e');
      Get.snackbar('Hata', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _loadAllTransactions() async {
    try {
      final allTrans = await _transactionService.getAllTransactions();
      allTransactions.value = allTrans;
      print('DEBUG _loadAllTransactions - Loaded ${allTrans.length} total transactions');
    } catch (e) {
      print('DEBUG _loadAllTransactions error: $e');
    }
  }
  
  Future<void> _refreshAnalyticsData() async {
    try {
      print('DEBUG: Refreshing analytics data...');
      await _loadAllTransactions();
      lastDataRefresh.value = DateTime.now();
    } catch (e) {
      print('DEBUG _refreshAnalyticsData error: $e');
    }
  }
  
  Future<void> refreshData() async {
    await loadDashboardData();
  }
  
  Future<void> clearAndReloadData() async {
    try {
      print('DEBUG: Clearing cached data...');
      
      _clearAllData();
      
      await Future.delayed(Duration(milliseconds: 500));
      
      await loadDashboardData();
      
      print('DEBUG: Data cleared and reloaded');
    } catch (e) {
      print('Clear and reload error: $e');
    }
  }
  
  void _clearAllData() {
    transactions.clear();
    allTransactions.clear();
    balance.value = 0.0;
    monthlyIncome.value = 0.0;
    monthlyExpense.value = 0.0;
    print('DEBUG: All data cleared');
  }
  
  void _recalculateBalanceFromAllTransactions() {
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var transaction in allTransactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }
    
    balance.value = totalIncome - totalExpense;
    monthlyIncome.value = totalIncome;
    monthlyExpense.value = totalExpense;
    
    print('DEBUG _recalculateBalanceFromAllTransactions - Balance: ${balance.value}, Income: ${monthlyIncome.value}, Expense: ${monthlyExpense.value}');
    print('DEBUG - Calculated from ${allTransactions.length} total transactions');
  }
  
  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    try {
      isLoading.value = true;
      
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }
      
      print('DEBUG addTransaction - Adding for user: ${currentUser.id}');
      print('DEBUG addTransaction - Transaction data: $transactionData');
      
      TransactionModel transactionModel = TransactionModel(
        userId: currentUser.id,
        categoryId: transactionData['categoryId']?.toString(), // String'e çevir
        title: transactionData['title']?.toString() ?? '',
        amount: (transactionData['amount'] ?? 0.0).toDouble(),
        type: transactionData['type']?.toString() ?? 'expense',
        description: transactionData['description']?.toString(),
        date: transactionData['date'] ?? DateTime.now(),
        createdAt: DateTime.now(),
      );
      
      print('DEBUG addTransaction - TransactionModel: ${transactionModel.toString()}');
      print('DEBUG addTransaction - TransactionModel toMap: ${transactionModel.toMap()}');
      
      TransactionModel newTransaction = await _transactionService.addTransaction(transactionModel);
      
      transactions.insert(0, newTransaction);
      allTransactions.insert(0, newTransaction);
      
      _recalculateBalanceFromAllTransactions();
      
      lastDataRefresh.value = DateTime.now();
      
      update();
      
      print('DEBUG addTransaction - Transaction added successfully');
      
    } catch (e) {
      print('DEBUG addTransaction error: $e');
      throw Exception('İşlem eklenirken hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> deleteTransaction(String id) async {
    try {
      isLoading.value = true;
      
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }
      
      print('DEBUG deleteTransaction - Deleting transaction: $id for user: ${currentUser.id}');
      
      await _transactionService.deleteTransaction(id);
      
      transactions.removeWhere((transaction) => transaction.id == id);
      allTransactions.removeWhere((transaction) => transaction.id == id);
      
      _recalculateBalanceFromAllTransactions();
      
      lastDataRefresh.value = DateTime.now();
      
      update();
      
      print('DEBUG deleteTransaction - Transaction deleted successfully');
      
      Get.snackbar(
        'Başarılı', 
        'İşlem başarıyla silindi',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
    } catch (e) {
      print('DEBUG deleteTransaction error: $e');
      Get.snackbar('Hata', 'İşlem silinirken hata oluştu: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> refreshTransactions() async {
    try {
      isLoading.value = true;
      
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }
      
      print('DEBUG refreshTransactions - Refreshing for user: ${currentUser.id}');
      
      List<TransactionModel> refreshedRecentTransactions = await _transactionService.getRecentTransactions(limit: 10);
      
      transactions.value = refreshedRecentTransactions;
      
      await _loadAllTransactions();
      
      _recalculateBalanceFromAllTransactions();
      
      lastDataRefresh.value = DateTime.now();
      
      update();
      
      print('DEBUG refreshTransactions - Refreshed ${refreshedRecentTransactions.length} recent transactions');
      print('DEBUG refreshTransactions - Total transactions: ${allTransactions.length}');
      print('DEBUG refreshTransactions - New balance: ${balance.value}');
      
    } catch (e) {
      print('DEBUG refreshTransactions error: $e');
      Get.snackbar('Hata', 'İşlemler yenilenirken hata oluştu: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  void _recalculateBalance() {
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var transaction in transactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }
    
    balance.value = totalIncome - totalExpense;
    monthlyIncome.value = totalIncome;
    monthlyExpense.value = totalExpense;
    
    print('DEBUG _recalculateBalance (OLD METHOD) - Balance: ${balance.value}, Income: ${monthlyIncome.value}, Expense: ${monthlyExpense.value}');
    print('WARNING: This method only calculates from ${transactions.length} recent transactions');
  }
  
  Future<void> updateTransaction(String id, TransactionModel updatedTransaction) async {
    try {
      isLoading.value = true;
      
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }
      
      if (updatedTransaction.userId != currentUser.id) {
        throw Exception('Bu işlemi güncelleme yetkiniz yok');
      }
      
      print('DEBUG updateTransaction - Updating transaction: $id for user: ${currentUser.id}');
      
      await _transactionService.updateTransaction(updatedTransaction);
      
      int recentIndex = transactions.indexWhere((transaction) => transaction.id == id);
      if (recentIndex != -1) {
        transactions[recentIndex] = updatedTransaction;
      }
      
      int allIndex = allTransactions.indexWhere((transaction) => transaction.id == id);
      if (allIndex != -1) {
        allTransactions[allIndex] = updatedTransaction;
      }
      
      _recalculateBalanceFromAllTransactions();
      
      lastDataRefresh.value = DateTime.now();
      
      update();
      
      print('DEBUG updateTransaction - Transaction updated successfully');
      
      Get.snackbar(
        'Başarılı', 
        'İşlem başarıyla güncellendi',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      
    } catch (e) {
      print('DEBUG updateTransaction error: $e');
      Get.snackbar('Hata', 'İşlem güncellenirken hata oluştu: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  List<TransactionModel> get allTransactionsList => allTransactions.toList();
  
  bool get isDataStale {
    return DateTime.now().difference(lastDataRefresh.value).inMinutes > 5;
  }
  
  Future<void> forceRefreshAnalytics() async {
    await _refreshAnalyticsData();
    update();
  }
  
  
  Future<void> forceRefreshAllData() async {
    print('🔄 HomeController: External refresh requested');
    await refreshTransactions();
  }
  
  void recalculateBalanceOnly() {
    print('🧮 HomeController: Recalculating balance from existing data');
    _recalculateBalanceFromAllTransactions();
  }
  
  void debugCurrentState() {
    print('=== HomeController Debug State ===');
    print('Recent transactions: ${transactions.length}');
    print('All transactions: ${allTransactions.length}');
    print('Balance: ${balance.value}');
    print('Monthly Income: ${monthlyIncome.value}');
    print('Monthly Expense: ${monthlyExpense.value}');
    print('Last refresh: ${lastDataRefresh.value}');
    print('===================================');
  }
}