import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_menu.dart';
import '../admin_provider.dart';

class AdminBottomBar extends StatelessWidget {
  const AdminBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    int currentIndex = adminMenuItems.indexWhere(
      (e) => e['route'] == admin.currentRoute,
    );

    if (currentIndex == -1) {
      currentIndex = 0;   // tránh lỗi khi route không thuộc bottom bar
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Color(0xFF8A3A75),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      iconSize: 20,
      onTap: (i) {
        admin.changeRoute(adminMenuItems[i]['route']);
      },
      items: adminMenuItems.map(
        (item) => BottomNavigationBarItem(
          icon: Icon(item['icon']),
          label: item['label'],
        ),
      ).toList(),
    );
  }
}
