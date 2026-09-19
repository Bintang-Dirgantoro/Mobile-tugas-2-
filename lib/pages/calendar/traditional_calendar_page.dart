import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';

/// Halaman Kalender Tradisional Interaktif: Weton Jawa & Saka Bali
/// 
/// Layout:
/// - Bagian Atas: Kartu Hasil Rincian Weton Jawa / Saka Bali & Watak
/// - Bagian Bawah: Grid Kalender Bulanan Interaktif dengan navigasi terpusat (bebas redundansi tombol)
class TraditionalCalendarPage extends StatefulWidget {
  const TraditionalCalendarPage({super.key});

  @override
  State<TraditionalCalendarPage> createState() => _TraditionalCalendarPageState();
}

class _TraditionalCalendarPageState extends State<TraditionalCalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tanggal yang sedang dipilih
  DateTime _selectedDate = DateTime.now();
  // Bulan dan tahun yang sedang ditampilkan di grid kalender
  late DateTime _currentMonth;

  // 7 Hari Jawa & Neptu
  static const Map<int, Map<String, dynamic>> _javaneseDays = {
    DateTime.monday: {'name': 'Senin', 'neptu': 4, 'bali': 'Soma'},
    DateTime.tuesday: {'name': 'Selasa', 'neptu': 3, 'bali': 'Anggara'},
    DateTime.wednesday: {'name': 'Rabu', 'neptu': 7, 'bali': 'Buda'},
    DateTime.thursday: {'name': 'Kamis', 'neptu': 8, 'bali': 'Wraspati'},
    DateTime.friday: {'name': 'Jumat', 'neptu': 6, 'bali': 'Sukra'},
    DateTime.saturday: {'name': 'Sabtu', 'neptu': 9, 'bali': 'Saniscara'},
    DateTime.sunday: {'name': 'Minggu', 'neptu': 5, 'bali': 'Redite'},
  };

  // 5 Pasaran Jawa (Index terstandarisasi: 0: Legi s/d 4: Kliwon)
  static const List<Map<String, dynamic>> _pasaranList = [
    {'name': 'Legi', 'neptu': 5, 'bali': 'Umanis'},
    {'name': 'Pahing', 'neptu': 9, 'bali': 'Paing'},
    {'name': 'Pon', 'neptu': 7, 'bali': 'Pon'},
    {'name': 'Wage', 'neptu': 4, 'bali': 'Wage'},
    {'name': 'Kliwon', 'neptu': 8, 'bali': 'Kliwon'},
  ];

  // 30 Wuku Pawukon
  static const List<String> _wukuList = [
    'Sinta', 'Landep', 'Wukir', 'Kurantil', 'Tolu',
    'Gumbreg', 'Warigalit', 'Warigagung', 'Julangwangi', 'Sungsang',
    'Dungulan (Galungan)', 'Kuningan', 'Langkir', 'Medangsia', 'Pujut',
    'Pahang', 'Krulut', 'Merakih', 'Tambir', 'Medangkungan',
    'Maktal', 'Wuye', 'Manahil', 'Prangbakat', 'Bala',
    'Ugu', 'Wayang', 'Kelawu', 'Dukut', 'Watugunung'
  ];

  // 3 Triwara Bali
  static const List<String> _triwaraList = ['Pasah', 'Beteng', 'Kajeng'];

  // 12 Sasih Bali
  static const List<String> _sasihBali = [
    'Kasa (Pertama)', 'Karo (Kedua)', 'Katiga (Ketiga)', 'Kapat (Keempat)',
    'Kalima (Kelima)', 'Kanem (Keenam)', 'Kapitu (Ketujuh)', 'Kawolu (Kedelapan)',
    'Kasanga (Kesembilan)', 'Kadasa (Kesepuluh / Nyepi)', 'Jyestha (Kesebelas)', 'Sadha (Keduabelas)'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Perhitungan Kalender Tradisional ---

  Map<String, dynamic> _getPasaran(DateTime date) {
    final epoch = DateTime.utc(1970, 1, 1);
    final target = DateTime.utc(date.year, date.month, date.day);
    final diffDays = target.difference(epoch).inDays;
    final index = ((diffDays + 3) % 5 + 5) % 5;
    return _pasaranList[index];
  }

  String _getWuku(DateTime date) {
    final epoch = DateTime.utc(1970, 1, 1);
    final target = DateTime.utc(date.year, date.month, date.day);
    final diffDays = target.difference(epoch).inDays;
    final pawukonDay = ((diffDays + 32) % 210 + 210) % 210;
    final wukuIndex = (pawukonDay / 7).floor() % 30;
    return _wukuList[wukuIndex];
  }

  String _getTriwara(DateTime date) {
    final epoch = DateTime.utc(1970, 1, 1);
    final target = DateTime.utc(date.year, date.month, date.day);
    final diffDays = target.difference(epoch).inDays;
    final index = ((diffDays + 2) % 3 + 3) % 3;
    return _triwaraList[index];
  }

  String? _getBalineseHoliday(DateTime date) {
    final pasaran = _getPasaran(date)['bali'];
    final wuku = _getWuku(date);
    final triwara = _getTriwara(date);

    if (date.weekday == DateTime.wednesday && pasaran == 'Kliwon' && wuku.contains('Dungulan')) {
      return 'Hari Raya Galungan';
    }
    if (date.weekday == DateTime.saturday && pasaran == 'Kliwon' && wuku.contains('Kuningan')) {
      return 'Hari Raya Kuningan';
    }
    if (triwara == 'Kajeng' && pasaran == 'Kliwon') {
      return 'Kajeng Kliwon';
    }
    if (date.weekday == DateTime.saturday && pasaran == 'Umanis' && wuku.contains('Watugunung')) {
      return 'Hari Raya Saraswati';
    }
    if (date.weekday == DateTime.wednesday && pasaran == 'Kliwon' && wuku.contains('Sinta')) {
      return 'Hari Raya Pagerwesi';
    }
    if (date.weekday == DateTime.saturday && pasaran == 'Kliwon') {
      return 'Hari Tumpek';
    }
    return null;
  }

  Map<String, String> _getJavaneseCharacter(int totalNeptu) {
    switch (totalNeptu) {
      case 7:
        return {
          'title': 'Pendito Sakti (Lakuning Bumi)',
          'trait': 'Cenderung pendiam, berjiwa petualang, senang belajar hal baru, dan memiliki firasat tajam.',
          'advice': 'Cocok di bidang penelitian, penulisan, spiritual, atau profesi mandiri.',
        };
      case 8:
        return {
          'title': 'Lakuning Geni (Pemberani & Dinamis)',
          'trait': 'Bersemangat tinggi, tidak mudah menyerah, pemberani, berpendirian teguh, namun terkadang emosional.',
          'advice': 'Sangat tangguh sebagai pemimpin operasional, teknisi, dan wirausaha yang penuh tantangan.',
        };
      case 9:
        return {
          'title': 'Lakuning Angin (Luwes & Kreatif)',
          'trait': 'Lincah, mudah bergaul, berpikiran fleksibel, pandai merangkul orang lain, dan berjiwa merdeka.',
          'advice': 'Unggul di bidang komunikasi, pemasaran, diplomasi, seni kreatif, dan hubungan masyarakat.',
        };
      case 10:
        return {
          'title': 'Pendito Mbangun Teki (Tekun & Cerdas)',
          'trait': 'Berbudi luhur, suka menolong sesama, cerdas, tekun mencari ilmu, dan tidak gemar pamer.',
          'advice': 'Sangat cocok sebagai akademisi, pendidik, analis data, pengelola keuangan, dan konsultan.',
        };
      case 11:
        return {
          'title': 'Lakuning Setan (Tangkas & Pekerja Keras)',
          'trait': 'Sangat gesit bekerja, tidak kenal lelah, mandiri, berani mengambil risiko besar, dan teguh pada prinsip.',
          'advice': 'Sukses dalam dunia perdagangan bebas, kontraktor, logistik bisnis, dan wirausaha ekspansif.',
        };
      case 12:
        return {
          'title': 'Lakuning Kembang (Disukai Banyak Orang)',
          'trait': 'Menyenangkan, berhati lembut, setia kawan, menyejukkan hati, dan memiliki pesona karisma alami.',
          'advice': 'Cocok di industri hospitality, pelayanan pelanggan, desain estetik, dan perhotelan.',
        };
      case 13:
        return {
          'title': 'Lakuning Lintang (Karisma & Mandiri)',
          'trait': 'Mandiri, tidak suka diperintah orang lain, berwawasan luas, berdaya pikat tinggi, dan tekun.',
          'advice': 'Sangat ideal menjadi pemilik bisnis (founder), pemimpin independen, dan inovator produk.',
        };
      case 14:
        return {
          'title': 'Lakuning Mbulan (Bijaksana & Pengayom)',
          'trait': 'Penyejuk hati di kala gundah, pendengar setia, cerdas menata suasana, sabar, dan berpikiran tenang.',
          'advice': 'Sangat baik sebagai manajer sumber daya manusia, penasihat bisnis, mediator, dan pengajar.',
        };
      case 15:
        return {
          'title': 'Lakuning Srengenge (Dermawan & Berwibawa)',
          'trait': 'Menghangatkan sekitar, gemar menolong yang lemah, dermawan, berwibawa tinggi, dan disegani kawan.',
          'advice': 'Sangat dihormati di organisasi sosial, politik, pimpinan perusahaan, dan perintis usaha besar.',
        };
      case 16:
        return {
          'title': 'Lakuning Bumi (Penyabar & Kokoh)',
          'trait': 'Penyabar luar biasa, amanah, teguh memegang rahasia, berbudi luhur, dan menjadi tempat berteduh.',
          'advice': 'Cocok di sektor agraria, manajemen aset riil, perbankan, dan pengembang properti.',
        };
      case 17:
        return {
          'title': 'Lakuning Gunung (Pendirian Kuat & Hemat)',
          'trait': 'Pendirian teguh laksana gunung, cermat mengelola keuangan, berwibawa, dan tidak mudah terpengaruh tren.',
          'advice': 'Sangat tepat sebagai direktur keuangan, perencana anggaran, auditor, dan pengawas bisnis.',
        };
      case 18:
        return {
          'title': 'Lakuning Paripurna (Berwibawa Mutlak)',
          'trait': 'Karisma tingkat tinggi, pandangan hidup matang, disegani semua pihak, tegas, dan berbakat besar.',
          'advice': 'Cocok sebagai tokoh masyarakat, pimpinan tertinggi organisasi, dan pengambil keputusan strategis.',
        };
      default:
        return {
          'title': 'Pancasuda Luhur',
          'trait': 'Memiliki keunikan karakter tersendiri dengan potensi spiritual dan kecerdasan emosional tinggi.',
          'advice': 'Terus kembangkan potensi diri melalui ketekunan dan menjaga silaturahmi.',
        };
    }
  }

  // --- Aksi Navigasi Kalender ---

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = now;
      _currentMonth = DateTime(now.year, now.month, 1);
    });
  }

  Future<void> _pickAnyDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _currentMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayInfo = _javaneseDays[_selectedDate.weekday]!;
    final pasaranInfo = _getPasaran(_selectedDate);
    final totalNeptu = (dayInfo['neptu'] as int) + (pasaranInfo['neptu'] as int);
    final wukuName = _getWuku(_selectedDate);
    final triwaraName = _getTriwara(_selectedDate);
    final holidayName = _getBalineseHoliday(_selectedDate);

    // Kalender Saka Bali
    final saptawaraBali = dayInfo['bali'] as String;
    final pancawaraBali = pasaranInfo['bali'] as String;
    final int sakaYear = _selectedDate.month >= 4 ? _selectedDate.year - 78 : _selectedDate.year - 79;
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
            Tab(icon: Icon(Icons.brightness_7_outlined), text: 'Weton Jawa'),
            Tab(icon: Icon(Icons.temple_hindu_outlined), text: 'Saka Bali'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HASIL DETAIL DI ATAS (Weton Jawa atau Saka Bali)
            Container(
              color: AppColors.background,
              child: _tabController.index == 0
                  ? _buildWetonDetail(dayInfo, pasaranInfo, totalNeptu, wukuName)
                  : _buildSakaBaliDetail(
                      sakaYear,
                      saptawaraBali,
                      pancawaraBali,
                      triwaraName,
                      wukuName,
                      sasihName,
                      holidayName,
                    ),
            ),

            const SizedBox(height: 8),

            // 2. GRID KALENDER BULANAN DI BAWAH (Kontrol Tunggal & Bersih)
            _buildMonthlyCalendarSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Widget Detail Weton Jawa (Di Atas) ---

  Widget _buildWetonDetail(
    Map<String, dynamic> dayInfo,
    Map<String, dynamic> pasaranInfo,
    int totalNeptu,
    String wukuName,
  ) {
    final characterInfo = _getJavaneseCharacter(totalNeptu);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Weton Utama
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.card,
                  AppColors.accent.withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  '${dayInfo['name']} ${pasaranInfo['name']}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Wuku: $wukuName',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _neptuBadge('Hari', '${dayInfo['name']} (${dayInfo['neptu']})'),
                    const Text('+', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                    _neptuBadge('Pasaran', '${pasaranInfo['name']} (${pasaranInfo['neptu']})'),
                    const Text('=', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                    _neptuBadge('Total Neptu', '$totalNeptu', isTotal: true),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Karakter & Watak Weton Jawa
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
                  children: [
                    const Icon(Icons.psychology_outlined, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        characterInfo['title']!,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  characterInfo['trait']!,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          characterInfo['advice']!,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Detail Saka Bali (Di Atas) ---

  Widget _buildSakaBaliDetail(
    int sakaYear,
    String saptawaraBali,
    String pancawaraBali,
    String triwaraName,
    String wukuName,
    String sasihName,
    String? holidayName,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Utama Saka Bali
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.card,
                  AppColors.warning.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.temple_hindu, color: AppColors.warning, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Tahun $sakaYear Saka',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$saptawaraBali, $pancawaraBali',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (holidayName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⭐ $holidayName',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Rincian Wewaran Lengkap
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
                const Text(
                  'Unsur Wewaran & Penanggalan Bali:',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),
                _baliRow('Saptawara (7 Hari):', saptawaraBali),
                _baliRow('Pancawara (5 Pasaran):', pancawaraBali),
                _baliRow('Triwara (3 Hari):', triwaraName),
                _baliRow('Wuku (Siklus 210 Hari):', wukuName),
                _baliRow('Sasih (Bulan Saka):', sasihName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Grid Kalender Bulanan (Di Bawah) ---

  Widget _buildMonthlyCalendarSection() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final startingOffset = firstWeekday % 7; // 0 jika Minggu, 1 jika Senin, dst.
    final totalCells = startingOffset + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final now = DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          // Header Bulan & Navigasi Terpusat (Bebas Redundansi)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 22),
                onPressed: _previousMonth,
                tooltip: 'Bulan Sebelumnya',
              ),
              InkWell(
                onTap: _pickAnyDate,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(_currentMonth),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppColors.accent, size: 18),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary, size: 22),
                onPressed: _nextMonth,
                tooltip: 'Bulan Berikutnya',
              ),
              const Spacer(),
              // Tombol 'Hari Ini' Tunggal & Rapi
              TextButton.icon(
                onPressed: _goToToday,
                icon: const Icon(Icons.today, size: 14, color: AppColors.accent),
                label: const Text('Hari Ini', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Header Nama Hari (Min, Sen, Sel, Rab, Kam, Jum, Sab)
          Row(
            children: [
              _weekdayLabel('Min', isSunday: true),
              _weekdayLabel('Sen'),
              _weekdayLabel('Sel'),
              _weekdayLabel('Rab'),
              _weekdayLabel('Kam'),
              _weekdayLabel('Jum'),
              _weekdayLabel('Sab'),
            ],
          ),

          const SizedBox(height: 8),

          // Grid Tanggal & Pasaran
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startingOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;
              final isToday = cellDate.year == now.year &&
                  cellDate.month == now.month &&
                  cellDate.day == now.day;
              final isSunday = cellDate.weekday == DateTime.sunday;
              final cellPasaran = _getPasaran(cellDate);
              final cellHoliday = _getBalineseHoliday(cellDate);

              return InkWell(
                onTap: () {
                  setState(() => _selectedDate = cellDate);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : (isToday ? AppColors.accent.withValues(alpha: 0.15) : AppColors.background),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : (isToday ? AppColors.accent : AppColors.border),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Angka Tanggal
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isSunday ? Colors.redAccent : AppColors.textPrimary),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Nama Pasaran
                      Text(
                        cellPasaran['name'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      // Dot penanda jika ada hari raya / rerainan
                      if (cellHoliday != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _weekdayLabel(String text, {bool isSunday = false}) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isSunday ? Colors.redAccent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
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
