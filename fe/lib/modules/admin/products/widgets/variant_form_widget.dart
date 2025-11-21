import 'package:flutter/material.dart';

class VariantFormWidget extends StatefulWidget {
  final List variants;

  const VariantFormWidget({super.key, required this.variants});

  @override
  State<VariantFormWidget> createState() => _VariantFormWidgetState();
}

class _VariantFormWidgetState extends State<VariantFormWidget> {
  final sizeOptions = ["S", "M", "L"];

  void addVariant() {
    setState(() {
      widget.variants.add({
        "size": "M",
        "color": "",
        "price": 0,
        "stock": 0,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Variants",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: addVariant,
              child: const Text("Thêm"),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ...widget.variants.asMap().entries.map((entry) {
          int index = entry.key;
          Map v = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Size
                  DropdownButtonFormField<String>(
                    value: v["size"],
                    decoration: const InputDecoration(labelText: "Size"),
                    items: sizeOptions.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        v["size"] = value;
                      });
                    },
                  ),

                  TextFormField(
                    initialValue: v["color"],
                    decoration: const InputDecoration(labelText: "Màu sắc"),
                    onChanged: (val) => v["color"] = val,
                  ),

                  TextFormField(
                    initialValue: v["price"].toString(),
                    decoration: const InputDecoration(labelText: "Giá"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => v["price"] = int.tryParse(val) ?? 0,
                  ),

                  TextFormField(
                    initialValue: v["stock"].toString(),
                    decoration: const InputDecoration(labelText: "Số lượng"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => v["stock"] = int.tryParse(val) ?? 0,
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          widget.variants.removeAt(index);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
