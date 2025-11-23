// lib/modules/admin/products/product_form_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../admin_provider.dart';
import 'components/image_manager.dart';
import 'components/variant_table.dart';
import 'components/variant_editor_dialog.dart';
import 'components/category_dropdown.dart';

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
        m = await MultipartFile.fromFile(picked.path, filename: filename);
      }

      final form = FormData.fromMap({
        "image": m,
        "categorySlug": _selectedCategorySlug ?? "",
      });

      final resp = await dio.post("/api/upload", data: form);
      final data = resp.data;
      if (data != null && data is Map) {
        setState(() {
          _images.add({
            "url": data["url"] ?? "",
            "public_id": data["public_id"] ?? "",
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload lỗi: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteImage(AdminProvider admin, int index) async {
    final publicId = _images[index]["public_id"];
    if (publicId == null || publicId == "") {
      // nếu ko có public_id chỉ remove local
      setState(() => _images.removeAt(index));
      return;
    }

    setState(() => _loading = true);
    try {
      final encoded = Uri.encodeComponent(publicId);
      // call backend DELETE /api/upload/:public_id
      await admin.api.dio.delete("/api/upload/$encoded");
      if (mounted) setState(() => _images.removeAt(index));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Xoá ảnh lỗi: $e")));
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
        setState(() {
          _images[index] = {
            "url": data["new_url"] ?? "",
            "public_id": data["new_public_id"] ?? "",
          };
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Replace lỗi: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openVariantEditor({Map<String, dynamic>? variant, int? index}) async {
    final result = await VariantEditorDialog.show(context, variant: variant);
    if (result != null) {
      setState(() {
        if (index == null) _variants.add(result);
        else _variants[index] = {..._variants[index], ...result};
      });
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
        await admin.api.put("/api/products/${widget.product!['_id']}", data: payload);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi lưu sản phẩm: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.product == null ? "Tạo sản phẩm" : "Sửa sản phẩm")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: admin.api.get("/api/category"),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text("Lỗi tải danh mục: ${snapshot.error}"));

            List categories = [];
            final data = snapshot.data?.data;
            if (data is Map && data.containsKey("categories")) categories = data["categories"];
            else if (data is Map && data.containsKey("data")) categories = data["data"];
            else if (data is List) categories = data;

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: "Tên sản phẩm"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Không được để trống" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: "Mô tả"),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  CategoryDropdown(
                    categories: categories,
                    value: _selectedCategorySlug,
                    onChanged: (v) => setState(() => _selectedCategorySlug = v),
                  ),
                  const SizedBox(height: 16),
                  ImageManager(
                    images: _images,
                    onPick: () => _pickAndUploadImage(admin),
                    onDelete: (i) => _deleteImage(admin, i),
                    onReplace: (i) => _replaceImage(admin, i),
                    loading: _loading,
                  ),
                  const SizedBox(height: 16),
                  VariantTable(
                    variants: _variants,
                    onAdd: () => _openVariantEditor(),
                    onEdit: (i) => _openVariantEditor(variant: _variants[i], index: i),
                    onDelete: (i) => setState(() => _variants.removeAt(i)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : () => _submit(admin),
                    child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.product == null ? "Tạo" : "Cập nhật"),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
