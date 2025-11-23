import 'package:fe/modules/user/models/mall_provider.dart';
import 'package:fe/modules/user/providers/address_provider.dart';
import 'package:fe/modules/user/providers/cart_provider.dart';
import 'package:fe/modules/user/providers/home_provider.dart';
import 'package:fe/modules/user/providers/notification_provider.dart';
import 'package:fe/modules/user/providers/order_provider.dart';
import 'package:fe/modules/user/providers/wishlist_provider.dart';
import 'package:fe/modules/user/providers/voucher_provider.dart';
import 'package:fe/modules/user/screens/cart_page.dart';
import 'package:fe/modules/user/user_main_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';

import 'modules/auth/providers/auth_provider.dart';

import 'modules/auth/views/login_page.dart';
import 'modules/auth/views/register_page.dart';

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => MallProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AddressProvider>(
          create: (context) => AddressProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => AddressProvider(auth),
        ),

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
          AppRoutes.userHome: (_) => const UserMainPage(),
          AdminRoutes.adminHome: (_) => const AdminHomePage(),
          '/cart': (_) => const CartPage(),
        },
      ),
    );
  }
}
