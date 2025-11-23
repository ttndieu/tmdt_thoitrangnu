// lib/modules/admin/products/components/image_manager.dart
import 'package:flutter/material.dart';

class ImageManager extends StatelessWidget {
  final List<Map<String, dynamic>> images;
  final VoidCallback onPick;
  final void Function(int) onDelete;
  final void Function(int) onReplace;
  final bool loading;

  const ImageManager({
    super.key,
    required this.images,
    required this.onPick,
    required this.onDelete,
    required this.onReplace,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ảnh sản phẩm", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < images.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      images[i]["url"] ?? "",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => onDelete(i),
                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => onReplace(i),
                      child: const CircleAvatar(radius: 12, backgroundColor: Colors.blue, child: Icon(Icons.refresh, size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            GestureDetector(
              onTap: loading ? null : onPick,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
                child: loading ? const Center(child: CircularProgressIndicator()) : const Icon(Icons.add_a_photo),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
