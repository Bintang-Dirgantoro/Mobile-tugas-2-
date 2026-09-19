import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../theme/app_colors.dart';

/// Halaman Konversi Tanggal Hijriah & Kalkulator Umur Presisi
/// 
/// Catatan Error Handling & Tipe Data:
/// 1. Proteksi Tanggal Masa Depan (Future Date Guard):
///    - Tanggal lahir tidak boleh melebihi `DateTime.now()`.
/// 2. Live Real-Time Ticker:
///    - Detik diperbarui secara live setiap detik menggunakan `Timer.periodic`.
/// 3. Perhitungan Presisi (Tahun, Bulan, Hari, Jam, Menit, Detik):
///    - Menghitung selisih kalender yang akurat dengan memperhitungkan jumlah hari per bulan dan tahun kabisat.
/// 4. Algoritma Kalender Hijriah:
///    - Menggunakan konversi Julian Day Number (JDN) Tabular Astronomis untuk menentukan
///      hari, bulan (12 bulan Hijriah), dan tahun Hijriah.
class DateConversionPage extends StatefulWidget {
  const DateConversionPage({super.key});

  @override
  State<DateConversionPage> createState() => _DateConversionPageState();
}

class _DateConversionPageState extends State<DateConversionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- State Tab 1: Konversi Hijriah ---
  DateTime _selectedHijriDate = DateTime.now();
  Map<String, dynamic>? _hijriResult;

  // --- State Tab 2: Kalkulator Umur ---
  DateTime? _birthDate;
  TimeOfDay _birthTime = const TimeOfDay(hour: 0, minute: 0);
  Timer? _liveTimer;
  Map<String, dynamic>? _ageResult;
  String? _ageError;

  final List<String> _hijriMonthNames = [
    'Muharram',
    'Safar',
    "Rabi'ul-Awwal",
    "Rabi'ul-Akhir",
    'Jumadil-Awwal',
    'Jumadil-Akhir',
    'Rajab',
    "Sya'ban",
    'Ramadhan',
    'Syawal',
    "Dzulqa'dah",
    'Dzulhijjah',
  ];

  final List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateHijri(_selectedHijriDate);

    // Live timer untuk update detik usia
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_birthDate != null && mounted) {
        _updateAgeCalculation();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  // ==========================================
  // 1. ALGORITMA KONVERSI HIJRIAH
  // ==========================================
  void _calculateHijri(DateTime gregorianDate) {
    // Menggunakan package hijri untuk konversi yang akurat
    final hijriDate = HijriCalendar.fromDate(gregorianDate);
    
    int hDay = hijriDate.hDay;
    int hMonth = hijriDate.hMonth;
    int hYear = hijriDate.hYear;

    setState(() {
      _hijriResult = {
        'day': hDay,
        'monthIndex': hMonth,
        'monthName': _hijriMonthNames[hMonth - 1],
        'year': hYear,
        'dayName': _dayNames[gregorianDate.weekday - 1],
      };
    });
  }

  // ==========================================
  // 2. PERHITUNGAN USIA DETAIL (REALTIME)
  // ==========================================
  void _updateAgeCalculation() {
    if (_birthDate == null) return;

    final birthDateTime = DateTime(
      _birthDate!.year,
      _birthDate!.month,
      _birthDate!.day,
      _birthTime.hour,
      _birthTime.minute,
    );

    final now = DateTime.now();

    // Validasi masa depan
    if (birthDateTime.isAfter(now)) {
      setState(() {
        _ageError = 'Tanggal lahir tidak boleh di masa depan!';
        _ageResult = null;
      });
      return;
    }

    _ageError = null;

    // Perhitungan Tahun, Bulan, Hari
    int years = now.year - birthDateTime.year;
    int months = now.month - birthDateTime.month;
    int days = now.day - birthDateTime.day;
    int hours = now.hour - birthDateTime.hour;
    int minutes = now.minute - birthDateTime.minute;
    int seconds = now.second - birthDateTime.second;

    if (seconds < 0) {
      seconds += 60;
      minutes -= 1;
    }
    if (minutes < 0) {
      minutes += 60;
      hours -= 1;
    }
    if (hours < 0) {
      hours += 24;
      days -= 1;
    }
    if (days < 0) {
      // Ambil jumlah hari di bulan sebelumnya
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }

    final totalDifference = now.difference(birthDateTime);
    final totalDays = totalDifference.inDays;
    final totalHours = totalDifference.inHours;

    // Hitung waktu menuju ulang tahun berikutnya
    DateTime nextBirthday = DateTime(now.year, birthDateTime.month, birthDateTime.day);
    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthDateTime.month, birthDateTime.day);
    }
    final daysToNextBirthday = nextBirthday.difference(now).inDays;

    setState(() {
      _ageResult = {
        'years': years,
        'months': months,
        'days': days,
        'hours': hours,
        'minutes': minutes,
        'seconds': seconds,
        'totalDays': totalDays,
        'totalHours': totalHours,
        'dayBorn': _dayNames[birthDateTime.weekday - 1],
        'daysToNextBirthday': daysToNextBirthday,
      };
    });
  }

  Future<void> _pickHijriSourceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedHijriDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedHijriDate = picked);
      _calculateHijri(picked);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2004, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now, // Proteksi tidak bisa memilih masa depan
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
      _updateAgeCalculation();
    }
  }

  Future<void> _pickBirthTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _birthTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _birthTime = picked);
      _updateAgeCalculation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konversi Tanggal & Umur'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.nights_stay_outlined), text: 'Kalender Hijriah'),
            Tab(icon: Icon(Icons.cake_outlined), text: 'Kalkulator Umur'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHijriTab(),
          _buildAgeTab(),
        ],
      ),
    );
  }

  Widget _buildHijriTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pemilih Tanggal Masehi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Tanggal Masehi:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedHijriDate),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickHijriSourceDate,
                      icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                      label: const Text('Ubah', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Hasil Konversi Hijriah
          if (_hijriResult != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.card,
                    AppColors.accent.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mosque_outlined, size: 48, color: AppColors.accent),
                  const SizedBox(height: 12),
                  const Text('Tanggal Kalender Hijriah',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '${_hijriResult!['day']} ${_hijriResult!['monthName']} ${_hijriResult!['year']} H',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hari ${_hijriResult!['dayName']}',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  Text(
                    'Bulan ke-${_hijriResult!['monthIndex']} dalam tahun Hijriah (${_hijriResult!['monthName']})',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pemilih Tanggal & Waktu Lahir
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Masukkan Waktu Kelahiran Anda:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickBirthDate,
                        icon: const Icon(Icons.calendar_month, color: AppColors.accent, size: 18),
                        label: Text(
                          _birthDate == null
                              ? 'Pilih Tanggal Lahir'
                              : DateFormat('d MMM yyyy', 'id_ID').format(_birthDate!),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _pickBirthTime,
                      icon: const Icon(Icons.access_time, color: AppColors.accent, size: 18),
                      label: Text(
                        _birthTime.format(context),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_ageError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger),
              ),
              child: Text(_ageError!, style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),

          if (_ageResult != null) ...[
            // Counter Umur Presisi (Realtime Ticker)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Lahir pada hari ${_ageResult!['dayBorn']}',
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid Unit Umur: Tahun, Bulan, Hari, Jam, Menit, Detik
                  Row(
                    children: [
                      _ageUnitBox('${_ageResult!['years']}', 'TAHUN'),
                      const SizedBox(width: 8),
                      _ageUnitBox('${_ageResult!['months']}', 'BULAN'),
                      const SizedBox(width: 8),
                      _ageUnitBox('${_ageResult!['days']}', 'HARI'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ageUnitBox('${_ageResult!['hours']}', 'JAM'),
                      const SizedBox(width: 8),
                      _ageUnitBox('${_ageResult!['minutes']}', 'MENIT'),
                      const SizedBox(width: 8),
                      _ageUnitBox('${_ageResult!['seconds']}', 'DETIK', isAccent: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),

                  // Info Tambahan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Hari Hidup',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${_ageResult!['totalDays']} Hari',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: AppColors.border),
                      Column(
                        children: [
                          const Text('Ulang Tahun Berikutnya',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${_ageResult!['daysToNextBirthday']} Hari lagi',
                              style: const TextStyle(
                                  color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ageUnitBox(String value, String label, {bool isAccent = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isAccent ? AppColors.accent.withValues(alpha: 0.2) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isAccent ? AppColors.accent : AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: isAccent ? AppColors.accent : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
