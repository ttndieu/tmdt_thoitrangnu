// lib/modules/admin/products/product_form_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../admin_provider.dart';

class ProductFormPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();

  String? _selectedCategorySlug;
  List<Map<String, dynamic>> _images = []; // {url, public_id}
  List<Map<String, dynamic>> _variants = []; // {size,color,stock,price,_id?}

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _name.text = p["name"] ?? "";
      _description.text = p["description"] ?? "";

      // Category may be object
      final c = p["category"];
      if (c is Map && c.containsKey("slug")) {
        _selectedCategorySlug = c["slug"];
      } else if (p["category"] is String) {
        _selectedCategorySlug = p["category"];
      }

      // images could be List<String> (old) or List<Map>
      final imgs = p["images"];
      if (imgs is List) {
        for (var v in imgs) {
          if (v is String) {
            _images.add({"url": v, "public_id": ""});
          } else if (v is Map) {
            _images.add({
              "url": v["url"] ?? "",
              "public_id": v["public_id"] ?? "",
            });
          }
        }
      }

      final vars = p["variants"];
      if (vars is List) {
        _variants = List<Map<String, dynamic>>.from(
          vars.map((e) => Map<String, dynamic>.from(e)),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage(AdminProvider admin) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final dio = admin.api.dio;
      final String filename = picked.name;

      MultipartFile m;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        m = MultipartFile.fromBytes(bytes, filename: filename);
      } else {
        // mobile
        m = await MultipartFile.fromFile(picked.path, filename: filename);
      }

      final form = FormData.fromMap({
        "image": m,
        "categorySlug": _selectedCategorySlug ?? "",
      });

      final resp = await dio.post("/api/upload", data: form);
      // resp e.g. { url, public_id, folder }
      final data = resp.data;
      if (data != null && data is Map) {
        _images.add({
          "url": data["url"] ?? "",
          "public_id": data["public_id"] ?? "",
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload lỗi: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteImage(AdminProvider admin, int index) async {
    final publicId = _images[index]["public_id"];
    if (publicId == null || publicId == "") {
      // nếu ko có public_id (có thể là url string cũ) chỉ remove local
      setState(() => _images.removeAt(index));
      return;
    }
    setState(() => _loading = true);
    try {
      final encoded = Uri.encodeComponent(publicId);
      await admin.api.dio.delete("/api/upload/$encoded");
      if (mounted) setState(() => _images.removeAt(index));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Xoá ảnh lỗi: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _replaceImage(AdminProvider admin, int index) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final dio = admin.api.dio;
      final String filename = picked.name;
      MultipartFile m;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        m = MultipartFile.fromBytes(bytes, filename: filename);
      } else {
        m = await MultipartFile.fromFile(picked.path, filename: filename);
      }

      final form = FormData.fromMap({
        "image": m,
        "old_public_id": _images[index]["public_id"] ?? "",
        "categorySlug": _selectedCategorySlug ?? "",
      });

      final resp = await dio.put("/api/upload/replace", data: form);
      final data = resp.data;
      if (data != null && data is Map) {
        _images[index] = {
          "url": data["new_url"] ?? "",
          "public_id": data["new_public_id"] ?? "",
        };
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Replace lỗi: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openVariantEditor({
    Map<String, dynamic>? variant,
    int? index,
  }) async {
    final sizeCtrl = TextEditingController(text: variant?["size"] ?? "");
    final colorCtrl = TextEditingController(text: variant?["color"] ?? "");
    final stockCtrl = TextEditingController(
      text: variant?["stock"]?.toString() ?? "0",
    );
    final priceCtrl = TextEditingController(
      text: variant?["price"]?.toString() ?? "0",
    );

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(variant == null ? "Thêm variant" : "Sửa variant"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: sizeCtrl,
                  decoration: const InputDecoration(labelText: "Size (S/M/L)"),
                ),
                TextFormField(
                  controller: colorCtrl,
                  decoration: const InputDecoration(labelText: "Color"),
                ),
                TextFormField(
                  controller: stockCtrl,
                  decoration: const InputDecoration(labelText: "Stock"),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                final v = {
                  "size": sizeCtrl.text.trim(),
                  "color": colorCtrl.text.trim(),
                  "stock": int.tryParse(stockCtrl.text.trim()) ?? 0,
                  "price": int.tryParse(priceCtrl.text.trim()) ?? 0,
                };
                Navigator.pop(context, v);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (index == null) {
        setState(() => _variants.add(result));
      } else {
        setState(() => _variants[index] = {..._variants[index], ...result});
      }
    }
  }

  Future<void> _submit(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final payload = {
        "name": _name.text.trim(),
        "description": _description.text.trim(),
        "category": _selectedCategorySlug,
        "images": _images, // array of {url, public_id}
        "variants": _variants,
      };

      if (widget.product == null) {
        await admin.api.post("/api/products", data: payload);
      } else {
        await admin.api.put(
          "/api/products/${widget.product!['_id']}",
          data: payload,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi lưu sản phẩm: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildImagesSection(AdminProvider admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ảnh sản phẩm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _images.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      _images[i]["url"] ?? "",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => _deleteImage(admin, i),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => _replaceImage(admin, i),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.refresh,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            GestureDetector(
              onTap: () => _pickAndUploadImage(admin),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add_a_photo),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Variants",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _openVariantEditor(),
              icon: const Icon(Icons.add),
              label: const Text("Thêm"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            for (int i = 0; i < _variants.length; i++)
              Card(
                child: ListTile(
                  title: Text(
                    "${_variants[i]['size']} - ${_variants[i]['color']}",
                  ),
                  subtitle: Text(
                    "Stock: ${_variants[i]['stock']}, Price: ${_variants[i]['price']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _openVariantEditor(variant: _variants[i], index: i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _variants.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? "Tạo sản phẩm" : "Sửa sản phẩm"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: admin.api.get("/api/category"),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(child: Text("Lỗi tải danh mục: ${snapshot.error}"));

            // backend có thể trả { categories: [...] } hoặc { success: true, data: [...] }
            List categories = [];
            final data = snapshot.data?.data;
            if (data is Map && data.containsKey("categories"))
              categories = data["categories"];
            else if (data is Map && data.containsKey("data"))
              categories = data["data"];
            else if (data is List)
              categories = data;

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: "Tên sản phẩm",
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? "Không được để trống"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: "Mô tả"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategorySlug,
                    decoration: const InputDecoration(labelText: "Danh mục"),
                    items: categories.map<DropdownMenuItem<String>>((cat) {
                      if (cat is Map) {
                        return DropdownMenuItem(
                          value: cat["slug"],
                          child: Text(cat["name"] ?? ""),
                        );
                      } else if (cat is String) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }
                      return const DropdownMenuItem(
                        value: "",
                        child: Text("Unknown"),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCategorySlug = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Chọn danh mục" : null,
                  ),
                  const SizedBox(height: 16),
                  _buildImagesSection(admin),
                  const SizedBox(height: 16),
                  _buildVariantsSection(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : () => _submit(admin),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(widget.product == null ? "Tạo" : "Cập nhật"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
