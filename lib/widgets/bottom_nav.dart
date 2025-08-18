import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../core/theme.dart';

class BottomNavBar extends StatelessWidget {
  final HomeController homeController = Get.find();

  final List<BottomNavItem> items = [
    BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Ana Sayfa'),
    BottomNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'İşlemler'),
    BottomNavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analiz'),
    BottomNavItem(icon: Icons.trending_up_outlined, activeIcon: Icons.trending_up, label: 'Yatırım'),
    BottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          int index = entry.key;
          BottomNavItem item = entry.value;
          bool isActive = homeController.currentIndex.value == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => homeController.changeTabIndex(index),
              child: Container(
                height: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? AppTheme.primaryColor : Colors.grey,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? AppTheme.primaryColor : Colors.grey,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ));
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}