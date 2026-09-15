import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// Halaman Konversi Kalender Weton Jawa & Kalender Saka Bali
/// 
/// Catatan Perhitungan & Logika Tradisional:
/// 1. Kalender Weton Jawa:
///    - Dihitung dari kombinasi 7 Hari Saptawara (Senin-Minggu) dan 5 Hari Pancawara/Pasaran (Legi, Pahing, Pon, Wage, Kliwon).
///    - Menggunakan patokan referensi Epoch (1 Januari 1970 = Kamis Pahing) dengan modulus 5.
///    - Menghitung Total Nilai Neptu (Neptu Hari + Neptu Pasaran) serta watak/karakter weton.
/// 2. Kalender Saka Bali:
///    - Tahun Saka = Tahun Masehi - 78 (disesuaikan dengan pergantian Sasih Kadasa/Nyepi).
///    - Menghitung Saptawara Bali (Redite s/d Saniscara) dan Pancawara Bali (Umanis, Paing, Pon, Wage, Kliwon).
///    - Menghitung 30 Wuku Pawukon (210 hari siklus) dan 12 Sasih Bali.
class TraditionalCalendarPage extends StatefulWidget {
  const TraditionalCalendarPage({super.key});

  @override
  State<TraditionalCalendarPage> createState() => _TraditionalCalendarPageState();
}

class _TraditionalCalendarPageState extends State<TraditionalCalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  // Data Neptu Hari Jawa
  final Map<int, Map<String, dynamic>> _javaneseDays = {
    DateTime.monday: {'name': 'Senin', 'neptu': 4},
    DateTime.tuesday: {'name': 'Selasa', 'neptu': 3},
    DateTime.wednesday: {'name': 'Rabu', 'neptu': 7},
    DateTime.thursday: {'name': 'Kamis', 'neptu': 8},
    DateTime.friday: {'name': 'Jumat', 'neptu': 6},
    DateTime.saturday: {'name': 'Sabtu', 'neptu': 9},
    DateTime.sunday: {'name': 'Minggu', 'neptu': 5},
  };

  // Data Pasaran Jawa (1 Jan 1970 = Pahing)
  final List<Map<String, dynamic>> _pasaranList = [
    {'name': 'Pahing', 'neptu': 9, 'bali': 'Paing'},
    {'name': 'Pon', 'neptu': 7, 'bali': 'Pon'},
    {'name': 'Wage', 'neptu': 4, 'bali': 'Wage'},
    {'name': 'Kliwon', 'neptu': 8, 'bali': 'Kliwon'},
    {'name': 'Legi', 'neptu': 5, 'bali': 'Umanis'},
  ];

  // 30 Wuku Pawukon (Jawa & Bali)
  final List<String> _wukuList = [
    'Sinta', 'Landep', 'Wukir', 'Kurantil', 'Tolu',
    'Gumbreg', 'Warigalit', 'Warigagung', 'Julangwangi', 'Sungsang',
    'Dungulan (Galungan)', 'Kuningan', 'Langkir', 'Medangsia', 'Pujut',
    'Pahang', 'Krulut', 'Merakih', 'Tambir', 'Medangkungan',
    'Maktal', 'Wuye', 'Manahil', 'Prangbakat', 'Bala',
    'Ugu', 'Wayang', 'Kelawu', 'Dukut', 'Watugunung'
  ];

  // 7 Saptawara Bali
  final Map<int, String> _saptawaraBali = {
    DateTime.sunday: 'Redite',
    DateTime.monday: 'Soma',
    DateTime.tuesday: 'Anggara',
    DateTime.wednesday: 'Buda',
    DateTime.thursday: 'Wraspati',
    DateTime.friday: 'Sukra',
    DateTime.saturday: 'Saniscara',
  };

  // 12 Sasih Bali
  final List<String> _sasihBali = [
    'Kasa (Pertama)', 'Karo (Kedua)', 'Katiga (Ketiga)', 'Kapat (Keempat)',
    'Kalima (Kelima)', 'Kanem (Keenam)', 'Kapitu (Ketujuh)', 'Kawolu (Kedelapan)',
    'Kasanga (Kesembilan)', 'Kadasa (Kesepuluh / Nyepi)', 'Jyestha (Kesebelas)', 'Sadha (Keduabelas)'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Menghitung Pasaran dari tanggal tertentu
  Map<String, dynamic> _getPasaran(DateTime date) {
    // Patokan Epoch: 1 Jan 1970 = Pahing (Index 0)
    final epoch = DateTime.utc(1970, 1, 1);
    final target = DateTime.utc(date.year, date.month, date.day);
    final diffDays = target.difference(epoch).inDays;
    final index = (diffDays % 5 + 5) % 5;
    return _pasaranList[index];
  }

  /// Menghitung Wuku Pawukon (Siklus 210 hari)
  String _getWuku(DateTime date) {
    // Patokan referensi Pawukon:
    // 1 Januari 1970 adalah Wuku Landep hari ke-5 (Kamis).
    // Landep adalah wuku index ke-1.
    final epoch = DateTime.utc(1970, 1, 1);
    final target = DateTime.utc(date.year, date.month, date.day);
    final diffDays = target.difference(epoch).inDays;
    
    // Offset dari hari Minggu Wuku Sinta (siklus awal)
    // 1 Jan 1970 berjarak 11 hari dari awal siklus Sinta terdekat
    final pawukonDay = (diffDays + 11) % 210;
    final wukuIndex = (pawukonDay / 7).floor() % 30;
    return _wukuList[wukuIndex];
  }

  /// Interpretasi watak dasar dari total Neptu Jawa
  String _getNeptuDescription(int totalNeptu) {
    if (totalNeptu <= 10) {
      return 'Karakter Pendiam, tekun, hemat, dan memiliki pendirian kuat.';
    } else if (totalNeptu <= 14) {
      return 'Karakter Luwes bergaul, berjiwa pemimpin, kreatif, dan suka menolong.';
    } else {
      return 'Karakter Karismatik, berpikiran luas, berani mengambil risiko, dan berwibawa tinggi.';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayInfo = _javaneseDays[_selectedDate.weekday]!;
    final pasaranInfo = _getPasaran(_selectedDate);
    final totalNeptu = (dayInfo['neptu'] as int) + (pasaranInfo['neptu'] as int);
    final wukuName = _getWuku(_selectedDate);

    // Data Kalender Saka Bali
    final saptawara = _saptawaraBali[_selectedDate.weekday]!;
    final pancawara = pasaranInfo['bali'] as String;
    // Penentuan tahun saka kasar (Masehi - 78)
    final int sakaYear = _selectedDate.month >= 4 ? _selectedDate.year - 78 : _selectedDate.year - 79;
    // Penentuan perkiraan Sasih Bali berdasarkan bulan Masehi
    final sasihIndex = (_selectedDate.month + 5) % 12;
    final sasihName = _sasihBali[sasihIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Tradisional'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.wb_sunny_outlined), text: 'Weton Jawa'),
            Tab(icon: Icon(Icons.temple_hindu_outlined), text: 'Saka Bali'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selector Tanggal Global
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: AppColors.card,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Masehi:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar, size: 16, color: Colors.white),
                  label: const Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                ),
              ],
            ),
          ),

          // Konten Tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWetonTab(dayInfo, pasaranInfo, totalNeptu, wukuName),
                _buildSakaBaliTab(sakaYear, saptawara, pancawara, wukuName, sasihName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWetonTab(
    Map<String, dynamic> dayInfo,
    Map<String, dynamic> pasaranInfo,
    int totalNeptu,
    String wukuName,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Utama Weton
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.card,
                  AppColors.accent.withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent),
            ),
            child: Column(
              children: [
                const Text('Weton Kelahiran / Hari Ini',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  '${dayInfo['name']} ${pasaranInfo['name']}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Wuku: $wukuName',
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _neptuBadge('Hari', '${dayInfo['name']} (${dayInfo['neptu']})'),
                    const Text('+', style: TextStyle(color: AppColors.textSecondary, fontSize: 20)),
                    _neptuBadge('Pasaran', '${pasaranInfo['name']} (${pasaranInfo['neptu']})'),
                    const Text('=', style: TextStyle(color: AppColors.textSecondary, fontSize: 20)),
                    _neptuBadge('Total Neptu', '$totalNeptu', isTotal: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Deskripsi Watak
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
                Row(
                  children: const [
                    Icon(Icons.psychology_outlined, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text('Watak Berdasarkan Neptu',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getNeptuDescription(totalNeptu),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSakaBaliTab(
    int sakaYear,
    String saptawara,
    String pancawara,
    String wukuName,
    String sasihName,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Utama Saka Bali
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.card,
                  AppColors.warning.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.warning),
            ),
            child: Column(
              children: [
                const Icon(Icons.temple_hindu, color: AppColors.warning, size: 40),
                const SizedBox(height: 10),
                const Text('Kalender Pawukon & Saka Bali',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  'Tahun $sakaYear Saka',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$saptawara, $pancawara',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Detail Unsur Wewaran Bali
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
                const Text('Unsur Penanggalan Bali:',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                _baliRow('Saptawara (7 Hari):', saptawara),
                _baliRow('Pancawara (5 Pasaran):', pancawara),
                _baliRow('Wuku (Siklus 210 Hari):', wukuName),
                _baliRow('Sasih (Bulan Saka):', sasihName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _neptuBadge(String label, String value, {bool isTotal = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isTotal ? AppColors.accent : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isTotal ? AppColors.accent : AppColors.border),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: isTotal ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _baliRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
