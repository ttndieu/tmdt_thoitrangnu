import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';

import 'modules/auth/providers/auth_provider.dart';

import 'modules/auth/views/login_page.dart';
import 'modules/auth/views/register_page.dart';

import 'modules/user/user_home_page.dart';

import 'modules/admin/admin_home_page.dart';
import 'modules/admin/admin_provider.dart';

import 'routes/app_routes.dart';
import 'modules/admin/admin_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Bắt buộc phải có!!!
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        /// AdminProvider phụ thuộc AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (_) => AdminProvider(AuthProvider(), ApiClient()),
          update: (_, authProvider, previous) =>
              AdminProvider(authProvider, ApiClient()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fashion App',
        theme: ThemeData(primarySwatch: Colors.pink),
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.register: (_) => const RegisterPage(),
          AppRoutes.userHome: (_) => const UserHomePage(),
          AdminRoutes.adminHome: (_) => const AdminHomePage(),
        },
      ),
    );
  }
}
