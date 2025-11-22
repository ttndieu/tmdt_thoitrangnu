import 'package:fe/modules/user/screens/home_page.dart';
import 'package:fe/modules/user/screens/mall_page.dart';
import 'package:fe/modules/user/screens/notifications_page.dart';
import 'package:fe/modules/user/screens/profile_page.dart';
import 'widgets/shared/custom_bottom_nav.dart';
import 'package:flutter/material.dart';

class UserMainPage extends StatefulWidget {
  const UserMainPage({Key? key}) : super(key: key);

  @override
  State<UserMainPage> createState() => _UserMainPageState();
}

class _UserMainPageState extends State<UserMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    MallPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
