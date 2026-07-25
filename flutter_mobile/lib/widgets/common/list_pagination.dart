import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

const int kDefaultPageSize = 5;

/// Returns a slice of [items] for the given zero-based [page].
List<T> paginateSlice<T>(List<T> items, int page, {int pageSize = kDefaultPageSize}) {
  if (items.isEmpty) return [];
  final start = page * pageSize;
  if (start >= items.length) return [];
  final end = (start + pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}

int totalPagesFor(int itemCount, {int pageSize = kDefaultPageSize}) {
  if (itemCount <= 0) return 0;
  return (itemCount / pageSize).ceil();
}

/// Prev / Next bar shown below paginated lists.
class ListPaginationBar extends StatelessWidget {
  const ListPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    required this.onPageChanged,
    this.pageSize = kDefaultPageSize,
  });

  final int currentPage;
  final int totalItems;
  final ValueChanged<int> onPageChanged;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    final totalPages = totalPagesFor(totalItems, pageSize: pageSize);
    if (totalPages <= 1) return const SizedBox.shrink();

    final start = currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of $totalItems',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          IconButton(
            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous',
          ),
          Text(
            '${currentPage + 1} / $totalPages',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }
}
