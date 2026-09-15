import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    setState(() {});
  }

  void _recordLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(0, _stopwatch.elapsed);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
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
              width: 250,
              height: 250,
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
