import 'package:flutter/material.dart';

import '../../models/doctor_model.dart';
import '../../services/doctor_service.dart';
import 'top_doctor_card.dart';

/// Home top doctors: max 10 in **2 horizontal rows** — same [TopDoctorCard] (120px) as RN.
class TopDoctorsGrid extends StatelessWidget {
  const TopDoctorsGrid({super.key, required this.doctors, required this.onDoctorTap});

  static const int maxDoctors = DoctorService.homeTopDoctorLimit;
  static const int rowCount = 2;
  static const double _gap = 12;
  static const double _rowGap = 16;

  final List<DoctorModel> doctors;
  final void Function(DoctorModel doctor) onDoctorTap;

  @override
  Widget build(BuildContext context) {
    final list = doctors.length > maxDoctors ? doctors.sublist(0, maxDoctors) : doctors;
    if (list.isEmpty) return const SizedBox.shrink();

    final perRow = (list.length / rowCount).ceil();
    final rows = <List<DoctorModel>>[];
    for (var r = 0; r < rowCount; r++) {
      final start = r * perRow;
      if (start >= list.length) break;
      final end = start + perRow > list.length ? list.length : start + perRow;
      rows.add(list.sublist(start, end));
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final row = entry.value;
        return Padding(
          padding: EdgeInsets.only(top: entry.key > 0 ? _rowGap : 0, bottom: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: row.asMap().entries.map((cell) {
                return Padding(
                  padding: EdgeInsets.only(right: cell.key < row.length - 1 ? _gap : 0),
                  child: TopDoctorCard(
                    doctor: cell.value,
                    onTap: () => onDoctorTap(cell.value),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }
}
