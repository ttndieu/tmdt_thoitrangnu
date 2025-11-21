import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_provider.dart';
import 'category_form_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late Future<List<dynamic>> futureCategories;

  @override
  void initState() {
    super.initState();
    futureCategories = loadCategories();
  }

  Future<List<dynamic>> loadCategories() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final res = await admin.api.get("/api/category");
    return res.data["data"];
  }

  void reload() {
    setState(() {
      futureCategories = loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Categories")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryFormPage()),
          );
          reload();
        },
      ),
      body: FutureBuilder(
        future: futureCategories,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!;

          if (categories.isEmpty) {
            return const Center(child: Text("Không có danh mục nào"));
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (_, index) {
              final c = categories[index];

              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(c["name"]),
                subtitle: Text(c["slug"]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // edit
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryFormPage(category: c),
                          ),
                        );
                        reload();
                      },
                    ),
                    // delete
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final admin = Provider.of<AdminProvider>(context, listen: false);
                        await admin.api.delete("/api/category/${c['_id']}");
                        reload();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
