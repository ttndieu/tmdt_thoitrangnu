import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../admin_provider.dart';
import 'category_form_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  static CategoriesPageState? instance;

  List<dynamic> categories = [];
  List<dynamic> original = []; // bản gốc
  late Future<void> loader;

  @override
  void initState() {
    super.initState();
    instance = this;
    loader = loadCategories();
  }

  Future<void> loadCategories() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final res = await admin.api.get("/api/category");

    setState(() {
      original = List.from(res.data["data"]);
      categories = List.from(original);
    });
  }

  // FILTER SEARCH
  void filter(String query) {
    setState(() {
      if (query.isEmpty) {
        categories = List.from(original);
      } else {
        final lower = query.toLowerCase();
        categories = original.where((c) {
          final name = (c["name"] ?? "").toString().toLowerCase();
          final slug = (c["slug"] ?? "").toString().toLowerCase();
          return name.contains(lower) || slug.contains(lower);
        }).toList();
      }
    });
  }

  void reload() => setState(() => loader = loadCategories());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh mục")),
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
        future: loader,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categories.isEmpty) {
            return const Center(child: Text("Không có danh mục"));
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

                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final admin = Provider.of<AdminProvider>(
                            context,
                            listen: false);
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
