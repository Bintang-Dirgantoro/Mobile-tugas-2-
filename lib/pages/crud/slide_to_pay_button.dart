import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

/// Widget Tombol Geser Pelunasan bergaya Gojek (Slide to Pay)
///
/// Pengguna/Kasir menggeser tombol knob dari kiri ke kanan untuk melunasi transaksi.
/// Jika mencapai batas minimal (80%), tombol akan terkunci dan memicu [onConfirmed].
class SlideToPayButton extends StatefulWidget {
  final Future<void> Function() onConfirmed;
  final String label;
  final String completedLabel;
  final double height;
  final Color baseColor;
  final Color activeColor;

  const SlideToPayButton({
    super.key,
    required this.onConfirmed,
    this.label = 'Geser untuk Melunasi',
    this.completedLabel = 'Memproses Pembayaran...',
    this.height = 56.0,
    this.baseColor = const Color(0xFF1E293B),
    this.activeColor = const Color(0xFF10B981), // Emerald / Gojek Green
  });

  @override
  State<SlideToPayButton> createState() => _SlideToPayButtonState();
}

class _SlideToPayButtonState extends State<SlideToPayButton>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isCompleted = false;
  bool _isLoading = false;

  late AnimationController _springController;
  late Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _springController.addListener(() {
      setState(() {
        _dragOffset = _springAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isCompleted || _isLoading) return;

    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted || _isLoading) return;

    // Ambang batas aktivasi: 80% dari total panjang lintasan
    final threshold = maxDrag * 0.80;

    if (_dragOffset >= threshold) {
      // Kunci ke posisi penuh dan picu aksi konfirmasi
      setState(() {
        _dragOffset = maxDrag;
        _isCompleted = true;
        _isLoading = true;
      });

      HapticFeedback.heavyImpact();

      widget.onConfirmed().catchError((error) {
        // Jika gagal, pulihkan state ke awal agar kasir bisa mencoba lagi
        if (mounted) {
          _resetSlider();
        }
      });
    } else {
      // Kembali ke awal dengan animasi pegas
      _springAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
      ));
      _springController.forward(from: 0.0);
    }
  }

  void _resetSlider() {
    setState(() {
      _isCompleted = false;
      _isLoading = false;
    });
    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));
    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    const double knobPadding = 4.0;
    final double knobSize = widget.height - (knobPadding * 2);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - knobSize - (knobPadding * 2);
        final double progress = maxDrag > 0 ? (_dragOffset / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(
              color: Color.lerp(AppColors.border, widget.activeColor, progress)!,
              width: 1.5,
            ),
            boxShadow: [
              if (progress > 0.3)
                BoxShadow(
                  color: widget.activeColor.withValues(alpha: 0.3 * progress),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Indikator pengisian progresif mengikuti tarikan
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragOffset + knobSize + (knobPadding * 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.activeColor.withValues(alpha: 0.35),
                        widget.activeColor.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              ),

              // 2. Label Teks Petunjuk di Tengah
              Center(
                child: Opacity(
                  opacity: (1.0 - (progress * 1.2)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLoading ? widget.completedLabel : widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_double_arrow_right_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Status Memproses saat terkunci
              if (_isLoading)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.completedLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. Tombol Knob Geser (Draggable Knob)
              Positioned(
                left: knobPadding + _dragOffset,
                top: knobPadding,
                bottom: knobPadding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxDrag),
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isCompleted
                            ? [Colors.white, Colors.white]
                            : [widget.activeColor, const Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isCompleted
                          ? Icon(Icons.check_rounded, color: widget.activeColor, size: 24)
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
