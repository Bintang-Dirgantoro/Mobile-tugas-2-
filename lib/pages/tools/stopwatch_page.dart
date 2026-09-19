import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/app_colors.dart';

/// Halaman Aplikasi Stopwatch (Bottom Nav Tab 2)
/// 
/// Fitur:
/// 1. Tampilan digital presisi: Menit, Detik, dan Ratusan Milidetik (MM:SS.ms).
/// 2. Kontrol: Start, Pause, Resume, Reset, dan Catat Putaran (Lap).
/// 3. Lap Times: Daftar putaran waktu dengan penanda putaran tercepat (hijau) dan terlambat (merah).
/// 4. Resource cleanup: Pembatalan `Timer.periodic` di fungsi `dispose()` untuk mencegah kebocoran memori.
class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  // Daftar Lap Time: menyimpan durasi waktu per putaran
  final List<Duration> _laps = [];

  // Waktu awal yang dapat diatur pengguna
  Duration _initialTime = Duration.zero;

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  void _pauseTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _resetTimer() {
    _stopwatch.reset();
    _timer?.cancel();
    _laps.clear();
    _initialTime = Duration.zero;
    setState(() {});
  }

  void _recordLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _stopwatch.elapsed);
      });
    }
  }

  Future<void> _showTimePickerDialog() async {
    final TextEditingController hourController = TextEditingController(text: '00');
    final TextEditingController minuteController = TextEditingController(text: '00');
    final TextEditingController secondController = TextEditingController(text: '00');

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.edit_outlined, color: AppColors.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Atur Waktu Awal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTeal,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hourController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        hintText: 'jj',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: minuteController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        hintText: 'mm',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: secondController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 2,
                      decoration: const InputDecoration(
                        hintText: 'dd',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      ),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final int? hour = int.tryParse(hourController.text);
                final int? minute = int.tryParse(minuteController.text);
                final int? second = int.tryParse(secondController.text);
                if (hour == null || minute == null || second == null) return;
                if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) return;
                setState(() {
                  _initialTime = Duration(hours: hour, minutes: minute, seconds: second);
                  _stopwatch.reset();
                  _laps.clear();
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                'Set',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final total = _initialTime + duration;
    final days = total.inDays;
    final hours = twoDigits(total.inHours.remainder(24));
    final minutes = twoDigits(total.inMinutes.remainder(60));
    final seconds = twoDigits(total.inSeconds.remainder(60));
    final milliseconds = (total.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    if (days > 0) {
      return '$days:$hours:$minutes:$seconds.$milliseconds';
    }
    return '$hours:$minutes:$seconds.$milliseconds';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _stopwatch.isRunning;
    final isStarted = _stopwatch.elapsedMilliseconds > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aplikasi Stopwatch'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // Tampilan Lingkaran Stopwatch Digital
          Center(
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.card,
                border: Border.all(
                  color: isRunning ? AppColors.accent : AppColors.border,
                  width: 3,
                ),
                boxShadow: isRunning
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_stopwatch.elapsed),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRunning ? 'BERJALAN' : (isStarted ? 'DIJEDA' : 'SIAP'),
                    style: TextStyle(
                      color: isRunning
                          ? AppColors.success
                          : (isStarted ? AppColors.warning : AppColors.textSecondary),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Tombol Kontrol
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol Reset / Lap
              ElevatedButton(
                onPressed: !isStarted
                    ? null
                    : (isRunning ? _recordLap : _resetTimer),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: AppColors.card,
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Icon(
                  isRunning ? Icons.flag_outlined : Icons.replay,
                  size: 24,
                  color: !isStarted ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 32),

              // Tombol Start / Pause
              ElevatedButton(
                onPressed: isRunning ? _pauseTimer : _startTimer,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                  backgroundColor: isRunning ? AppColors.warning : AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: Icon(
                  isRunning ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tombol untuk memunculkan dialog atur waktu awal
          TextButton.icon(
            onPressed: _showTimePickerDialog,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Atur Waktu Awal'),
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.border),

          // Daftar Putaran (Lap Times)
          Expanded(
            child: _laps.isEmpty
                ? Center(
                    child: Text(
                      isStarted
                          ? 'Tekan tombol bendera untuk mencatat putaran'
                          : 'Belum ada putaran waktu dicatat',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: _laps.length,
                    separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final lapNum = _laps.length - index;
                      final lapTime = _laps[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Putaran $lapNum',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            Text(
                              _formatTime(lapTime),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}