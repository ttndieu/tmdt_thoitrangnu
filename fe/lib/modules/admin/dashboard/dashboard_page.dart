// lib/modules/admin/dashboard/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../admin_provider.dart';

final moneyFmt = NumberFormat("#,###", "vi_VN");

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  Map<String, dynamic> stats = {};
  List<dynamic> months = [], byCategory = [], topProducts = [];

  @override void initState() { super.initState(); _loadAll(); }

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
    } catch (e) { debugPrint("Dashboard error: $e"); }
    finally { if (mounted) setState(() => loading = false); }
  }

  // Card thống kê
  Widget _statCard(String title, dynamic value, IconData icon, Color color, String unit) => Container(
    padding: const EdgeInsets.all(20), width: 260,
    decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(.3), width: 1.5),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0,4))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 28)),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value is num ? (unit == 'đ' ? moneyFmt.format(value) : moneyFmt.format(value)) : value.toString(),
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color is MaterialColor ? color.shade700 : color)),
        const SizedBox(width: 6),
        Text(unit, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: (color is MaterialColor ? color.shade700 : color).withOpacity(.8))),
      ]),
    ]),
  );

  // Biểu đồ cột doanh thu
  Widget _revenueChart() => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Doanh thu theo tháng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text("Năm ${DateTime.now().year}", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      const SizedBox(height: 20),
      SizedBox(height: 300, child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: months.isEmpty ? 1e6 : months.map((e) => (e['revenue']??0).toDouble()).reduce((a,b)=>a>b?a:b)*1.3,
        barGroups: months.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(
          toY: (e.value['revenue']??0).toDouble(),
          color: const Color(0xFFC597B9), width: 32,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        )])).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 68, interval: 500000,
            getTitlesWidget: (v,_) => Text(v.toInt()==0?'0':moneyFmt.format(v.toInt()), style: const TextStyle(fontSize: 11)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 38,
            getTitlesWidget: (v,_) { final i=v.toInt(); return i<months.length ? Padding(padding: const EdgeInsets.only(top:8),
              child: Text("Th.${months[i]['month'].toString().split('-').last}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))) : const SizedBox(); })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ))),
    ])),
  );

  // Biểu đồ tròn trạng thái đơn hàng
  PieChartData _pieData() {
    final o = stats["orders"] ?? {};
    final vals = [
      (o["pending"] ?? 0).toDouble(),
      (o["confirmed"] ?? 0).toDouble(),
      (o["shipping"] ?? 0).toDouble(),
      (o["completed"] ?? 0).toDouble(),
      (o["cancelled"] ?? 0).toDouble(),
    ];
    final colors = [Colors.orange.shade300, Colors.blue.shade300, Colors.purple.shade300, Colors.green.shade400, Colors.red.shade300];

    if (vals.every((e) => e == 0)) {
      return PieChartData(sections: [PieChartSectionData(value: 1, color: Colors.grey.shade300, title: "0", radius: 60)]);
    }

    return PieChartData(
      sectionsSpace: 3,
      centerSpaceRadius: 40,
      sections: vals.asMap().entries.map((e) {
        final value = e.value;
        return PieChartSectionData(
          value: value,
          color: colors[e.key],
          radius: 55,
          title: value == 0 ? "" : value.toInt().toString(),
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        );
      }).toList(),
    );
  }

  Widget _orderStatusChart() => Card(
    child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Tình trạng đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      SizedBox(height: 260, child: PieChart(_pieData())),
            const SizedBox(height: 16),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem("Chờ xác nhận", Colors.orange.shade300),
          _legendItem("Đã xác nhận", Colors.blue.shade300),
          _legendItem("Đang giao", Colors.purple.shade300),
          _legendItem("Hoàn thành", Colors.green.shade400),
          _legendItem("Đã hủy", Colors.red.shade300),
        ],
      ),
    ])),
  );
  Widget _legendItem(String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 13)),
  ]);
  // Doanh thu theo danh mục
  Widget _categoryBars() {
    if (byCategory.isEmpty) return const Text("Không có dữ liệu");
    final max = byCategory.map((e)=>(e["revenue"]??0).toDouble()).reduce((a,b)=>a>b?a:b);
    return Column(children: byCategory.map((c){
      final name = c["name"]??"Khác";
      final rev = (c["revenue"]??0).toDouble();
      final pct = max==0 ? 0 : rev/max;
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
        Expanded(flex: 3, child: Text(name)),
        Expanded(flex: 6, child: Stack(children: [
          Container(height: 12, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
          FractionallySizedBox(widthFactor: pct.clamp(0,1), child: Container(height: 12, decoration: BoxDecoration(color: Colors.purple.shade300, borderRadius: BorderRadius.circular(6)))),
        ])),
        SizedBox(width: 80, child: Text(moneyFmt.format(rev), textAlign: TextAlign.right)),
      ]));
    }).toList());
  }

  @override Widget build(BuildContext context) => loading
    ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      const Text("Tổng quan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),

      // 4 Cards
      Wrap(spacing: 20, runSpacing: 20, children: [
        _statCard("Tổng doanh thu", stats["totalRevenue"]??0, Icons.trending_up_rounded, Colors.purple, "đ"),
        _statCard("Tổng đơn hàng", stats["totalOrders"]??0, Icons.receipt_long_rounded, Colors.blue, "đơn"),
        _statCard("Người dùng", stats["totalUsers"]??0, Icons.people_alt_rounded, Colors.green, "người"),
        _statCard("Sản phẩm", stats["totalProducts"]??0, Icons.inventory_2_rounded, Colors.orange, "sản phẩm"),
      ]),

      const SizedBox(height: 40),

      // 2 Biểu đồ responsive
      LayoutBuilder(builder: (_, c) {
        final wide = c.maxWidth > 900;
        return wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _revenueChart()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _orderStatusChart()),
            ])
          : Column(children: [_revenueChart(), const SizedBox(height: 24), _orderStatusChart()]);
      }),

      const SizedBox(height: 40),

      // Danh mục + Top sản phẩm
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Doanh thu theo danh mục", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _categoryBars(),
      ]))),

      const SizedBox(height: 30),

      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Top sản phẩm bán chạy", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...topProducts.map((p) => ListTile(contentPadding: EdgeInsets.zero,
          leading: p["images"]!=null && p["images"].isNotEmpty
            ? Image.network(p["images"][0]["url"], width: 48, height: 48, fit: BoxFit.cover)
            : Container(width: 48, height: 48, color: Colors.grey.shade200),
          title: Text(p["name"]??""), trailing: Text("${p["sold"]??0}"),
        )),
      ]))),
    ]));
}