import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';

class CategoryFormPage extends StatefulWidget {
  final Map? category;

  const CategoryFormPage({super.key, this.category});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _name.text = widget.category!["name"];
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final data = {"name": _name.text.trim()};

    try {
      if (widget.category == null) {
        await admin.api.post("/api/category", data: data);
      } else {
        await admin.api.put("/api/category/${widget.category!['_id']}", data: data);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Category" : "Add Category")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Category name"),
                validator: (v) =>
                    v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Update" : "Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
