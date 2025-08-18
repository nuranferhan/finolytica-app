import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/investment_controller.dart';
import '../../core/theme.dart';
import '../../models/savings_goal.dart';
import '../../models/watchlist.dart';
import '../../core/supabase.dart';

class InvestmentsScreen extends StatefulWidget {
  @override
  _InvestmentsScreenState createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen>
    with TickerProviderStateMixin {
  final InvestmentController controller = Get.put(InvestmentController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        controller.changeTabIndex(_tabController.index);
      }
    });
    
    if (controller.selectedTabIndex.value != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(controller.selectedTabIndex.value);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Yatırım'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          Obx(() => IconButton(
            onPressed: controller.isUpdatingRates.value 
                ? null 
                : controller.updateWatchlistPrices,
            icon: controller.isUpdatingRates.value
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh),
            tooltip: 'Fiyatları  Güncelle',
          )),
          PopupMenuButton<String>(
    onSelected: (value) {
      switch (value) {
        case 'add_popular_forex':
          controller.addDefaultWatchlistItems();
          break;
        case 'add_popular_stocks':
          controller.addPopularStocks();
          break;
        case 'add_popular_crypto':
          controller.addPopularCryptos();
          break;
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem(
        value: 'add_popular_forex',
        child: Row(
          children: [
            Icon(Icons.currency_exchange, size: 20),
            SizedBox(width: 8),
            Text('Popüler Dövizler Ekle'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'add_popular_stocks',
        child: Row(
          children: [
            Icon(Icons.trending_up, size: 20),
            SizedBox(width: 8),
            Text('Popüler Hisseler Ekle'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'add_popular_crypto',
        child: Row(
          children: [
            Icon(Icons.currency_bitcoin, size: 20),
            SizedBox(width: 8),
            Text('Popüler Kriptolar Ekle'),
          ],
        ),
      ),
    ],
  ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: controller.changeTabIndex,
          tabs: [
            Tab(text: 'Tasarruf Hedefleri'),
            Tab(text: 'Döviz Takibi'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildSavingsGoalsTab(context),
            _buildWatchlistTab(context),
          ],
        );
      }),
      floatingActionButton: Obx(() => FloatingActionButton(
        onPressed: () => controller.selectedTabIndex.value == 0
            ? _showAddGoalDialog(context)
            : _showAddWatchlistDialog(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: controller.selectedTabIndex.value == 0 
            ? 'Hedef Ekle' 
            : 'İzleme Listesine Ekle',
      )),
    );
  }

  Widget _buildSavingsGoalsTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.loadSavingsGoals,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalsSummaryCard(context),
            SizedBox(height: 24),

            Text(
              'Hedefleriniz',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Obx(() {
              if (controller.savingsGoals.isEmpty) {
                return _buildEmptyGoalsState(context);
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.savingsGoals.length,
                itemBuilder: (context, index) {
                  return _buildGoalCard(context, controller.savingsGoals[index]);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

Widget _buildGoalsSummaryCard(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.indigo, Colors.purple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.indigo.withOpacity(0.3),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Obx(() => Column(  // BU ÖNEMLİ: Obx ile sar
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hedefler Özeti',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₺${NumberFormat('#,##0.00').format(controller.totalGoalsCurrent.value)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Biriken Tutar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.completedGoals.value}/${controller.totalGoals.value}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Tamamlanan',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        LinearProgressIndicator(
          value: controller.goalsProgress.value / 100,
          backgroundColor: Colors.white24,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          '%${controller.goalsProgress.value.toStringAsFixed(1)} tamamlandı',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    )),
  );
}

  Widget _buildGoalCard(BuildContext context, SavingsGoal goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                goal.categoryIcon,
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (goal.description != null)
                      Text(
                        goal.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'add') {
                    _showAddToGoalDialog(context, goal);
                  } else if (value == 'delete') {
                    _showDeleteGoalDialog(context, goal);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, size: 20),
                        SizedBox(width: 8),
                        Text('Para Ekle'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sil', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Progress bar
          LinearProgressIndicator(
            value: goal.progressPercentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              goal.isCompleted ? Colors.green : AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₺${NumberFormat('#,##0.00').format(goal.currentAmount)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₺${NumberFormat('#,##0.00').format(goal.targetAmount)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 4),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '%${goal.progressPercentage.toStringAsFixed(1)}',
                style: TextStyle(
                  color: goal.isCompleted ? Colors.green : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (goal.targetDate != null)
                Text(
                  'Hedef: ${DateFormat('dd/MM/yyyy').format(goal.targetDate!)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          
          if (goal.dailyTarget != null && !goal.isCompleted)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Günlük hedef: ₺${goal.dailyTarget!.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40),
          Icon(Icons.savings, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Henüz tasarruf hedefi yok',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'İlk hedefi oluştur ve tasarruf yapmaya başla!',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildWatchlistTab(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.updateExchangeRates,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExchangeSummaryCard(context),
            SizedBox(height: 24),

            Text(
              'İzleme Listesi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            Obx(() {
              if (controller.watchlist.isEmpty) {
                return _buildEmptyWatchlistState(context);
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.watchlist.length,
                itemBuilder: (context, index) {
                  return _buildWatchlistCard(context, controller.watchlist[index]);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

Widget _buildExchangeSummaryCard(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.teal, Colors.cyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.teal.withOpacity(0.3),
          blurRadius: 15,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Güncel Kurlar',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.trending_up, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'Piyasa Takibi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Son güncelleme: ${DateFormat('HH:mm').format(DateTime.now())}',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}
  Widget _buildWatchlistCard(BuildContext context, WatchlistItem item) {
    final isPositive = item.changePercentage >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                item.symbolIcon,
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SizedBox(width: 16),
          
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            item.symbol,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getTypeColor(item.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getTypeLabel(item.type),
              style: TextStyle(
                color: _getTypeColor(item.type),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      Text(
        item.name,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    ],
  ),
),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.formattedPrice,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: changeColor,
                      size: 12,
                    ),
                    SizedBox(width: 2),
                    Text(
                      '${item.changePercentage.abs().toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          IconButton(
            onPressed: () => controller.removeFromWatchlist(item.id!, item.name),
            icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
          ),
        ],
      ),
    );
  }

Widget _buildEmptyWatchlistState(BuildContext context) {
  return Center(
    child: Column(
      children: [
        SizedBox(height: 40),
        Icon(Icons.visibility, size: 64, color: Colors.grey[400]),
        SizedBox(height: 16),
        Text(
          'İzleme listesi yükleniyor...',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),),
            SizedBox(height: 8),
            Text('Popüler varlıklar otomatik ekleniyor',style: TextStyle(color: Colors.grey[500]),),
            SizedBox(height: 20),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => controller.addDefaultWatchlistItems(),
              icon: Icon(Icons.currency_exchange, size: 16),
              label: Text('Popüler Dövizler'),
            ),
            ElevatedButton.icon(
              onPressed: () => controller.addPopularStocks(),
              icon: Icon(Icons.trending_up, size: 16),
              label: Text('Popüler Hisseler'),
            ),
            ElevatedButton.icon(
              onPressed: () => controller.addPopularCryptos(),
              icon: Icon(Icons.currency_bitcoin, size: 16),
              label: Text('Popüler Kriptolar'),
            ),
          ],
        ),
      ],
    ),
  );
}


  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'general';
    DateTime? selectedDate;

    Get.dialog(
      AlertDialog(
        title: Text('Yeni Tasarruf Hedefi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Hedef Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (İsteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Hedef Tutar (₺)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: controller.goalCategories.map((category) {
                  return DropdownMenuItem(
                    value: category['key'],
                    child: Row(
                      children: [
                        Text(category['icon']!),
                        SizedBox(width: 8),
                        Text(category['name']!),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 3650)),
                  );
                  if (date != null) selectedDate = date;
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        selectedDate != null 
                            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                            : 'Hedef Tarih (İsteğe bağlı)',
                        style: TextStyle(
                          color: selectedDate != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty || amountController.text.isEmpty) {
                Get.snackbar('Hata', 'Hedef adı ve tutar gerekli');
                return;
              }
              
              controller.addSavingsGoal(
                title: titleController.text,
                description: descriptionController.text.isEmpty 
                    ? null 
                    : descriptionController.text,
                targetAmount: double.parse(amountController.text),
                targetDate: selectedDate,
                category: selectedCategory,
              );
            },
            child: Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showAddToGoalDialog(BuildContext context, SavingsGoal goal) {
      final amountController = TextEditingController();
      final descriptionController = TextEditingController();

      Get.dialog(
        AlertDialog(
          title: Text('Hedefe Para Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${goal.title} hedefine ne kadar eklemek istiyorsun?'),
              SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Tutar (₺)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (İsteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (amountController.text.isEmpty) {
                  Get.snackbar('Hata', 'Tutar gerekli');
                  return;
                }
                
                double? parsedAmount;
                try {
                  parsedAmount = double.parse(amountController.text);
                } catch (e) {
                  Get.snackbar('Hata', 'Geçersiz tutar formatı');
                  return;
                }
                
                if (parsedAmount <= 0) {
                  Get.snackbar('Hata', 'Tutar pozitif olmalı');
                  return;
                }

                if (goal.id == null || goal.id!.isEmpty) {
                  Get.snackbar('Hata', 'Hedef ID bulunamadı');
                  return;
                }
                
                controller.addToGoal(
                  goal.id!,
                  parsedAmount,
                  descriptionController.text.isEmpty 
                      ? 'Para eklendi' 
                      : descriptionController.text,
                );
                Get.back();
              },
              child: Text('Ekle'),
            ),
          ],
        ),
      );
    }

  void _showDeleteGoalDialog(BuildContext context, SavingsGoal goal) {
    Get.dialog(
      AlertDialog(
        title: Text('Hedefi Sil'),
        content: Text('${goal.title} hedefini silmek istediğinden emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSavingsGoal(goal.id!);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

void _showAddWatchlistDialog(BuildContext context) {
  String selectedType = 'forex';
  String? selectedItem;

  Get.dialog(
    StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('İzleme Listesine Ekle'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'forex', label: Text('Döviz')),
                    ButtonSegment(value: 'stock', label: Text('Hisse')),
                    ButtonSegment(value: 'crypto', label: Text('Kripto')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      selectedType = newSelection.first;
                      selectedItem = null; // Reset selection
                    });
                  },
                ),
                SizedBox(height: 16),
                
                if (selectedType == 'forex')
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Döviz Seç',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.popularCurrencies.map((currency) {
                      return DropdownMenuItem(
                        value: currency['symbol'],
                        child: Row(
                          children: [
                            Text(currency['symbol']!),
                            SizedBox(width: 8),
                            Expanded(child: Text(currency['name']!)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => selectedItem = value,
                  ),
                
                if (selectedType == 'stock')
                  Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Hisse Ara (örn: AAPL)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.search),
                        ),
                        onChanged: (query) {
                          if (query.length >= 2) {
                            controller.searchAndAddStock(query);
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      
                      Obx(() {
                        if (controller.isSearching.value) {
                          return CircularProgressIndicator();
                        }
                        
                        if (controller.searchResults.isNotEmpty) {
                          return Container(
                            height: 150,
                            child: ListView.builder(
                              itemCount: controller.searchResults.length,
                              itemBuilder: (context, index) {
                                final result = controller.searchResults[index];
                                return ListTile(
                                  title: Text(result['symbol']),
                                  subtitle: Text(result['name']),
                                  onTap: () {
                                    selectedItem = '${result['symbol']}|${result['name']}';
                                    setState(() {});
                                  },
                                  selected: selectedItem?.startsWith(result['symbol']) == true,
                                );
                              },
                            ),
                          );
                        }
                        
                        return Text('Hisse senedi aramak için en az 2 karakter girin');
                      }),
                      
                      SizedBox(height: 8),
                      Text('Popüler Hisse Senetleri:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Popüler Hisse Seç',
                          border: OutlineInputBorder(),
                        ),
                        items: controller.popularStocks.map((stock) {
                          return DropdownMenuItem(
                            value: '${stock['symbol']}|${stock['name']}',
                            child: Row(
                              children: [
                                Text(stock['symbol']!),
                                SizedBox(width: 8),
                                Expanded(child: Text(stock['name']!)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => selectedItem = value,
                      ),
                    ],
                  ),
                
                if (selectedType == 'crypto')
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Kripto Para Seç',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.popularCryptos.map((crypto) {
                      return DropdownMenuItem(
                        value: '${crypto['symbol']}|${crypto['name']}',
                        child: Row(
                          children: [
                            Text(crypto['symbol']!),
                            SizedBox(width: 8),
                            Expanded(child: Text(crypto['name']!)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => selectedItem = value,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedItem == null) {
                  Get.snackbar('Hata', 'Seçim yapmanız gerekli');
                  return;
                }
                
                if (selectedType == 'forex') {
                  final currency = controller.popularCurrencies
                      .firstWhere((c) => c['symbol'] == selectedItem);
                  
                  controller.addToWatchlist(
                    symbol: currency['symbol']!,
                    name: currency['name']!,
                    type: 'forex',
                  );
                } else if (selectedType == 'stock') {
                  final parts = selectedItem!.split('|');
                  controller.addStockToWatchlist(parts[0], parts[1]);
                } else if (selectedType == 'crypto') {
                  final parts = selectedItem!.split('|');
                  controller.addCryptoToWatchlist(parts[0], parts[1]);
                }
                
                Get.back();
              },
              child: Text('Ekle'),
            ),
          ],
        );
      },
    ),
  );
}
Color _getTypeColor(String type) {
  switch (type) {
    case 'forex':
      return Colors.blue;
    case 'stock':
      return Colors.green;
    case 'crypto':
      return Colors.orange;
    default:
      return Colors.grey;
  }
}

String _getTypeLabel(String type) {
  switch (type) {
    case 'forex':
      return 'DÖVİZ';
    case 'stock':
      return 'HİSSE';
    case 'crypto':
      return 'KRİPTO';
    default:
      return 'DİĞER';
  }
}
}