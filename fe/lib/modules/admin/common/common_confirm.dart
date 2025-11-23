import 'package:flutter/material.dart';

/// ----------------------------------------------------------------
/// POPUP XÁC NHẬN DÙNG CHUNG (BẢN NGẮN CHIỀU NGANG)
/// ----------------------------------------------------------------
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  Color? confirmColor,
  String confirmText = "Xác nhận",
  String cancelText = "Hủy",
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          final theme = Theme.of(context).colorScheme;

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 60), // ➜ GIỚI HẠN CHIỀU NGANG
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 300,    // 🎉 GIỚI HẠN CHIỀU RỘNG POPUP
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 34,
                      color: confirmColor ?? theme.primary,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            cancelText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            backgroundColor: confirmColor ?? theme.primary,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(confirmText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ) ??
      false;
}
