import 'package:flutter/material.dart';

/// =============================================================
///  COMMON TABLE (DataTable + Phân trang + Hover + No-Sort Header)
///  - Header chỉ hiển thị, không bấm để sort
/// =============================================================
class CommonTable extends StatefulWidget {
  final List<String> columns;              // Tiêu đề cột
  final List<List<dynamic>> rows;          // Dữ liệu bảng
  final List<int> pageSizes;               // Tuỳ chọn số dòng / trang

  const CommonTable({
    super.key,
    required this.columns,
    required this.rows,
    this.pageSizes = const [10, 20, 50],
  });

  @override
  State<CommonTable> createState() => _CommonTableState();
}

class _CommonTableState extends State<CommonTable> {
  int pageSize = 10;
  int page = 0;

  @override
  void initState() {
    super.initState();
    pageSize = widget.pageSizes.first;
  }

  // =============================================================
  // PHÂN TRANG
  // =============================================================
  List<List<dynamic>> get pagedRows {
    final begin = page * pageSize;
    final end = (begin + pageSize).clamp(0, widget.rows.length);
    return widget.rows.sublist(begin, end);
  }

  int get totalPages => (widget.rows.length / pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // =============================================================
          // CHỌN SỐ DÒNG / TRANG
          // =============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<int>(
                value: pageSize,
                items: widget.pageSizes
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text("$s dòng / trang"),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      pageSize = v;
                      page = 0;
                    });
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =============================================================
          // TABLE
          // =============================================================
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                // 🚫 TẮT SORT — không setup sortColumnIndex hoặc onSort
                sortColumnIndex: null,
                sortAscending: true,

                headingRowColor: WidgetStateProperty.all(
                  theme.primary.withOpacity(0.1),
                ),
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),

                // ❌ Không có onSort trong DataColumn
                columns: widget.columns
                    .map(
                      (label) => DataColumn(
                        label: Text(label),
                      ),
                    )
                    .toList(),

                rows: pagedRows.map((cells) {
                  return DataRow(
                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.blue.withOpacity(0.05);
                      }
                      return Colors.white;
                    }),
                    cells: cells
                        .map(
                          (cell) =>
                              DataCell(cell is Widget ? cell : Text(cell.toString())),
                        )
                        .toList(),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // =============================================================
          // THANH PHÂN TRANG
          // =============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: page > 0 ? () => setState(() => page--) : null,
              ),
              Text(
                "Trang ${page + 1} / $totalPages",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    page < totalPages - 1 ? () => setState(() => page++) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
