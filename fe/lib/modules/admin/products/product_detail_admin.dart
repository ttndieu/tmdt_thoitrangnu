// lib/modules/admin/products/product_detail_admin.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin_provider.dart';
import '../common/common_confirm.dart';

final moneyFmt = NumberFormat("#,###", "vi_VN");
final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

class ProductDetailAdmin extends StatefulWidget {
  final String productId;
  const ProductDetailAdmin({super.key, required this.productId});

  @override
  State<ProductDetailAdmin> createState() => _ProductDetailAdminState();
}

class _ProductDetailAdminState extends State<ProductDetailAdmin> {
  Map<String, dynamic>? _product;
  List<dynamic> _reviews = [];

  bool _loadingProduct = true;
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReviews();
  }

  Future<void> _loadProduct() async {
    try {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final resp = await admin.api.get("/api/products/${widget.productId}");

      if (resp.data is Map && resp.data["product"] != null) {
        setState(() => _product = Map<String, dynamic>.from(resp.data["product"]));
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _loadingProduct = false);
    }
  }

  Future<void> _loadReviews() async {
    try {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final resp = await admin.api.get("/api/reviews/product/${widget.productId}");

      if (resp.data != null && resp.data["reviews"] != null) {
        setState(() => _reviews = List.from(resp.data["reviews"]));
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirm = await showConfirmDialog(
      context,
      title: "Xóa đánh giá",
      message: "Bạn chắc chắn muốn xóa đánh giá này?",
      confirmColor: Colors.red,
      confirmText: "Xóa",
      cancelText: "Hủy",
    );

    if (!confirm) return;

    try {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      await admin.api.delete("/api/reviews/$reviewId");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã xóa đánh giá"), backgroundColor: Colors.green),
      );

      _loadReviews();
      _loadProduct();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      Provider.of<AdminProvider>(context, listen: false).backToProducts(),
                ),
                const SizedBox(width: 8),
                const Text("Chi tiết sản phẩm",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 16),

            // MAIN CONTENT SCROLL
            Expanded(
              child: _loadingProduct
                  ? const Center(child: CircularProgressIndicator())
                  : _product == null
                      ? const Center(child: Text("Không tìm thấy sản phẩm"))
                      : ListView(
                          children: [
                            _buildProductInfo(),
                            const SizedBox(height: 30),
                            _buildReviewsSection(),
                            const SizedBox(height: 30),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- THÔNG TIN SẢN PHẨM ----------
  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_product!["name"],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        Text("Danh mục: ${_product!["category"]?["name"] ?? "Chưa có"}",
            style: const TextStyle(fontSize: 16)),

        const SizedBox(height: 20),

        if ((_product!["images"] as List).isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _product!["images"].length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final img = _product!["images"][i];
                final url = img is Map ? img["url"] : img.toString();

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[300]),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 20),
        const Text("Mô tả:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text((_product!["description"] ?? "").toString(),
            style: const TextStyle(fontSize: 15)),

        const SizedBox(height: 24),
        const Text("Variants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        ...(_product!["variants"] as List).map((v) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text("${v["size"]} - ${v["color"]}"),
              subtitle: Text("Kho: ${v["stock"]} | Giá: ${moneyFmt.format(v["price"])}₫"),
            ),
          );
        }),
      ],
    );
  }

  // ---------- DANH SÁCH ĐÁNH GIÁ ----------
  Widget _buildReviewsSection() {
    final avg = _product?["averageRating"]?.toDouble() ?? 0.0;
    final count = _product?["reviewCount"] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Đánh giá",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.star, color: Colors.amber, size: 26),
            const SizedBox(width: 4),
            Text("$avg",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(" ($count)", style: TextStyle(color: Colors.grey[600])),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(),

        if (_loadingReviews)
          const Center(child: Padding(
              padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
        else if (_reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("Chưa có đánh giá nào",
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          )
        else
          ..._reviews.map(_buildReviewItem),
      ],
    );
  }

  Widget _buildReviewItem(dynamic r) {
    final user = r["user"] ?? {};
    final images = (r["images"] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user["avatar"] != null
                      ? NetworkImage(user["avatar"])
                      : const AssetImage("assets/images/default_avatar.png")
                          as ImageProvider,
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user["name"] ?? "Khách",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < (r["rating"] as num)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateFmt.format(DateTime.parse(r["createdAt"])),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _deleteReview(r["_id"]),
                ),
              ],
            ),

            if (r["comment"]?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(r["comment"], style: const TextStyle(fontSize: 15)),
            ],

            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, j) {
                    final img = images[j];
                    final url = img is Map ? img["url"] : img.toString();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
