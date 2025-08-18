import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/bottom_nav.dart';
import 'dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../analytics/analytics_screen.dart';
import '../investments/investments_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final HomeController homeController = Get.put(HomeController());

  final List<Widget> screens = [
    DashboardScreen(),
    TransactionsScreen(),
    AnalyticsScreen(),
    InvestmentsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: homeController.currentIndex.value,
        children: screens,
      )),
      bottomNavigationBar: BottomNavBar(),
    );
  }
}