import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/investment_controller.dart';
import '../../core/theme.dart';
import '../../widgets/transaction_card.dart';

class DashboardScreen extends StatelessWidget {
  final HomeController homeController = Get.find();
  final AuthController authController = Get.find();
  final InvestmentController investmentController = Get.put(InvestmentController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await homeController.refreshData();
            await investmentController.refreshData();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merhaba,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Obx(() => Text(
                          authController.userProfile.value?.fullName ?? 'Kullanıcı',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                      ],
                    ),
Container(
  height: 20, 
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF7B4397), // Üst kartın mor rengi
        Color(0xFF9C27B0), // Alt kartın mor rengi
      ],
    ),
  ),
)
                  ],
                ),
                SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Bakiye',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Obx(() => Text(
                        '₺${NumberFormat('#,##0.00').format(homeController.balance.value)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward, 
                                        color: Colors.green[300], size: 16),
                                    SizedBox(width: 4),
                                    Text('Gelir', 
                                        style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                                Obx(() => Text(
                                  '₺${NumberFormat('#,##0.00').format(homeController.monthlyIncome.value)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_upward, 
                                        color: Colors.red[300], size: 16),
                                    SizedBox(width: 4),
                                    Text('Gider', 
                                        style: TextStyle(color: Colors.white70)),
                                  ],
                                ),
                                Obx(() => Text(
                                  '₺${NumberFormat('#,##0.00').format(homeController.monthlyExpense.value)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                _buildInvestmentSummaryCard(context),
                SizedBox(height: 24),

                Text(
                  'Hızlı İşlemler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'Gelir Ekle',
                        Icons.add_circle_outline,
                        Colors.green,
                        () => Get.toNamed('/add_transaction?type=income'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'Gider Ekle',
                        Icons.remove_circle_outline,
                        Colors.red,
                        () => Get.toNamed('/add_transaction?type=expense'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'Hedef Ekle',
                        Icons.savings,
                        Colors.purple,
                        () => Get.toNamed('/investments'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        context,
                        'Döviz Takibi',
                        Icons.trending_up,
                        Colors.teal,
                        () async {
                          investmentController.changeTabIndex(1);
                          await Future.delayed(Duration(milliseconds: 100));
                          Get.toNamed('/investments');
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Son İşlemler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => homeController.changeTabIndex(1),
                      child: Text('Tümünü Gör'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Obx(() {
                  if (homeController.isLoading.value) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (homeController.transactions.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          SizedBox(height: 28),
                          Icon(Icons.receipt_long, 
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text('Henüz işlem yok',
                              style: TextStyle(color: Colors.grey[600])),
                          Text('İlk işleminizi ekleyerek başlayın!',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: homeController.transactions.length > 5 
                        ? 5 
                        : homeController.transactions.length,
                    itemBuilder: (context, index) {
                      return TransactionCard(
                        transaction: homeController.transactions[index],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add_transaction?type=expense'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        tooltip: 'Yeni İşlem Ekle',
      ),
    );
  }

  Widget _buildInvestmentSummaryCard(BuildContext context) {
    return Obx(() => Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[700]!, Colors.purple[600]!],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasarruf Hedefleri',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed('/investments'),
                child: Text(
                  'Tümünü Gör',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          if (investmentController.totalGoals.value == 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Henüz hedef yok',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'İlk tasarruf hedefini oluştur!',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₺${NumberFormat('#,##0.00').format(investmentController.totalGoalsCurrent.value)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biriken tutar',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${investmentController.completedGoals.value}/${investmentController.totalGoals.value} hedef',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '%${investmentController.goalsProgress.value.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    ));
  }

  Widget _buildQuickAction(BuildContext context, String title, IconData icon, 
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(title, 
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}