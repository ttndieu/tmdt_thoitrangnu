// lib/modules/admin/products/product_form_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../admin_provider.dart';

// common
import '../common/common_section.dart';
import '../common/common_card.dart';
import '../common/common_gap.dart';
import '../common/common_confirm.dart';
import '../common/common_notify.dart';

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
  final _name = TextEditingController();
  final _description = TextEditingController();

  String? _selectedCategorySlug;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _variants = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      final p = widget.product!;
      _name.text = p["name"] ?? "";
      _description.text = p["description"] ?? "";

      final c = p["category"];
      if (c is Map && c.containsKey("slug")) _selectedCategorySlug = c["slug"];
      else if (c is String) _selectedCategorySlug = c;

      final imgs = p["images"];
      if (imgs is List) {
        for (var v in imgs) {
          if (v is String)
            _images.add({"url": v, "public_id": ""});
          else if (v is Map)
            _images.add({"url": v["url"], "public_id": v["public_id"]});
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

  // ---------------------------------------------------------
  // UPLOAD ẢNH (không confirm, không notify)
  // ---------------------------------------------------------
  Future<void> _pickAndUploadImage(AdminProvider admin) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      MultipartFile f = kIsWeb
          ? MultipartFile.fromBytes(await picked.readAsBytes(), filename: picked.name)
          : await MultipartFile.fromFile(picked.path, filename: picked.name);

      final resp = await admin.api.dio.post(
        "/api/upload",
        data: FormData.fromMap({
          "image": f,
          "categorySlug": _selectedCategorySlug ?? "",
        }),
      );

      final d = resp.data;
      if (d is Map) {
        setState(() {
          _images.add({"url": d["url"], "public_id": d["public_id"]});
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // Không confirm delete ảnh
  Future<void> _deleteImage(AdminProvider admin, int i) async {
    final publicId = _images[i]["public_id"];
    if (publicId != null && publicId != "") {
      await admin.api.dio.delete("/api/upload/${Uri.encodeComponent(publicId)}");
    }
    setState(() => _images.removeAt(i));
  }

  // Không confirm replace
  Future<void> _replaceImage(AdminProvider admin, int i) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      MultipartFile f = kIsWeb
          ? MultipartFile.fromBytes(await picked.readAsBytes(), filename: picked.name)
          : await MultipartFile.fromFile(picked.path, filename: picked.name);

      final resp = await admin.api.dio.put(
        "/api/upload/replace",
        data: FormData.fromMap({
          "image": f,
          "old_public_id": _images[i]["public_id"],
          "categorySlug": _selectedCategorySlug ?? "",
        }),
      );

      final d = resp.data;
      if (d is Map) {
        setState(() {
          _images[i] = {"url": d["new_url"], "public_id": d["new_public_id"]};
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------
  // VARIANT (không notify)
  // ---------------------------------------------------------
  Future<void> _openVariantEditor({Map<String, dynamic>? v, int? idx}) async {
    final r = await VariantEditorDialog.show(context, variant: v);
    if (r == null) return;
    setState(() {
      if (idx == null)
        _variants.add(r);
      else
        _variants[idx] = {..._variants[idx], ...r};
    });
  }

  Future<void> _deleteVariant(int i) async {
    setState(() => _variants.removeAt(i));
  }

  // ---------------------------------------------------------
  // LƯU SẢN PHẨM (có confirm + notify)
  // ---------------------------------------------------------
  Future<void> _submit(AdminProvider admin) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await showConfirmDialog(
      context,
      title: widget.product == null ? "Tạo sản phẩm mới?" : "Cập nhật sản phẩm?",
      message: "Xác nhận lưu thay đổi?",
      confirmColor: Colors.green,
      confirmText: "Lưu",
    );
    if (!ok) return;

    setState(() => _loading = true);

    try {
      final payload = {
        "name": _name.text.trim(),
        "description": _description.text.trim(),
        "category": _selectedCategorySlug,
        "images": _images,
        "variants": _variants,
      };

      if (widget.product == null) {
        await admin.api.post("/api/products", data: payload);
        showSuccess(context, "Tạo sản phẩm thành công");
      } else {
        await admin.api.put("/api/products/${widget.product!["_id"]}", data: payload);
        showSuccess(context, "Cập nhật sản phẩm thành công");
      }

      admin.backToProducts();
    } catch (e) {
      showError(context, "Lỗi lưu sản phẩm: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => admin.backToProducts()),
          const SizedBox(width: 8),
          Text(
            widget.product == null ? "Tạo sản phẩm" : "Cập nhật sản phẩm",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ]),

        const SizedBox(height: 12),

        Expanded(
          child: FutureBuilder(
            future: admin.api.get("/api/category"),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text("Lỗi tải danh mục: ${snap.error}"));
              }

              List categories = [];
              final d = snap.data?.data;
              if (d is Map && d["categories"] is List) categories = d["categories"];
              else if (d is Map && d["data"] is List) categories = d["data"];
              else if (d is List) categories = d;

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    // Thông tin sản phẩm
                    CommonCard(
                      child: CommonSection(
                        title: "Thông tin sản phẩm",
                        child: Column(children: [
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(labelText: "Tên sản phẩm"),
                            validator: (v) => v == null || v.trim().isEmpty ? "Không được để trống" : null,
                          ),
                          G.h12,
                          TextFormField(
                            controller: _description,
                            decoration: const InputDecoration(labelText: "Mô tả"),
                            maxLines: 3,
                          ),
                          G.h16,
                          CategoryDropdown(
                            categories: categories,
                            value: _selectedCategorySlug,
                            onChanged: (v) => setState(() => _selectedCategorySlug = v),
                          ),
                        ]),
                      ),
                    ),

                    // Ảnh sản phẩm
                    CommonCard(
                      child: CommonSection(
                        title: "Ảnh sản phẩm",
                        child: ImageManager(
                          images: _images,
                          loading: _loading,
                          onPick: () => _pickAndUploadImage(admin),
                          onDelete: (i) => _deleteImage(admin, i),
                          onReplace: (i) => _replaceImage(admin, i),
                        ),
                      ),
                    ),

                    // Variants
                    CommonCard(
                      child: CommonSection(
                        title: "Variants",
                        child: VariantTable(
                          variants: _variants,
                          onAdd: () => _openVariantEditor(),
                          onEdit: (i) => _openVariantEditor(v: _variants[i], idx: i),
                          onDelete: _deleteVariant,
                        ),
                      ),
                    ),

                    G.h20,

                    // Nút lưu
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : () => _submit(admin),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(widget.product == null ? "Tạo sản phẩm" : "Cập nhật"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
