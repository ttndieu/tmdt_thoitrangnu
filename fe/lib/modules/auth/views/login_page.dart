// lib/modules/auth/views/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../modules/admin/admin_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Màu chủ đạo – giữ đồng bộ với RegisterPage
    final primaryColor = Colors.deepPurple;
    // Nếu bạn dùng màu khác ở Register thì sửa ở đây cho giống

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon thương hiệu
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 24),

                Text(
                  "Chào mừng trở lại!",
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Đăng nhập để tiếp tục mua sắm",
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
                const SizedBox(height: 40),

                // Form trong Card đẹp
                Card(
                  elevation: 8,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              hintText: "nhập email của bạn",
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[50],
                            ),
                            onSaved: (v) => _email = v?.trim() ?? '',
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return "Vui lòng nhập email";
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(v)) {
                                return "Email không hợp lệ";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Mật khẩu
                          TextFormField(
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Mật khẩu",
                              hintText: "ít nhất 6 ký tự",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[50],
                            ),
                            onSaved: (v) => _password = v ?? '',
                            validator: (v) => v == null || v.length < 6
                                ? "Mật khẩu phải từ 6 ký tự trở lên"
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Quên mật khẩu (tùy chọn mở rộng sau)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Navigate to Forgot Password
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Tính năng quên mật khẩu sắp ra mắt!",
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Quên mật khẩu?",
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nút Đăng nhập
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      if (!_formKey.currentState!.validate())
                                        return;
                                      _formKey.currentState!.save();

                                      setState(() => _loading = true);

                                      final success = await auth.login(
                                        _email,
                                        _password,
                                      );

                                      setState(() => _loading = false);

                                      if (success) {
                                        final role = auth.user?.role ?? "user";

                                        if (!mounted) return;

                                        if (role == "admin") {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AdminRoutes.adminHome,
                                          );
                                        } else {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRoutes.userHome,
                                          );
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                auth.message ??
                                                    "Đăng nhập thất bại",
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: _loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Đăng nhập",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Chưa có tài khoản?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Chưa có tài khoản? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                      child: Text(
                        "Đăng ký ngay",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
