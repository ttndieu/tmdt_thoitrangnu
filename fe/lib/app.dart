import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'modules/auth/providers/auth_provider.dart';

import 'modules/auth/views/login_page.dart';
import 'modules/auth/views/register_page.dart';

import 'modules/user/user_home_page.dart';
import 'modules/admin/admin_dashboard_page.dart';


import 'routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fashion App',
        theme: ThemeData(primarySwatch: Colors.pink),
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.register: (_) => const RegisterPage(),

          /// USER
          // AppRoutes.home: (_) => const HomePage(),
  // Thêm hai route này
  AppRoutes.userHome: (_) => const UserHomePage(),
  AppRoutes.adminDashboard: (_) => const AdminDashboardPage(),
},
      ),
    );
  }
}
