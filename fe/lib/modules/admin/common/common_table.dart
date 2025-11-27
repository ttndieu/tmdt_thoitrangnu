import 'package:flutter/material.dart';

class CommonTable extends StatefulWidget {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final List<int> pageSizes;

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

  /// Controller riêng → tránh lỗi ScrollPosition null
  final ScrollController verticalCtrl = ScrollController();
  final ScrollController horizontalCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    pageSize = widget.pageSizes.first;
  }

  @override
  void dispose() {
    verticalCtrl.dispose();
    horizontalCtrl.dispose();
    super.dispose();
  }

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
          // =============== CHỌN SỐ DÒNG / TRANG ===============
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<int>(
                value: pageSize,
                items: widget.pageSizes
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text("$s dòng"),
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

          // const SizedBox(height: 10),

          // =============== BẢNG + CUỘN DỌC + NGANG ===============
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minWidth = constraints.maxWidth;

                return Scrollbar(
                  controller: verticalCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: verticalCtrl,
                    scrollDirection: Axis.vertical,

                    child: SingleChildScrollView(
                      controller: horizontalCtrl,
                      scrollDirection: Axis.horizontal,

                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: minWidth,
                          maxWidth: double.infinity,
                        ),

                        child: DataTable(
                          columnSpacing: 24,
                          dataRowMinHeight: 56,
                          dataRowMaxHeight: 64,

                          headingRowColor: WidgetStateProperty.all(
                            theme.primary.withOpacity(0.12),
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primary,
                            fontSize: 14,
                          ),

                          columns: widget.columns
                              .map((label) => DataColumn(label: Text(label)))
                              .toList(),

                          rows: pagedRows.map((cells) {
                            return DataRow(
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.blue.withOpacity(0.05);
                                }
                                return Colors.white;
                              }),
                              cells: cells.map((cell) {
                                if (cell is Widget) return DataCell(cell);
                                return DataCell(
                                  Text(cell.toString(),
                                      style: const TextStyle(fontSize: 14)),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // =============== PHÂN TRANG ===============
          const SizedBox(height: 10),
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
