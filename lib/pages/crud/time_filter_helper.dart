import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

/// Pilihan periode filter waktu
enum TimeFilterPeriod {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  thisYear,
  custom,
}

/// Helper utilitas untuk kalkulasi dimensi rentang waktu dan widget filter
class TimeFilterHelper {
  static final DateFormat _dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  /// Menghitung DateTimeRange aktif berdasarkan pilihan enum
  static DateTimeRange getRange(TimeFilterPeriod period, DateTimeRange? customRange) {
    final now = DateTime.now();
    switch (period) {
      case TimeFilterPeriod.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case TimeFilterPeriod.yesterday:
        final y = now.subtract(const Duration(days: 1));
        return DateTimeRange(
          start: DateTime(y.year, y.month, y.day, 0, 0, 0),
          end: DateTime(y.year, y.month, y.day, 23, 59, 59, 999),
        );
      case TimeFilterPeriod.thisWeek:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(monday.year, monday.month, monday.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
      case TimeFilterPeriod.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1, 0, 0, 0),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999),
        );
      case TimeFilterPeriod.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1, 0, 0, 0),
          end: DateTime(now.year, 12, 31, 23, 59, 59, 999),
        );
      case TimeFilterPeriod.custom:
        if (customRange != null) {
          return DateTimeRange(
            start: DateTime(customRange.start.year, customRange.start.month, customRange.start.day, 0, 0, 0),
            end: DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59, 999),
          );
        }
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day, 0, 0, 0),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
    }
  }

  /// Menghasilkan label teks ramah pengguna untuk periode aktif
  static String getLabel(TimeFilterPeriod period, DateTimeRange? customRange) {
    final range = getRange(period, customRange);
    switch (period) {
      case TimeFilterPeriod.today:
        return 'Hari Ini (${_dateFormat.format(range.start)})';
      case TimeFilterPeriod.yesterday:
        return 'Kemarin (${_dateFormat.format(range.start)})';
      case TimeFilterPeriod.thisWeek:
        return 'Minggu Ini (${_dateFormat.format(range.start)} - ${_dateFormat.format(range.end)})';
      case TimeFilterPeriod.thisMonth:
        return 'Bulan Ini (${DateFormat('MMMM yyyy', 'id_ID').format(range.start)})';
      case TimeFilterPeriod.thisYear:
        return 'Tahun Ini (${range.start.year})';
      case TimeFilterPeriod.custom:
        return '${_dateFormat.format(range.start)} - ${_dateFormat.format(range.end)}';
    }
  }

  /// Komponen UI filter chip bar yang dapat digunakan berulang
  static Widget buildFilterBar({
    required BuildContext context,
    required TimeFilterPeriod selectedPeriod,
    required DateTimeRange? customRange,
    required Function(TimeFilterPeriod period, DateTimeRange? custom) onPeriodChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodChip('Hari Ini', TimeFilterPeriod.today, selectedPeriod, onPeriodChanged, customRange),
                _buildPeriodChip('Kemarin', TimeFilterPeriod.yesterday, selectedPeriod, onPeriodChanged, customRange),
                _buildPeriodChip('Minggu Ini', TimeFilterPeriod.thisWeek, selectedPeriod, onPeriodChanged, customRange),
                _buildPeriodChip('Bulan Ini', TimeFilterPeriod.thisMonth, selectedPeriod, onPeriodChanged, customRange),
                _buildPeriodChip('Tahun Ini', TimeFilterPeriod.thisYear, selectedPeriod, onPeriodChanged, customRange),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.date_range, size: 16, color: AppColors.accent),
                    label: Text(
                      selectedPeriod == TimeFilterPeriod.custom ? 'Kustom (Aktif)' : 'Pilih Tanggal',
                      style: TextStyle(
                        color: selectedPeriod == TimeFilterPeriod.custom ? AppColors.accent : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: selectedPeriod == TimeFilterPeriod.custom
                        ? AppColors.accent.withValues(alpha: 0.25)
                        : AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selectedPeriod == TimeFilterPeriod.custom ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: customRange ??
                            DateTimeRange(
                              start: DateTime.now().subtract(const Duration(days: 7)),
                              end: DateTime.now(),
                            ),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.accent,
                                surface: AppColors.card,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        onPeriodChanged(TimeFilterPeriod.custom, picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Periode: ${getLabel(selectedPeriod, customRange)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildPeriodChip(
    String label,
    TimeFilterPeriod period,
    TimeFilterPeriod activePeriod,
    Function(TimeFilterPeriod, DateTimeRange?) onPeriodChanged,
    DateTimeRange? customRange,
  ) {
    final isSelected = activePeriod == period;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.accent.withValues(alpha: 0.25),
        checkmarkColor: AppColors.accent,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
        ),
        onSelected: (selected) {
          if (selected) {
            onPeriodChanged(period, customRange);
          }
        },
      ),
    );
  }
}
