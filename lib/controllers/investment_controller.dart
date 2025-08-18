import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/savings_goal.dart';
import '../models/watchlist.dart';
import '../services/investment_service.dart';
import '../core/supabase.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart'; 
import '../services/alpha_vantage_service.dart'; 

class InvestmentController extends GetxController {
  final InvestmentService _investmentService = InvestmentService();
  
  late final AuthController authController;
  HomeController? homeController; // HomeController referansı eklendi

  final RxList<SavingsGoal> savingsGoals = <SavingsGoal>[].obs;
  final RxList<WatchlistItem> watchlist = <WatchlistItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUpdatingRates = false.obs;
  final RxInt selectedTabIndex = 0.obs;

  final RxDouble totalGoalsTarget = 0.0.obs;
  final RxDouble totalGoalsCurrent = 0.0.obs;
  final RxInt completedGoals = 0.obs;
  final RxInt totalGoals = 0.obs;
  final RxDouble goalsProgress = 0.0.obs;

  Timer? _periodicTimer;
@override
void onInit() {
  super.onInit();
  
  authController = Get.find<AuthController>();
  
  try {
    homeController = Get.find<HomeController>();
    print('✅ HomeController found and connected');
  } catch (e) {
    print('⚠️ HomeController not found yet, will be connected later');
    homeController = null;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        homeController = Get.find<HomeController>();
        print('✅ HomeController connected in post frame callback');
      } catch (e) {
        print('⚠️ HomeController still not available');
      }
    });
  }
  
  ever(authController.user, (user) {
    print('🔄 InvestmentController: User changed to ${user?.id}');
    if (user != null) {
      print('📊 Loading data for new user...');
      clearAllData();
      loadData();
    } else {
      print('🗑️ Clearing all data for logout...');
      clearAllData();
    }
  });

  if (authController.user.value != null) {
    print('🎯 Initial data load for user: ${authController.user.value?.id}');
    loadData();
    setupPeriodicUpdates();
  }
}

  @override
  void onReady() {
    super.onReady();
    
    if (homeController == null) {
      try {
        homeController = Get.find<HomeController>();
        print('✅ HomeController connected in onReady');
      } catch (e) {
        print('⚠️ HomeController still not available in onReady');
      }
    }
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    super.onClose();
  }

  
 Future<void> _syncWithHomeController() async {
  try {
    if (homeController == null) {
      try {
        homeController = Get.find<HomeController>();
        print('✅ HomeController reconnected during sync');
      } catch (e) {
        print('⚠️ HomeController not available for sync: $e');
    
        return;
      }
    }
    
    print('🔄 Syncing with HomeController...');
    
    if (homeController != null) {
      await homeController!.refreshTransactions();
      print('✅ HomeController synced successfully');
    }
  } catch (e) {
    print('❌ Error syncing with HomeController: $e');
  
  }
}

  
  void clearAllData() {
    print('🧹 Clearing all investment data...');
    savingsGoals.clear();
    watchlist.clear();
    totalGoalsTarget.value = 0.0;
    totalGoalsCurrent.value = 0.0;
    completedGoals.value = 0;
    totalGoals.value = 0;
    goalsProgress.value = 0.0;
    _periodicTimer?.cancel();
  }

  bool get hasAuthenticatedUser {
    final user = authController.user.value;
    final isAuthenticated = user != null;
    if (!isAuthenticated) {
      print('❌ No authenticated user found');
    }
    return isAuthenticated;
  }


  Future<void> loadData() async {
    if (!hasAuthenticatedUser) {
      print('❌ Cannot load data: No authenticated user');
      return;
    }

    try {
      isLoading.value = true;
      print('📊 Loading investment data...');
      
      await Future.wait([
        loadSavingsGoals(),
        loadWatchlist(),
        updateFinancialSummary(),
      ]);
      
      print('✅ Investment data loaded successfully');
    } catch (e) {
      print('❌ Error loading investment data: $e');
      Get.snackbar('Hata', 'Veriler yüklenirken hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSavingsGoals() async {
    if (!hasAuthenticatedUser) {
      savingsGoals.clear();
      return;
    }

    try {
      print('📈 Loading savings goals...');
      final goals = await _investmentService.getSavingsGoals();
      savingsGoals.value = goals;
      print('✅ Loaded ${goals.length} savings goals');
    } catch (e) {
      print('❌ Error loading savings goals: $e');
      savingsGoals.clear();
    }
  }

Future<void> loadWatchlist() async {
  if (!hasAuthenticatedUser) {
    watchlist.clear();
    return;
  }

  try {
    print('👀 Loading watchlist...');
    final items = await _investmentService.getWatchlist();
    watchlist.value = items;
    
    await _ensureDefaultItems();
    
    final updatedItems = await _investmentService.getWatchlist();
    watchlist.value = updatedItems;
    
    print('✅ Loaded ${updatedItems.length} watchlist items');
  } catch (e) {
    print('❌ Error loading watchlist: $e');
    watchlist.clear();
  }
}

Future<void> _ensureDefaultItems() async {
  if (!hasAuthenticatedUser) return;

  try {
    final existingSymbols = watchlist.map((item) => 
      '${item.symbol.toUpperCase()}_${item.type}').toSet();
    
    for (final defaultItem in defaultWatchlistItems) {
      final uniqueKey = '${defaultItem['symbol']!.toUpperCase()}_${defaultItem['type']}';
      
      if (!existingSymbols.contains(uniqueKey)) {
        try {
          final item = WatchlistItem(
            userId: authController.user.value!.id,
            symbol: defaultItem['symbol']!.toUpperCase(),
            name: defaultItem['name']!,
            type: defaultItem['type']!,
            lastUpdated: DateTime.now(),
            createdAt: DateTime.now(),
          );

          await _investmentService.addToWatchlist(item);
          
          await Future.delayed(Duration(seconds: 2));
        } catch (e) {
          print('⚠️ Error adding ${defaultItem['symbol']}: $e');
          continue;
        }
      }
    }
  } catch (e) {
    print('❌ Error in _ensureDefaultItems: $e');
  }
}
Future<void> _addDefaultWatchlistItemsSilent() async {
  if (!hasAuthenticatedUser) return;

  try {
    print('🔄 Adding default watchlist items silently...');
    
    for (final defaultItem in defaultWatchlistItems) {
      try {
        final item = WatchlistItem(
          userId: authController.user.value!.id,
          symbol: defaultItem['symbol']!.toUpperCase(),
          name: defaultItem['name']!,
          type: defaultItem['type']!,
          lastUpdated: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _investmentService.addToWatchlist(item);
        
        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        print('⚠️ Error adding ${defaultItem['symbol']}: $e');
 
        continue;
      }
    }
    
    print('✅ Default watchlist items added silently');
  } catch (e) {
    print('❌ Error in _addDefaultWatchlistItemsSilent: $e');
  }
}

  Future<void> updateFinancialSummary() async {
    if (!hasAuthenticatedUser) {
      totalGoalsTarget.value = 0.0;
      totalGoalsCurrent.value = 0.0;
      completedGoals.value = 0;
      totalGoals.value = 0;
      goalsProgress.value = 0.0;
      return;
    }

    try {
      print('📊 Updating financial summary...');
      
      final summary = await _investmentService.getFinancialSummary();
      
      totalGoalsTarget.value = summary['totalGoalsTarget'] ?? 0.0;
      totalGoalsCurrent.value = summary['totalGoalsCurrent'] ?? 0.0;
      completedGoals.value = summary['completedGoals'] ?? 0;
      totalGoals.value = summary['totalGoals'] ?? 0;
      goalsProgress.value = summary['goalsProgress'] ?? 0.0;
      
      print('✅ Financial summary updated:');
      print('   Total Goals: ${totalGoals.value}');
      print('   Completed: ${completedGoals.value}');
      print('   Progress: ${goalsProgress.value}%');
      
      update();
      
    } catch (e) {
      print('❌ Error updating financial summary: $e');
      
      // Hata durumunda varsayılan değerler
      totalGoalsTarget.value = 0.0;
      totalGoalsCurrent.value = 0.0;
      completedGoals.value = 0;
      totalGoals.value = 0;
      goalsProgress.value = 0.0;
    }
  }


  Future<void> addSavingsGoal({
    required String title,
    String? description,
    required double targetAmount,
    DateTime? targetDate,
    required String category,
    String color = '4285479655',
  }) async {
    if (!hasAuthenticatedUser) {
      Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
      return;
    }

    try {
      isLoading.value = true;
      
      final goal = SavingsGoal(
        userId: '', // Service içinde ayarlanacak
        title: title,
        description: description,
        targetAmount: targetAmount,
        targetDate: targetDate,
        category: category,
        color: color,
        createdAt: DateTime.now(),
      );

      await _investmentService.addSavingsGoal(goal);
      await loadSavingsGoals();
      await updateFinancialSummary();
      
      Get.back();
      Get.snackbar('Başarılı', 'Tasarruf hedefi eklendi');
    } catch (e) {
      Get.snackbar('Hata', 'Hedef eklenirken hata oluştu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    if (!hasAuthenticatedUser) return;

    try {
      await _investmentService.updateSavingsGoal(goal);
      await loadSavingsGoals();
      await updateFinancialSummary();
      Get.snackbar('Başarılı', 'Hedef güncellendi');
    } catch (e) {
      Get.snackbar('Hata', 'Hedef güncellenirken hata oluştu: $e');
    }
  }

  Future<void> addToGoal(String goalId, double amount, String description) async {
    if (!hasAuthenticatedUser) {
      Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
      return;
    }

    try {
      print('🔍 addToGoal Controller Debug:');
      print('   Received Goal ID: "$goalId" (type: ${goalId.runtimeType})');
      print('   Current User: ${authController.user.value?.id}');
      print('   Amount: $amount (type: ${amount.runtimeType})');
      print('   Description: "$description"');
      
      if (goalId.isEmpty) {
        print('❌ Goal ID is empty');
        Get.snackbar('Hata', 'Hedef ID bulunamadı');
        return;
      }

      if (amount <= 0) {
        print('❌ Amount is not positive: $amount');
        Get.snackbar('Hata', 'Tutar pozitif olmalı');
        return;
      }

      final existingGoal = savingsGoals.firstWhereOrNull((goal) => goal.id == goalId);
      if (existingGoal == null) {
        print('❌ Goal not found in local list: $goalId');
        print('   Available goals: ${savingsGoals.map((g) => g.id).toList()}');
        Get.snackbar('Hata', 'Hedef bulunamadı');
        return;
      }

      print('✅ All validations passed, calling service...');

      await _investmentService.addToGoal(goalId, amount, description);
      
      print('✅ Service call completed, refreshing investment data...');
      
      await Future.wait([
        loadSavingsGoals(),
        updateFinancialSummary(),
      ]);
      
      print('✅ Investment data refreshed, now syncing with HomeController...');
      
      // *** KRİTİK: HomeController'ın verilerini yenile ***
      await _syncWithHomeController();
      
      print('✅ Full synchronization completed successfully');
      
      Get.snackbar(
        'Başarılı', 
        'Hedefe ₺${amount.toStringAsFixed(2)} eklendi',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error in addToGoal controller: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      Get.snackbar(
        'Hata', 
        'Para eklenirken hata oluştu: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
  }

  Future<void> deleteSavingsGoal(String goalId) async {
    if (!hasAuthenticatedUser) return;

    try {
      await _investmentService.deleteSavingsGoal(goalId);
      
      await Future.wait([
        loadSavingsGoals(),
        updateFinancialSummary(),
      ]);
      
      await _syncWithHomeController();
      
      Get.snackbar('Başarılı', 'Hedef silindi');
    } catch (e) {
      Get.snackbar('Hata', 'Hedef silinirken hata oluştu: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGoalTransactions(String goalId) async {
    if (!hasAuthenticatedUser) return [];

    try {
      return await _investmentService.getGoalTransactions(goalId);
    } catch (e) {
      print('Error loading goal transactions: $e');
      return [];
    }
  }

  Future<void> addToWatchlist({
    required String symbol,
    required String name,
    String type = 'forex',
  }) async {
    if (!hasAuthenticatedUser) {
      Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
      return;
    }

    try {
      final existingItem = watchlist.firstWhereOrNull(
        (item) => item.symbol.toUpperCase() == symbol.toUpperCase(),
      );
      
      if (existingItem != null) {
        Get.snackbar('Uyarı', '$name zaten izleme listesinde');
        return;
      }

      final item = WatchlistItem(
        userId: '', // Service içinde ayarlanacak
        symbol: symbol.toUpperCase(),
        name: name,
        type: type,
        lastUpdated: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _investmentService.addToWatchlist(item);
      await loadWatchlist();
      Get.snackbar('Başarılı', '$name izleme listesine eklendi');
    } catch (e) {
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        Get.snackbar('Uyarı', '$name zaten izleme listesinde');
      } else {
        Get.snackbar('Hata', 'İzleme listesine eklenirken hata oluştu: $e');
      }
    }
  }

  Future<void> removeFromWatchlist(String itemId, String name) async {
    if (!hasAuthenticatedUser) return;

    try {
      await _investmentService.removeFromWatchlist(itemId);
      await loadWatchlist();
      Get.snackbar('Başarılı', '$name izleme listesinden çıkarıldı');
    } catch (e) {
      Get.snackbar('Hata', 'İzleme listesinden çıkarılırken hata oluştu: $e');
    }
  }

Future<void> updateExchangeRates() async {
  if (!hasAuthenticatedUser) return;

  try {
    isUpdatingRates.value = true;
    
    await Future.wait([
      _investmentService.updateExchangeRates(),
      _investmentService.updateWatchlistPrices(),
    ]);
    
    await loadWatchlist();
    print('All rates and prices updated at ${DateTime.now()}');
  } catch (e) {
    if (e.toString().contains('network') || e.toString().contains('timeout')) {
      Get.snackbar('Uyarı', 'İnternet bağlantısını kontrol edin');
    } else {
      Get.snackbar('Uyarı', 'Bazı veriler güncellenemedi');
    }
    print('Error updating rates and prices: $e');
  } finally {
    isUpdatingRates.value = false;
  }
}

Future<void> addDefaultWatchlistItems() async {
  if (!hasAuthenticatedUser) {
    Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
    return;
  }

  try {
    isLoading.value = true;
    
    final existingSymbols = watchlist.map((item) => item.symbol.toUpperCase()).toSet();
    int addedCount = 0;
    
    for (final defaultItem in defaultWatchlistItems) {
      final symbol = defaultItem['symbol']!.toUpperCase();
      
      if (existingSymbols.contains(symbol)) {
        continue;
      }
      
      try {
        final item = WatchlistItem(
          userId: authController.user.value!.id,
          symbol: symbol,
          name: defaultItem['name']!,
          type: defaultItem['type']!,
          lastUpdated: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _investmentService.addToWatchlist(item);
        addedCount++;
        
        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        print('Error adding ${defaultItem['symbol']}: $e');
        continue;
      }
    }
    
    await loadWatchlist();
    
    if (addedCount > 0) {
      Get.snackbar('Başarılı', '$addedCount yeni öğe eklendi');
    } else {
      Get.snackbar('Bilgi', 'Tüm popüler öğeler zaten listede');
    }
  } catch (e) {
    Get.snackbar('Hata', 'Öğeler eklenirken hata oluştu');
    print('Error adding default watchlist items: $e');
  } finally {
    isLoading.value = false;
  }
}

  void changeTabIndex(int index) {
    selectedTabIndex.value = index;
    update();
  }

  TabController? _tabController;

  void setTabController(TabController controller) {
    _tabController = controller;
  }

  void changeTabIndexWithController(int index) {
    selectedTabIndex.value = index;
    if (_tabController != null && _tabController!.length > index) {
      _tabController!.animateTo(index);
    }
  }

  void setupPeriodicUpdates() {
    _periodicTimer?.cancel();
    
    if (!hasAuthenticatedUser) return;
    
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 10),
      (timer) {
        if (!hasAuthenticatedUser) {
          timer.cancel();
          return;
        }
        
        if (watchlist.isNotEmpty) {
          updateExchangeRates();
        }
      },
    );
  }

  Future<void> refreshData() async {
    if (!hasAuthenticatedUser) {
      print('❌ Cannot refresh: No authenticated user');
      return;
    }

    print('🔄 Manual refresh triggered');
    await loadData();
    if (watchlist.isNotEmpty) {
      await updateExchangeRates();
    }
  }


  List<SavingsGoal> get activeGoals => 
      savingsGoals.where((goal) => !goal.isCompleted).toList();

  List<SavingsGoal> get completedGoalsList => 
      savingsGoals.where((goal) => goal.isCompleted).toList();

  List<WatchlistItem> get topChangers {
    if (watchlist.isEmpty) return [];
    
    final sorted = List<WatchlistItem>.from(watchlist);
    sorted.sort((a, b) => b.changePercentage.abs().compareTo(a.changePercentage.abs()));
    return sorted.take(3).toList();
  }

  List<WatchlistItem> get gainers => 
      watchlist.where((item) => item.changePercentage > 0).toList();

  List<WatchlistItem> get losers => 
      watchlist.where((item) => item.changePercentage < 0).toList();

  double get thisMonthGoalContributions {
    return savingsGoals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

final RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
final RxBool isSearching = false.obs;

Future<void> searchAndAddStock(String query) async {
  if (!hasAuthenticatedUser) {
    Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
    return;
  }

  if (query.isEmpty) {
    searchResults.clear();
    return;
  }

  try {
    isSearching.value = true;
    final results = await _investmentService.searchSymbols(query);
    
    searchResults.value = results.where((item) => 
      item['type']?.toString().toLowerCase().contains('equity') == true ||
      item['type']?.toString().toLowerCase().contains('stock') == true
    ).toList();
    
    if (searchResults.isEmpty) {
      Get.snackbar('Bilgi', 'Arama sonucu bulunamadı');
    }
  } catch (e) {
    Get.snackbar('Hata', 'Arama sırasında hata oluştu: $e');
    searchResults.clear();
  } finally {
    isSearching.value = false;
  }
}

Future<void> addStockToWatchlist(String symbol, String name) async {
  if (!hasAuthenticatedUser) {
    Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
    return;
  }

  try {
    final existingItem = watchlist.firstWhereOrNull(
      (item) => item.symbol.toUpperCase() == symbol.toUpperCase() && item.type == 'stock',
    );
    
    if (existingItem != null) {
      Get.snackbar('Uyarı', '$name zaten izleme listesinde');
      return;
    }

    isLoading.value = true;
    await _investmentService.addStockToWatchlist(symbol);
    await loadWatchlist();
    
    Get.snackbar('Başarılı', '$name hisse senedi eklendi');
  } catch (e) {
    Get.snackbar('Hata', 'Hisse senedi eklenirken hata oluştu: $e');
  } finally {
    isLoading.value = false;
  }
}

Future<void> addCryptoToWatchlist(String symbol, String name) async {
  if (!hasAuthenticatedUser) {
    Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
    return;
  }

  try {
    final existingItem = watchlist.firstWhereOrNull(
      (item) => item.symbol.toUpperCase() == symbol.toUpperCase() && item.type == 'crypto',
    );
    
    if (existingItem != null) {
      Get.snackbar('Uyarı', '$name zaten izleme listesinde');
      return;
    }

    isLoading.value = true;
    await _investmentService.addCryptoToWatchlist(symbol);
    await loadWatchlist();
    
    Get.snackbar('Başarılı', '$name kripto para eklendi');
  } catch (e) {
    Get.snackbar('Hata', 'Kripto para eklenirken hata oluştu: $e');
  } finally {
    isLoading.value = false;
  }
}

Future<void> updateWatchlistPrices() async {
  if (!hasAuthenticatedUser) return;

  try {
    isUpdatingRates.value = true;
    await _investmentService.updateWatchlistPrices();
    await loadWatchlist();
    
    Get.snackbar('Başarılı', 'Fiyatlar güncellendi');
  } catch (e) {
    Get.snackbar('Hata', 'Fiyatlar güncellenirken hata oluştu: $e');
  } finally {
    isUpdatingRates.value = false;
  }
}

Future<void> addPopularStocks() async {
  if (!hasAuthenticatedUser) {
    Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
    return;
  }

  try {
    isLoading.value = true;
    
    final popularStocks = ['AAPL', 'GOOGL', 'MSFT', 'TSLA'];
    
    for (String symbol in popularStocks) {
      final exists = watchlist.any((item) => 
        item.symbol.toUpperCase() == symbol && item.type == 'stock');
      
      if (!exists) {
        try {
          await _investmentService.addStockToWatchlist(symbol);
          await Future.delayed(Duration(seconds: 1)); // Rate limiting
        } catch (e) {
          print('Error adding $symbol: $e');
        }
      }
    }
    
    await loadWatchlist();
    Get.snackbar('Başarılı', 'Popüler hisse senetleri eklendi');
  } catch (e) {
    Get.snackbar('Hata', 'Hisse senetleri eklenirken hata oluştu: $e');
  } finally {
    isLoading.value = false;
  }
}

Future<void> addPopularCryptos() async {
  if (!hasAuthenticatedUser) {
    Get.snackbar('Hata', 'Kullanıcı doğrulanmamış');
    return;
  }

  try {
    isLoading.value = true;
    
    final popularCryptos = ['BTC', 'ETH', 'ADA'];
    
    for (String symbol in popularCryptos) {
      final exists = watchlist.any((item) => 
        item.symbol.toUpperCase() == symbol && item.type == 'crypto');
      
      if (!exists) {
        try {
          await _investmentService.addCryptoToWatchlist(symbol);
          await Future.delayed(Duration(seconds: 1)); // Rate limiting
        } catch (e) {
          print('Error adding $symbol: $e');
        }
      }
    }
    
    await loadWatchlist();
    Get.snackbar('Başarılı', 'Popüler kripto paralar eklendi');
  } catch (e) {
    Get.snackbar('Hata', 'Kripto paralar eklenirken hata oluştu: $e');
  } finally {
    isLoading.value = false;
  }
}

List<Map<String, String>> get defaultWatchlistItems => [
  // DÖVIZLER - Sadece en önemliler
  {'symbol': 'USD', 'name': 'Amerikan Doları', 'type': 'forex'},
  {'symbol': 'EUR', 'name': 'Euro', 'type': 'forex'},
  {'symbol': 'GBP', 'name': 'İngiliz Sterlini', 'type': 'forex'},
//  {'symbol': 'JPY', 'name': 'Japon Yeni', 'type': 'forex'},
//  {'symbol': 'CHF', 'name': 'İsviçre Frangı', 'type': 'forex'},
  
  // KRİPTO PARALAR - Sadece en büyük 5
  {'symbol': 'BTC', 'name': 'Bitcoin', 'type': 'crypto'},
  {'symbol': 'ETH', 'name': 'Ethereum', 'type': 'crypto'},
  {'symbol': 'USDT', 'name': 'Tether', 'type': 'crypto'},
  //{'symbol': 'BNB', 'name': 'BNB', 'type': 'crypto'},
//  {'symbol': 'XRP', 'name': 'XRP', 'type': 'crypto'},
  
  // HİSSE SENETLERİ - Sadece en popüler 10
  {'symbol': 'AAPL', 'name': 'Apple Inc.', 'type': 'stock'}, 
  {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'type': 'stock'},
  {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'type': 'stock'},
//  {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'type': 'stock'},
//  {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'type': 'stock'},
//  {'symbol': 'META', 'name': 'Meta Platforms Inc.', 'type': 'stock'},
//  {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'type': 'stock'},
/*  {'symbol': 'NFLX', 'name': 'Netflix Inc.', 'type': 'stock'},
  {'symbol': 'DIS', 'name': 'Walt Disney Company', 'type': 'stock'},
  {'symbol': 'PYPL', 'name': 'PayPal Holdings Inc.', 'type': 'stock'}, */
];
  List<Map<String, String>> get goalCategories => [
    {'key': 'emergency', 'name': 'Acil Durum', 'icon': '🚨'},
    {'key': 'vacation', 'name': 'Tatil', 'icon': '🏖️'},
    {'key': 'house', 'name': 'Ev', 'icon': '🏠'},
    {'key': 'car', 'name': 'Araba', 'icon': '🚗'},
    {'key': 'education', 'name': 'Eğitim', 'icon': '📚'},
    {'key': 'wedding', 'name': 'Düğün', 'icon': '💍'},
    {'key': 'general', 'name': 'Genel', 'icon': '💰'},
  ];

List<Map<String, String>> get popularCurrencies => [
  {'symbol': 'USD', 'name': 'Amerikan Doları'},
  {'symbol': 'EUR', 'name': 'Euro'},
  {'symbol': 'GBP', 'name': 'İngiliz Sterlini'},
  {'symbol': 'CHF', 'name': 'İsviçre Frangı'},
  {'symbol': 'JPY', 'name': 'Japon Yeni'},
  {'symbol': 'CAD', 'name': 'Kanada Doları'},
  {'symbol': 'AUD', 'name': 'Avustralya Doları'},
  {'symbol': 'CNY', 'name': 'Çin Yuanı'},
  {'symbol': 'RUB', 'name': 'Rus Rublesi'},
];

List<Map<String, String>> get popularStocks => [
  {'symbol': 'AAPL', 'name': 'Apple Inc.'},
  {'symbol': 'GOOGL', 'name': 'Alphabet Inc.'},
  {'symbol': 'MSFT', 'name': 'Microsoft Corporation'},
  {'symbol': 'TSLA', 'name': 'Tesla Inc.'},
  {'symbol': 'AMZN', 'name': 'Amazon.com Inc.'},
  {'symbol': 'META', 'name': 'Meta Platforms Inc.'},
  {'symbol': 'NVDA', 'name': 'NVIDIA Corporation'},
];

List<Map<String, String>> get popularCryptos => [
  {'symbol': 'BTC', 'name': 'Bitcoin'},
  {'symbol': 'ETH', 'name': 'Ethereum'},
  {'symbol': 'ADA', 'name': 'Cardano'},
  {'symbol': 'DOT', 'name': 'Polkadot'},
  {'symbol': 'LINK', 'name': 'Chainlink'},
];

  List<Map<String, dynamic>> get goalColors => [
    {'name': 'Mavi', 'value': '4285479655', 'color': Colors.blue},
    {'name': 'Yeşil', 'value': '4283215696', 'color': Colors.green},
    {'name': 'Turuncu', 'value': '4294940672', 'color': Colors.orange},
    {'name': 'Mor', 'value': '4288423856', 'color': Colors.purple},
    {'name': 'Kırmızı', 'value': '4294198070', 'color': Colors.red},
    {'name': 'İndigo', 'value': '4283662478', 'color': Colors.indigo},
  ];


  bool isValidGoalAmount(String amount) {
    if (amount.isEmpty) return false;
    final parsed = double.tryParse(amount);
    return parsed != null && parsed > 0 && parsed <= 10000000;
  }

  bool isValidGoalTitle(String title) {
    return title.trim().length >= 3 && title.trim().length <= 50;
  }

  String? validateTargetDate(DateTime? date) {
    if (date == null) return null;
    
    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 1));
    final maxDate = now.add(const Duration(days: 3650));
    
    if (date.isBefore(minDate)) {
      return 'Hedef tarihi en az yarın olmalı';
    }
    
    if (date.isAfter(maxDate)) {
      return 'Hedef tarihi en fazla 10 yıl sonra olabilir';
    }
    
    return null;
  }


  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '₺${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₺${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₺${amount.toStringAsFixed(0)}';
    }
  }

  String formatProgress(double progress) {
    return '%${progress.clamp(0, 100).toStringAsFixed(1)}';
  }


  Map<String, int> get goalsByCategory {
    final Map<String, int> categoryCount = {};
    for (final goal in savingsGoals) {
      categoryCount[goal.category] = (categoryCount[goal.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  double get averageGoalCompletion {
    if (savingsGoals.isEmpty) return 0.0;
    final totalProgress = savingsGoals.fold(0.0, (sum, goal) => sum + goal.progressPercentage);
    return totalProgress / savingsGoals.length;
  }
}
