// lib/modules/admin/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../admin_provider.dart';

final moneyFmt = NumberFormat("#,###", "vi_VN");

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;

  Map<String, dynamic> stats = {};
  List<dynamic> months = [];
  List<dynamic> byCategory = [];
  List<dynamic> topProducts = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => loading = true);
    try {
      final api = Provider.of<AdminProvider>(context, listen: false).api;

      final res = await Future.wait([
        api.get("/api/admin/stats"),
        api.get("/api/admin/revenue/month"),
        api.get("/api/admin/revenue/category"),
        api.get("/api/admin/top-products"),
      ]);

      stats = res[0].data;
      months = res[1].data;
      byCategory = res[2].data;
      topProducts = res[3].data;
    } catch (e) {
      print("Dashboard load error: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // -----------------------------
  // Card tiện ích
  // -----------------------------
  Widget _statCard({
    required String title,
    required dynamic value,
    required IconData icon,
    required Color color,
    required String unit, // mới thêm
  }) {
    final displayValue = value is num
        ? (unit == 'đ' ? "${moneyFmt.format(value)}" : moneyFmt.format(value))
        : value.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      width: 260,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color is MaterialColor ? color.shade700 : color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: (color is MaterialColor ? color.shade700 : color)
                      .withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // Biểu đồ doanh thu theo tháng (CỘT)
  // -----------------------------
  BarChartData _buildBarChart() {
    final barSpots = <BarChartGroupData>[];

    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final revenue = (m['revenue'] ?? 0).toDouble();

      barSpots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              width: 18,
              borderRadius: BorderRadius.circular(4),
              color: Colors.purple.shade300,
            ),
          ],
        ),
      );
    }

    return BarChartData(
      barGroups: barSpots,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            reservedSize: 32,
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= months.length) {
                return const SizedBox.shrink();
              }

              final label = months[idx]["month"] ?? "";
              final mm = label.toString().split("-").last;

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(mm, style: const TextStyle(fontSize: 11)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: false),
    );
  }

  // -----------------------------
  // Doanh thu theo danh mục
  // -----------------------------
  Widget _buildCategoryBars() {
    if (byCategory.isEmpty) return const Text("Không có dữ liệu");

    final max = byCategory
        .map((e) => (e["revenue"] ?? 0).toDouble())
        .fold<double>(0, (p, c) => c > p ? c : p);

    return Column(
      children: byCategory.map((c) {
        final name = c["name"] ?? "Khác";
        final revenue = (c["revenue"] ?? 0).toDouble();
        final pct = max == 0 ? 0 : revenue / max;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(name)),
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0, 1),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  moneyFmt.format(revenue),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tổng quan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _statCard(
                      title: "Tổng doanh thu",
                      value: stats["totalRevenue"] ?? 0,
                      icon: Icons.trending_up_rounded,
                      color: Colors.purple,
                      unit: "đ",
                    ),
                    _statCard(
                      title: "Tổng đơn hàng",
                      value: stats["totalOrders"] ?? 0,
                      icon: Icons.receipt_long_rounded,
                      color: Colors.blue,
                      unit: "đơn",
                    ),
                    _statCard(
                      title: "Người dùng",
                      value: stats["totalUsers"] ?? 0,
                      icon: Icons.people_alt_rounded,
                      color: Colors.green,
                      unit: "người",
                    ),
                    _statCard(
                      title: "Sản phẩm",
                      value: stats["totalProducts"] ?? 0,
                      icon: Icons.inventory_2_rounded,
                      color: Colors.orange,
                      unit: "sản phẩm",
                    ),
                    _statCard(
                      title: "Chờ xác nhận",
                      value: stats["orders"]?["pending"] ?? 0,
                      icon: Icons.schedule_rounded,
                      color: Colors.red,
                      unit: "đơn",
                    ),
                    _statCard(
                      title: "Đã giao",
                      value: stats["orders"]?["completed"] ?? 0,
                      icon: Icons.check_circle_rounded,
                      color: Colors.teal,
                      unit: "đơn",
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Biểu đồ cột doanh thu theo tháng
                const SizedBox(height: 30),

                // Biểu đồ doanh thu theo tháng - ĐẸP, DỄ NHÌN, ĐƠN GIẢN
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Doanh thu theo tháng",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Năm ${DateTime.now().year}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Biểu đồ cột đẹp hơn, to hơn, dễ đọc
                      SizedBox(
                        height: 280,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: months.isEmpty
                                ? 1000000
                                : (months
                                          .map(
                                            (e) =>
                                                (e['revenue'] ?? 0).toDouble(),
                                          )
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.3),

                            barGroups: months.asMap().entries.map((e) {
                              final revenue = (e.value['revenue'] ?? 0)
                                  .toDouble();
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: revenue,
                                    color: const Color.fromRGBO(
                                      197,
                                      151,
                                      185,
                                      1,
                                    ),
                                    width: 32,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),

                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 68, // tăng chỗ cho chữ
                                  interval:
                                      500000, // chia mỗi 500k → không bao giờ chồng
                                  getTitlesWidget: (v, _) => Text(
                                    v.toInt() == 0
                                        ? '0'
                                        : moneyFmt.format(v.toInt()),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 38,
                                  getTitlesWidget: (v, _) {
                                    final idx = v.toInt();
                                    if (idx >= months.length)
                                      return const SizedBox();
                                    final m = months[idx]["month"]
                                        .toString()
                                        .split("-")
                                        .last;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        "Th.$m",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),

                            gridData: const FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Danh mục
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Doanh thu theo danh mục",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryBars(),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Top sản phẩm
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top sản phẩm bán chạy",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...topProducts.map((p) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              (p["images"] != null && p["images"].isNotEmpty)
                              ? Image.network(
                                  p["images"][0]["url"],
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.grey.shade200,
                                ),
                          title: Text(p["name"] ?? ""),
                          trailing: Text("${p["sold"] ?? 0}"),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}
