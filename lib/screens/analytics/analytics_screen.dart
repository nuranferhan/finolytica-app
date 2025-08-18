import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/home_controller.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../services/transaction_service.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../core/theme.dart';
import 'dart:math' as math;

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final HomeController homeController = Get.find();
  final TransactionService _transactionService = TransactionService();
  
  double get currentBalance {
    final transactions = filteredTransactions;
    final totalIncome = transactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount.toDouble());
    final totalExpense = transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount.toDouble());
    return totalIncome - totalExpense;
  }

  late TabController _tabController;
  String selectedPeriod = 'monthly'; // 'daily', 'weekly', 'monthly'
  String selectedChartType = 'pie'; // 'pie', 'doughnut', 'bar'
  
  List<TransactionModel> allTransactions = [];
  List<CategoryModel> allCategories = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 5, vsync: this); // 5 tab'e çıkardık
    _loadAnalyticsData();
    
    ever(homeController.allTransactions, (transactions) {
      if (mounted) {
        _loadAnalyticsData();
      }
    });
    
    homeController.addListener(() {
      if (mounted) {
        _loadAnalyticsData();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _loadAnalyticsData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _loadAnalyticsData();
    }
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    try {
      if (homeController.allTransactions.isNotEmpty) {
        allTransactions = homeController.allTransactions.toList();
        print('DEBUG Analytics - Loaded from controller: ${allTransactions.length} transactions');
      } else {
        allTransactions = await _transactionService.getAllTransactions();
        print('DEBUG Analytics - Loaded from service: ${allTransactions.length} transactions');
      }
      
      allCategories = await _transactionService.getAllCategories();
      print('DEBUG Analytics - Loaded ${allCategories.length} categories');
      
      if (homeController.isDataStale) {
        homeController.forceRefreshAnalytics();
      }
      
    } catch (e) {
      print('Analytics data loading error: $e');
      if (mounted) {
        Get.snackbar('Hata', 'Analiz verileri yüklenirken hata oluştu');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<TransactionModel> get filteredTransactions {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (selectedPeriod) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'monthly':
      default:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }
    
    return allTransactions.where((transaction) {
      return transaction.date.isAfter(startDate.subtract(Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Analiz',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: _loadAnalyticsData,
            tooltip: 'Verileri Yenile',
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white : Colors.black87,
            ),
            color: isDark ? Color(0xFF2C2C2C) : Colors.white,
            onSelected: (String period) {
              setState(() {
                selectedPeriod = period;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'daily',
                child: Row(
                  children: [
                    Icon(Icons.today, color: theme.primaryColor),
                    SizedBox(width: 8),
                    Text('Günlük', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'weekly',
                child: Row(
                  children: [
                    Icon(Icons.view_week, color: theme.primaryColor),
                    SizedBox(width: 8),
                    Text('Haftalık', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: theme.primaryColor),
                    SizedBox(width: 8),
                    Text('Aylık', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: isDark ? Color(0xFF1E1E1E) : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.primaryColor,
              labelColor: theme.primaryColor,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              isScrollable: true,
              tabs: [
                Tab(text: 'Özet'),
                Tab(text: 'Kategoriler'),
                Tab(text: 'Trend'),
                Tab(text: 'Alışkanlıklar'),
                Tab(text: 'Öneriler'),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Veriler yükleniyor...',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAnalyticsData,
              color: theme.primaryColor,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(isDark, theme),
                  _buildCategoriesTab(isDark, theme),
                  _buildTrendTab(isDark, theme),
                  _buildHabitsTab(isDark, theme),
                  _buildRecommendationsTab(isDark, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryTab(bool isDark, ThemeData theme) {
    final transactions = filteredTransactions;
    final totalIncome = filteredTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount.toDouble());
    final totalExpense = transactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;
    
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodHeader(isDark, theme),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Gelir',
                  Helpers.formatCurrency(totalIncome),
                  Colors.green,
                  Icons.trending_up,
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Gider',
                  Helpers.formatCurrency(totalExpense),
                  Colors.red,
                  Icons.trending_down,
                  isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildSummaryCard(
            'Net Bakiye',
            Helpers.formatCurrency(balance),
            balance >= 0 ? Colors.green : Colors.red,
            balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
            isDark,
            isFullWidth: true,
          ),
          SizedBox(height: 24),
          _buildTopCategoriesSection(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodHeader(isDark, theme),
          SizedBox(height: 16),
          _buildChartTypeSelector(isDark, theme),
          SizedBox(height: 24),
          Container(
            height: 250,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildCategoryChart(),
          ),
          SizedBox(height: 16),
          // Sadece balance negatif veya sıfır ise kategori detaylarını göster
          if (currentBalance <= 0.0)
            _buildCategoryLegend(isDark, theme),
          if (currentBalance > 0.0)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.celebration, size: 48, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Tebrikler! 🎉',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bu dönemde ${Helpers.formatCurrency(currentBalance)} tasarruf ettiniz.\nÖneriler sekmesinden bu tasarrufları nasıl değerlendirebileceğinizi öğrenin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodHeader(isDark, theme),
          SizedBox(height: 24),
          Container(
            height: 300,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildTrendChart(),
          ),
          SizedBox(height: 24),
          _buildTransactionStats(isDark, theme),
        ],
      ),
    );
  }
  Widget _buildPositiveHabitsSection(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Başarılı Mali Alışkanlıklar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildPositiveHabitItem(
            'Disiplinli Harcama',
            'Gelirinizi aşmadan harcama yapıyorsunuz. Bu harika bir alışkanlık!',
            Icons.check_circle,
            Colors.green,
            isDark,
          ),
          _buildPositiveHabitItem(
            'Tasarruf Etme',
            '${Helpers.formatCurrency(currentBalance)} tasarruf ettiniz. Bu parayı değerlendirmeyi unutmayın.',
            Icons.savings,
            Colors.blue,
            isDark,
          ),
          _buildPositiveHabitItem(
            'Mali Farkındalık',
            'Harcamalarınızı takip ediyorsunuz. Bu mali sağlığınız için çok önemli.',
            Icons.visibility,
            Colors.purple,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPositiveHabitItem(String title, String description, IconData icon, Color color, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHabitsTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodHeader(isDark, theme),
          SizedBox(height: 16),
          if (currentBalance <= 0.0) ...[
            _buildSpendingPatternsSection(isDark, theme),
            SizedBox(height: 16),
          ],
          _buildFrequencyAnalysisSection(isDark, theme),
          SizedBox(height: 16),
          _buildBudgetComparisonSection(isDark, theme),
          if (currentBalance > 0.0) ...[
            SizedBox(height: 16),
            _buildPositiveHabitsSection(isDark, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodHeader(isDark, theme),
          SizedBox(height: 16),
          _buildSmartRecommendations(isDark, theme),
          SizedBox(height: 16),
          _buildSavingsOpportunities(isDark, theme),
          SizedBox(height: 16),
          _buildBudgetSuggestions(isDark, theme),
          SizedBox(height: 16),
          _buildGoalsSection(isDark, theme),
        ],
      ),
    );
  }

  Widget _buildSpendingPatternsSection(bool isDark, ThemeData theme) {
    final patterns = _analyzeSpendingPatterns();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pattern, color: theme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Harcama Kalıpları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...patterns.map((pattern) => _buildPatternItem(pattern, isDark)),
        ],
      ),
    );
  }

  Widget _buildFrequencyAnalysisSection(bool isDark, ThemeData theme) {
    final frequency = _analyzeTransactionFrequency();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: theme.primaryColor),
              SizedBox(width: 8),
              Text(
                'İşlem Sıklığı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFrequencyCard('Günlük Ortalama', '${frequency['daily'].toStringAsFixed(1)}', Icons.today, Colors.blue, isDark),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFrequencyCard('Haftalık Ortalama', '${frequency['weekly'].toStringAsFixed(1)}', Icons.view_week, Colors.green, isDark),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildFrequencyCard('En Aktif Gün', frequency['mostActiveDay'], Icons.calendar_today, Colors.orange, isDark, isFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildBudgetComparisonSection(bool isDark, ThemeData theme) {
    final budgetData = _calculateBudgetComparison();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: theme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Bütçe Performansı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: budgetData['percentage'] / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              budgetData['percentage'] > 100.0 ? Colors.red : 
              budgetData['percentage'] > 80.0 ? Colors.orange : Colors.green,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harcanan: ${Helpers.formatCurrency(budgetData['spent'])}',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              Text(
                'Bütçe: ${Helpers.formatCurrency(budgetData['budget'])}',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            budgetData['message'],
            style: TextStyle(
              color: budgetData['percentage'] > 100.0 ? Colors.red : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendations(bool isDark, ThemeData theme) {
    final recommendations = _generateSmartRecommendations();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Akıllı Öneriler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...recommendations.map((rec) => _buildRecommendationCard(rec, isDark)),
        ],
      ),
    );
  }

  Widget _buildSavingsOpportunities(bool isDark, ThemeData theme) {
    final opportunities = _findSavingsOpportunities();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Tasarruf Fırsatları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...opportunities.map((opp) => _buildOpportunityCard(opp, isDark)),
        ],
      ),
    );
  }

  Widget _buildBudgetSuggestions(bool isDark, ThemeData theme) {
    final suggestions = _generateBudgetSuggestions();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: theme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Bütçe Önerileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...suggestions.map((sug) => _buildBudgetSuggestionCard(sug, isDark, theme)),
        ],
      ),
    );
  }

  // YENİ: Hedefler Bölümü
  Widget _buildGoalsSection(bool isDark, ThemeData theme) {
    final goals = _calculateFinancialGoals();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Mali Hedefler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...goals.map((goal) => _buildGoalCard(goal, isDark)),
        ],
      ),
    );
  }

  
  List<Map<String, dynamic>> _analyzeSpendingPatterns() {
    final transactions = filteredTransactions.where((t) => t.type == 'expense').toList();
    final categoryAmounts = _getCategoryAmounts(transactions);
    final totalExpense = transactions.fold(0.0, (sum, t) => sum + t.amount);
    
    List<Map<String, dynamic>> patterns = [];
    
    categoryAmounts.forEach((category, amount) {
      final percentage = (amount / totalExpense) * 100.0;
      String pattern = '';
      Color color = Colors.blue;
      IconData icon = Icons.info;
      
      if (percentage > 40.0) {
        pattern = 'Bu kategoride çok yüksek harcama yapıyorsunuz (%${percentage.toStringAsFixed(1)})';
        color = Colors.red;
        icon = Icons.warning;
      } else if (percentage > 25.0) {
        pattern = 'Bu kategori bütçenizin büyük kısmını oluşturuyor (%${percentage.toStringAsFixed(1)})';
        color = Colors.orange;
        icon = Icons.priority_high;
      } else if (percentage > 15.0) {
        pattern = 'Dengeli harcama yapıyorsunuz (%${percentage.toStringAsFixed(1)})';
        color = Colors.green;
        icon = Icons.check_circle;
      } else {
        pattern = 'Bu kategoride düşük harcama yapıyorsunuz (%${percentage.toStringAsFixed(1)})';
        color = Colors.blue;
        icon = Icons.info;
      }
      
      patterns.add({
        'category': category,
        'pattern': pattern,
        'color': color,
        'icon': icon,
        'amount': amount,
      });
    });
    
    return patterns.take(5).toList();
  }
  
  Map<String, dynamic> _analyzeTransactionFrequency() {
    final transactions = filteredTransactions;
    final days = selectedPeriod == 'daily' ? 1 : selectedPeriod == 'weekly' ? 7 : 30;
    
    final dailyAvg = transactions.length / days;
    final weeklyAvg = transactions.length / (days / 7.0);
    
    Map<String, int> dayCount = {
      'Pazartesi': 0, 'Salı': 0, 'Çarşamba': 0, 'Perşembe': 0, 
      'Cuma': 0, 'Cumartesi': 0, 'Pazar': 0
    };
    
    List<String> dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    
    for (var transaction in transactions) {
      final dayName = dayNames[transaction.date.weekday - 1];
      dayCount[dayName] = (dayCount[dayName] ?? 0) + 1;
    }
    
    String mostActiveDay = dayCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    return {
      'daily': dailyAvg,
      'weekly': weeklyAvg,
      'mostActiveDay': mostActiveDay,
      'dayCount': dayCount,
    };
  }
  
  Map<String, dynamic> _calculateBudgetComparison() {
    final expenses = filteredTransactions.where((t) => t.type == 'expense');
    final totalSpent = expenses.fold(0.0, (sum, t) => sum + t.amount);
    
    final income = filteredTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final suggestedBudget = income * 0.7;
    
    final percentage = suggestedBudget > 0.0 ? (totalSpent / suggestedBudget) * 100.0 : 0.0;
    
    String message = '';
    if (percentage > 100.0) {
      message = 'Bütçenizi %${(percentage - 100.0).toStringAsFixed(1)} aştınız!';
    } else if (percentage > 80.0) {
      message = 'Bütçenizin %${percentage.toStringAsFixed(1)}\'ini kullandınız. Dikkatli olun!';
    } else {
      message = 'Bütçe kontrolünüz iyi! %${(100.0 - percentage).toStringAsFixed(1)} tasarruf ettiniz.';
    }
    
    return {
      'spent': totalSpent,
      'budget': suggestedBudget,
      'percentage': percentage,
      'message': message,
    };
  }
  
  List<Map<String, dynamic>> _generateSmartRecommendations() {
    List<Map<String, dynamic>> recommendations = [];
    final transactions = filteredTransactions;
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    
    if (currentBalance > 0.0) {
      recommendations.add({
        'title': 'Mükemmel Mali Durum! 💰',
        'description': 'Bu dönemde ${Helpers.formatCurrency(currentBalance)} tasarruf ettiniz. Bu parayı yatırım için değerlendirin.',
        'potential_saving': 0.0,
        'priority': 'high',
        'icon': Icons.trending_up,
        'color': Colors.green,
      });
      
      recommendations.add({
        'title': 'Yatırım Fırsatı',
        'description': 'Tasarruflarınızı değerlendirmek için yatırım araçlarını araştırın. BES, hisse senedi veya altın gibi seçenekleri inceleyin.',
        'potential_saving': 0.0,
        'priority': 'medium',
        'icon': Icons.show_chart,
        'color': Colors.blue,
      });
      
      recommendations.add({
        'title': 'Acil Durum Fonu',
        'description': 'Tasarrufunuzun bir kısmını acil durum fonu olarak ayırın. Bu sizin güvenlik ağınız olacak.',
        'potential_saving': 0.0,
        'priority': 'medium',
        'icon': Icons.security,
        'color': Colors.orange,
      });
      
      return recommendations;
    }
    
    final categoryAmounts = _getCategoryAmounts(expenses);
    if (categoryAmounts.isNotEmpty) {
      final highestCategory = categoryAmounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (highestCategory.value > 1000.0) {
        recommendations.add({
          'title': '${highestCategory.key} Harcamalarınız Yüksek',
          'description': 'Bu kategoride ${Helpers.formatCurrency(highestCategory.value)} harcadınız. %15 azaltmayı hedefleyin.',
          'potential_saving': highestCategory.value * 0.15,
          'priority': 'high',
          'icon': Icons.trending_down,
          'color': Colors.red,
        });
      }
    }
    
    final smallTransactions = expenses.where((t) => t.amount < 50.0).toList();
    if (smallTransactions.length > 10.0) {
      final smallTotal = smallTransactions.fold(0.0, (sum, t) => sum + t.amount);
      recommendations.add({
        'title': 'Küçük Harcamalarınız Birikiyor',
        'description': '${smallTransactions.length} adet küçük harcama toplam ${Helpers.formatCurrency(smallTotal)} tutuyor.',
        'potential_saving': smallTotal * 0.3,
        'priority': 'medium',
        'icon': Icons.coffee,
        'color': Colors.orange,
      });
    }
    
    if (_hasIrregularSpending()) {
      recommendations.add({
        'title': 'Harcama Düzeninizi İyileştirin',
        'description': 'Günlük harcamalarınızda büyük dalgalanmalar var. Düzenli bütçe planı oluşturun.',
        'potential_saving': 0.0,
        'priority': 'medium',
        'icon': Icons.schedule,
        'color': Colors.blue,
      });
    }
    
    return recommendations;
  }

  
  List<Map<String, dynamic>> _findSavingsOpportunities() {
    List<Map<String, dynamic>> opportunities = [];
    
    if (currentBalance > 0) {
      opportunities.add({
        'title': 'Yatırım Diversifikasyonu',
        'description': 'Riskinizi dağıtmak için farklı yatırım araçlarını değerlendirin. Portföyünüzü çeşitlendirin.',
        'potential_saving': currentBalance * 0.1, // Potansiyel getiri
        'category': 'Yatırım',
        'icon': Icons.account_balance,
        'color': Colors.green,
      });
      
      opportunities.add({
        'title': 'Uzun Vadeli Hedefler',
        'description': 'Ev almak, araba değiştirmek gibi büyük hedefler için tasarruf planı oluşturun.',
        'potential_saving': 0.0,
        'category': 'Hedef',
        'icon': Icons.home,
        'color': Colors.blue,
      });
      
      opportunities.add({
        'title': 'Eğitim & Gelişim',
        'description': 'Kendinizi geliştirmek için kurs, sertifika programları için bütçe ayırın.',
        'potential_saving': 0.0,
        'category': 'Eğitim',
        'icon': Icons.school,
        'color': Colors.purple,
      });
      
      return opportunities;
    }
    
    final transactions = filteredTransactions;
    final categoryAmounts = _getCategoryAmounts(transactions.where((t) => t.type == 'expense').toList());
    
    final recurringCategories = ['Abonelik', 'Fatura', 'Sigorta'];
    categoryAmounts.forEach((category, amount) {
      if (recurringCategories.any((rec) => category.toLowerCase().contains(rec.toLowerCase()))) {
        opportunities.add({
          'title': '$category Gözden Geçirin',
          'description': 'Aylık ${Helpers.formatCurrency(amount)} harcıyorsunuz. Kullanmadığınız servisleri iptal edin.',
          'potential_saving': amount * 0.2,
          'category': category,
          'icon': Icons.subscriptions,
          'color': Colors.purple,
        });
      }
    });
    
    final foodAmount = categoryAmounts['Yemek'] ?? 0.0;
    if (foodAmount > 500.0) {
      opportunities.add({
        'title': 'Yemek Harcamalarını Optimize Edin',
        'description': 'Ev yemegi pişirerek aylık ${Helpers.formatCurrency(foodAmount * 0.3)} tasarruf edebilirsiniz.',
        'potential_saving': foodAmount * 0.3,
        'category': 'Yemek',
        'icon': Icons.restaurant,
        'color': Colors.green,
      });
    }
    
    final transportAmount = categoryAmounts['Ulaşım'] ?? 0.0;
    if (transportAmount > 300.0) {
      opportunities.add({
        'title': 'Ulaşım Alternatifleri',
        'description': 'Toplu taşıma veya bisiklet kullanarak aylık ${Helpers.formatCurrency(transportAmount * 0.25)} tasarruf edin.',
        'potential_saving': transportAmount * 0.25,
        'category': 'Ulaşım',
        'icon': Icons.directions_bus,
        'color': Colors.blue,
      });
    }
    
    return opportunities;
  }
  
  List<Map<String, dynamic>> _generateBudgetSuggestions() {
    List<Map<String, dynamic>> suggestions = [];
    final totalIncome = filteredTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount.toDouble());
    final totalExpenses = filteredTransactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount.toDouble());
    
    if (totalIncome > 0.0) {
      // 50/30/20 kuralı önerisi
      suggestions.add({
        'title': '50/30/20 Kuralını Uygulayın',
        'description': 'Gelirin %50\'si ihtiyaçlar, %30\'u istekler, %20\'si tasarruf için ayrılmalı.',
        'needs_budget': totalIncome * 0.5,
        'wants_budget': totalIncome * 0.3,
        'savings_budget': totalIncome * 0.2,
        'type': 'rule',
      });
      
      final categoryAmounts = _getCategoryAmounts(filteredTransactions.where((t) => t.type == 'expense').toList());
      categoryAmounts.forEach((category, amount) {
        final percentage = (amount / totalIncome) * 100.0;
        final suggestedPercentage = _getSuggestedCategoryPercentage(category);
        
        if (percentage > suggestedPercentage) {
          suggestions.add({
            'title': '$category Bütçesi Yüksek',
            'description': 'Bu kategori için gelirin %${percentage.toStringAsFixed(1)}\'ini harcıyorsunuz. Önerilen: %$suggestedPercentage',
            'current': amount,
            'suggested': totalIncome * (suggestedPercentage / 100.0),
            'category': category,
            'type': 'category',
          });
        }
      });
    }
    
    return suggestions;
  }
  
  List<Map<String, dynamic>> _calculateFinancialGoals() {
    List<Map<String, dynamic>> goals = [];
    final monthlyIncome = filteredTransactions.where((t) => t.type == 'income').fold(0.0, (sum, t) => sum + t.amount);
    final monthlyExpenses = filteredTransactions.where((t) => t.type == 'expense').fold(0.0, (sum, t) => sum + t.amount);
    final monthlySavings = monthlyIncome - monthlyExpenses;
    
    // Acil durum fonu
    goals.add({
      'title': 'Acil Durum Fonu',
      'description': '6 aylık harcama tutarı kadar acil durum fonu oluşturun.',
      'target_amount': monthlyExpenses * 6.0,
      'monthly_contribution': monthlySavings * 0.3,
      'months_to_complete': monthlySavings > 0.0 ? ((monthlyExpenses * 6.0) / (monthlySavings * 0.3)).ceil() : 0.0,
      'priority': 'high',
      'icon': Icons.security,
      'color': Colors.red,
    });
    
    goals.add({
      'title': 'Emeklilik Fonu',
      'description': 'Gelirin %10-15\'ini emeklilik için ayırın.',
      'target_amount': monthlyIncome * 0.15 * 12 * 30, // 30 yıl
      'monthly_contribution': monthlyIncome * 0.15,
      'months_to_complete': 30.0 * 12.0,
      'priority': 'medium',
      'icon': Icons.elderly,
      'color': Colors.blue,
    });
    
    if (monthlySavings > 0.0) {
      goals.add({
        'title': 'Tatil Fonu',
        'description': 'Yılda bir güzel tatil için para biriktirin.',
        'target_amount': 5000.0,
        'monthly_contribution': monthlySavings * 0.2,
        'months_to_complete': (5000.0 / (monthlySavings * 0.2)).ceil(),
        'priority': 'low',
        'icon': Icons.beach_access,
        'color': Colors.orange,
      });
    }
    
    return goals;
  }
  
  
  Widget _buildPatternItem(Map<String, dynamic> pattern, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: pattern['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pattern['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(pattern['icon'], color: pattern['color'], size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern['category'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  pattern['pattern'],
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Helpers.formatCurrency(pattern['amount']),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: pattern['color'],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFrequencyCard(String title, String value, IconData icon, Color color, bool isDark, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationCard(Map<String, dynamic> rec, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: rec['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rec['color'].withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(rec['icon'], color: rec['color'], size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  rec['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ),
              if (rec['priority'] == 'high')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Öncelikli',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            rec['description'],
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          if (rec['potential_saving'] > 0) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.savings, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Potansiyel tasarruf: ${Helpers.formatCurrency(rec['potential_saving'])}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildOpportunityCard(Map<String, dynamic> opp, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: opp['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: opp['color'].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: opp['color'].withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(opp['icon'], color: opp['color'], size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opp['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  opp['description'],
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                if (opp['potential_saving'] > 0) ...[
                  SizedBox(height: 6),
                  Text(
                    '💰 ${Helpers.formatCurrency(opp['potential_saving'])} tasarruf',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetSuggestionCard(Map<String, dynamic> sug, bool isDark, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2C2C2C) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sug['title'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            sug['description'],
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          if (sug['type'] == 'rule') ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetRuleItem('İhtiyaçlar', '50%', Helpers.formatCurrency(sug['needs_budget']), Colors.red, isDark),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildBudgetRuleItem('İstekler', '30%', Helpers.formatCurrency(sug['wants_budget']), Colors.orange, isDark),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildBudgetRuleItem('Tasarruf', '20%', Helpers.formatCurrency(sug['savings_budget']), Colors.green, isDark),
                ),
              ],
            ),
          ] else if (sug['type'] == 'category') ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mevcut:', style: TextStyle(color: Colors.red, fontSize: 12)),
                    Text(Helpers.formatCurrency(sug['current']), style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.arrow_forward, color: theme.primaryColor),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Önerilen:', style: TextStyle(color: Colors.green, fontSize: 12)),
                    Text(Helpers.formatCurrency(sug['suggested']), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBudgetRuleItem(String label, String percentage, String amount, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            percentage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalCard(Map<String, dynamic> goal, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goal['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goal['color'].withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(goal['icon'], color: goal['color'], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                  ),
                ),
              ),
              if (goal['priority'] == 'high')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Acil',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            goal['description'],
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hedef Tutar:', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                    Text(Helpers.formatCurrency(goal['target_amount']), style: TextStyle(fontWeight: FontWeight.bold, color: goal['color'])),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aylık Katkı:', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                    Text(Helpers.formatCurrency(goal['monthly_contribution']), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Süre:', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
                    Text('${goal['months_to_complete']} ay', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.1, // Bu değer gerçek veriye göre hesaplanabilir
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(goal['color']),
          ),
        ],
      ),
    );
  }
  
  
  bool _hasIrregularSpending() {
    final expenses = filteredTransactions.where((t) => t.type == 'expense').toList();
    if (expenses.length < 5) return false;
    
    Map<DateTime, double> dailyExpenses = {};
    for (var expense in expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyExpenses[date] = (dailyExpenses[date] ?? 0.0) + expense.amount;
    }
    
    if (dailyExpenses.length < 3) return false;
    
    final amounts = dailyExpenses.values.toList();
    final average = amounts.reduce((a, b) => a + b) / amounts.length;
    
    final variance = amounts.map((amount) => (amount - average) * (amount - average)).reduce((a, b) => a + b) / amounts.length;
    final standardDeviation = variance > 0.0 ? math.sqrt(variance) : 0.0;
    
    return standardDeviation > (average * 0.7);
  }
  
  double _getSuggestedCategoryPercentage(String category) {

    switch (category.toLowerCase()) {
      case 'yemek':
      case 'market':
        return 15.0;
      case 'ulaşım':
        return 10.0;
      case 'kira':
      case 'ev':
        return 30.0;
      case 'sağlık':
        return 5.0;
      case 'eğlence':
        return 10.0;
      case 'kıyafet':
        return 5.0;
      case 'fatura':
        return 10.0;
      default:
        return 8.0;
    }
  }

  Widget _buildPeriodHeader(bool isDark, ThemeData theme) {
    String periodText = '';
    String dateText = '';
    final now = DateTime.now();
    
    switch (selectedPeriod) {
      case 'daily':
        periodText = 'Günlük Analiz';
        dateText = Helpers.formatDate(now);
        break;
      case 'weekly':
        periodText = 'Haftalık Analiz';
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        dateText = '${Helpers.formatDateShort(startOfWeek)} - ${Helpers.formatDateShort(endOfWeek)}';
        break;
      case 'monthly':
        periodText = 'Aylık Analiz';
        dateText = '${_getMonthName(now.month)} ${now.year}';
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withOpacity(0.8), theme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            dateText,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon, bool isDark, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: isFullWidth ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTypeSelector(bool isDark, ThemeData theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildChartTypeButton('pie', 'Pasta', isDark, theme),
          _buildChartTypeButton('doughnut', 'Halka', isDark, theme),
          _buildChartTypeButton('bar', 'Çubuk', isDark, theme),
        ],
      ),
    );
  }

  Widget _buildChartTypeButton(String type, String label, bool isDark, ThemeData theme) {
    final isSelected = selectedChartType == type;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedChartType = type),
        child: Container(
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart() {
    final expenseTransactions = filteredTransactions.where((t) => t.type == 'expense').toList();
    
    if (expenseTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Bu dönemde gider yok', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    switch (selectedChartType) {
      case 'doughnut':
        return _buildDoughnutChart(expenseTransactions);
      case 'bar':
        return _buildBarChart(expenseTransactions);
      case 'pie':
      default:
        return _buildPieChart(expenseTransactions);
    }
  }

  Widget _buildPieChart(List<TransactionModel> transactions) {
    final categoryData = _getCategoryData(transactions);
    final colors = _getChartColors();
    
    return PieChart(
      PieChartData(
        sections: categoryData.entries.map((entry) {
          final index = categoryData.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: '${entry.value.toStringAsFixed(0)}%',
            titleStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            radius: 100,
          );
        }).toList(),
        centerSpaceRadius: 0,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildDoughnutChart(List<TransactionModel> transactions) {
    final categoryData = _getCategoryData(transactions);
    final colors = _getChartColors();
    
    return PieChart(
      PieChartData(
        sections: categoryData.entries.map((entry) {
          final index = categoryData.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: '${entry.value.toStringAsFixed(0)}%',
            titleStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            radius: 50,
          );
        }).toList(),
        centerSpaceRadius: 60,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildBarChart(List<TransactionModel> transactions) {
    final categoryAmounts = _getCategoryAmounts(transactions);
    final colors = _getChartColors();
    
    if (categoryAmounts.isEmpty) {
      return Center(child: Text('Veri yok'));
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: categoryAmounts.values.reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final categories = categoryAmounts.keys.toList();
                if (value.toInt() < categories.length) {
                  final categoryName = categories[value.toInt()];
                  final category = _findCategoryByName(categoryName);
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      category?.icon ?? '📊',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: categoryAmounts.entries.map((entry) {
          final index = categoryAmounts.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: colors[index % colors.length],
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendChart() {
    final trendData = _getTrendData();
    
    if (trendData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text('Bu dönemde veri yok', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    color: Colors.green,
                  ),
                  SizedBox(width: 6),
                  Text('Gelir', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    color: Colors.red,
                  ),
                  SizedBox(width: 6),
                  Text('Gider', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final days = trendData.keys.toList();
                      if (value.toInt() < days.length) {
                        final day = days[value.toInt()];
                        return Text(
                          '${day.day}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        );
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: trendData.entries.map((entry) {
                    final index = trendData.keys.toList().indexOf(entry.key);
                    return FlSpot(index.toDouble(), entry.value['income'] ?? 0.0);
                  }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
                LineChartBarData(
                  spots: trendData.entries.map((entry) {
                    final index = trendData.keys.toList().indexOf(entry.key);
                    return FlSpot(index.toDouble(), entry.value['expense'] ?? 0.0);
                  }).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.red.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryLegend(bool isDark, ThemeData theme) {
    final expenseTransactions = filteredTransactions.where((t) => t.type == 'expense').toList();
    final categoryAmounts = _getCategoryAmounts(expenseTransactions);
    final colors = _getChartColors();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Detayları',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          ...categoryAmounts.entries.map((entry) {
            final index = categoryAmounts.keys.toList().indexOf(entry.key);
            final category = _findCategoryByName(entry.key);
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(category?.icon ?? '📊', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(entry.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSection(bool isDark, ThemeData theme) {
    final expenseTransactions = filteredTransactions.where((t) => t.type == 'expense').toList();
    final categoryAmounts = _getCategoryAmounts(expenseTransactions);
    final sortedCategories = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).toList();
    
    if (topCategories.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Bu dönemde gider kategorisi yok',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'En Çok Harcama Yapılan Kategoriler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          ...topCategories.asMap().entries.map((entry) {
            final index = entry.key;
            final categoryEntry = entry.value;
            final category = _findCategoryByName(categoryEntry.key);
            final colors = [Colors.amber, Colors.orange, Colors.deepOrange];
            
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors[index].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors[index].withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(category?.icon ?? '📊', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryEntry.key,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(categoryEntry.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors[index],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTransactionStats(bool isDark, ThemeData theme) {
    final transactions = filteredTransactions;
    final expenseCount = transactions.where((t) => t.type == 'expense').length;
    final incomeCount = transactions.where((t) => t.type == 'income').length;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İşlem İstatistikleri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Toplam İşlem', '${transactions.length}', Icons.receipt_long, theme.primaryColor, isDark),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem('Gelir İşlemi', '$incomeCount', Icons.trending_up, Colors.green, isDark),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem('Gider İşlemi', '$expenseCount', Icons.trending_down, Colors.red, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, double> _getCategoryData(List<TransactionModel> transactions) {
    final Map<String, double> categoryTotals = {};
    double totalAmount = 0.0;

    for (var transaction in transactions) {
      final categoryName = _findCategoryById(transaction.categoryId ?? '')?.name ?? 'Diğer';
      
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0.0) + transaction.amount;
      totalAmount += transaction.amount;
    }

    final Map<String, double> categoryPercentages = {};
    categoryTotals.forEach((category, amount) {
      categoryPercentages[category] = totalAmount > 0.0 ? (amount / totalAmount) * 100.0 : 0.0;
    });

    return categoryPercentages;
  }

  Map<String, double> _getCategoryAmounts(List<TransactionModel> transactions) {
    final Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      final categoryName = _findCategoryById(transaction.categoryId ?? '')?.name ?? 'Diğer';
      
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + transaction.amount;
    }

    return categoryTotals;
  }

  Map<DateTime, Map<String, double>> _getTrendData() {
    final Map<DateTime, Map<String, double>> dailyTotals = {};
    final now = DateTime.now();
    DateTime startDate;
    int days;
    
    switch (selectedPeriod) {
      case 'daily':
        days = 7;
        startDate = now.subtract(Duration(days: days - 1));
        break;
      case 'weekly':
        days = 28;
        startDate = now.subtract(Duration(days: days - 1));
        break;
      case 'monthly':
      default:
        days = 30;
        startDate = now.subtract(Duration(days: days - 1));
        break;
    }

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      dailyTotals[dateKey] = {
        'income': 0.0,
        'expense': 0.0,
      };
    }

    for (var transaction in filteredTransactions) {
      final dateKey = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      if (dailyTotals.containsKey(dateKey)) {
        if (transaction.type == 'income') {
          dailyTotals[dateKey]!['income'] = (dailyTotals[dateKey]!['income'] ?? 0.0) + transaction.amount.toDouble();
        } else if (transaction.type == 'expense') {
          dailyTotals[dateKey]!['expense'] = (dailyTotals[dateKey]!['expense'] ?? 0.0) + transaction.amount.toDouble();
        }
      }
    }

    return dailyTotals;
  }

  List<Color> _getChartColors() {
    return [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  CategoryModel? _findCategoryById(String categoryId) {
    try {
      return allCategories.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  CategoryModel? _findCategoryByName(String categoryName) {
    try {
      return allCategories.firstWhere((c) => c.name == categoryName);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }
}