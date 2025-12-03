// lib/modules/admin/products/product_form_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../admin_provider.dart';

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
  List<Map<String, String>> categories = []; 

  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _variants = [];

  bool _loading = false;
  bool _loadingCategories = true; // để hiển thị spinner khi đang tải categories

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCategories());
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  // ---------------- LOAD PRODUCT DATA (1 lần) ----------------
  void _loadInitialData() {
    if (widget.product == null) return;

    final p = widget.product!;
    _name.text = p["name"] ?? "";
    _description.text = p["description"] ?? "";

    final c = p["category"];
    if (c is Map && c.containsKey("slug")) _selectedCategorySlug = c["slug"]?.toString();
    else if (c is String) _selectedCategorySlug = c;

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

  // ---------------- LOAD CATEGORIES (1 LẦN) ----------------
  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });

    final admin = Provider.of<AdminProvider>(context, listen: false);
    try {
      final res = await admin.api.get("/api/category");
      final respData = res.data;

      List raw = [];
      if (respData is Map && respData["categories"] is List) raw = respData["categories"];
      else if (respData is Map && respData["data"] is List) raw = respData["data"];
      else if (respData is List) raw = respData;

      categories = raw.map<Map<String, String>>((e) {
        if (e is Map) {
          final slug = (e["slug"] ?? e["_id"] ?? e["id"] ?? "").toString();
          final name = (e["name"] ?? e["title"] ?? slug).toString();
          return {"slug": slug, "name": name};
        } else {
          final s = e.toString();
          return {"slug": s, "name": s};
        }
      }).where((m) => (m["slug"] ?? "").isNotEmpty).toList();

      // Nếu selectedCategorySlug không nằm trong categories -> set null
      final exists = categories.any((c) => c["slug"] == _selectedCategorySlug);
      if (!exists) _selectedCategorySlug = null;

      setState(() {});
    } catch (e) {
      showError(context, "Không tải được danh mục");
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  // ---------------- IMAGE UPLOAD ----------------
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
        _images.add({
          "url": d["url"] ?? d["new_url"] ?? "",
          "public_id": d["public_id"] ?? d["new_public_id"] ?? "",
        });
      }
      setState(() {});
    } on DioException catch (e) {
      showError(context, "Tải ảnh thất bại: ${e.message}");
    } catch (e) {
      showError(context, "Tải ảnh thất bại: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteImage(AdminProvider admin, int i) async {
    if (i < 0 || i >= _images.length) return;
    final publicId = _images[i]["public_id"];
    try {
      if (publicId != null && publicId != "") {
        await admin.api.dio.delete("/api/upload/${Uri.encodeComponent(publicId)}");
      }
    } catch (_) {}
    if (mounted) setState(() => _images.removeAt(i));
  }

  Future<void> _replaceImage(AdminProvider admin, int i) async {
    if (i < 0 || i >= _images.length) return;

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
          "old_public_id": _images[i]["public_id"] ?? "",
          "categorySlug": _selectedCategorySlug ?? "",
        }),
      );

      final d = resp.data;
      if (d is Map) {
        _images[i] = {
          "url": d["new_url"] ?? d["url"] ?? "",
          "public_id": d["new_public_id"] ?? d["public_id"] ?? "",
        };
      }
      setState(() {});
    } on DioException catch (e) {
      showError(context, "Thay ảnh thất bại: ${e.message}");
    } catch (e) {
      showError(context, "Thay ảnh thất bại: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- VARIANTS ----------------
  Future<void> _openVariantEditor({Map<String, dynamic>? v, int? idx}) async {
    final r = await VariantEditorDialog.show(context, variant: v);
    if (r == null) return;
    if (!mounted) return;
    setState(() {
      if (idx == null) _variants.add(r);
      else if (idx >= 0 && idx < _variants.length) _variants[idx] = {..._variants[idx], ...r};
    });
  }

  Future<void> _deleteVariant(int i) async {
    if (i < 0 || i >= _variants.length) return;
    if (mounted) setState(() => _variants.removeAt(i));
  }

  // ---------------- CLEAN / SUBMIT ----------------
  List<Map<String, dynamic>> _cleanImagesForPayload() {
    return _images.where((e) => (e["url"] ?? "").toString().isNotEmpty).toList();
  }

  List<Map<String, dynamic>> _cleanVariantsForPayload() {
    return _variants.where((v) {
      final price = int.tryParse(v["price"]?.toString() ?? "") ?? (v["price"] is int ? v["price"] : 0);
      return price > 0;
    }).toList();
  }

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

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final imagesPayload = _cleanImagesForPayload();
      final variantsPayload = _cleanVariantsForPayload();

      final payload = {
        "name": _name.text.trim(),
        "description": _description.text.trim(),
        "category": _selectedCategorySlug,
        "images": imagesPayload,
        "variants": variantsPayload,
      };

      if (widget.product == null) {
        await admin.api.post("/api/products", data: payload);
        if (mounted) showSuccess(context, "Tạo sản phẩm thành công");
      } else {
        await admin.api.put("/api/products/${widget.product!["_id"]}", data: payload);
        if (mounted) showSuccess(context, "Cập nhật sản phẩm thành công");
      }

      admin.backToProducts();
    } on DioException catch (e) {
      final msg = e.response != null
          ? "Lỗi server: ${e.response?.statusCode} ${e.response?.statusMessage}"
          : "Lỗi mạng: ${e.message}";
      if (mounted) showError(context, "Lỗi lưu sản phẩm: $msg");
    } catch (e) {
      if (mounted) showError(context, "Lỗi lưu sản phẩm: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------- UI ----------------
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
          child: Form(
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

                      // CategoryDropdown sử dụng categories chuẩn (slug + name)
                      _loadingCategories
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            )
                          : CategoryDropdown(
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
          ),
        ),
      ],
    );
  }
}
