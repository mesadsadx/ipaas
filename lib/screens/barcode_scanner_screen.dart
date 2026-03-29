// ── BarcodeScanner ────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/usda_service.dart';
import '../theme/app_theme.dart';
import 'food_detail_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String mealType;
  final DateTime date;

  const BarcodeScannerScreen({super.key, required this.mealType, required this.date});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;
    _scanned = true;

    final results = await UsdaService.searchByBarcode(barcode);
    if (!mounted) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Штрихкод $barcode не найден'), backgroundColor: AppColors.coral),
      );
      setState(() => _scanned = false);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(food: results.first, mealType: widget.mealType, date: widget.date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // Overlay
          Column(
            children: [
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: 280, height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 0),
                    ),
                    child: CustomPaint(painter: _CornerPainter()),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.barcode_reader, color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Text('Наведите на штрихкод',
                          style: TextStyle(color: Colors.white70, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const c = 22.0;
    // TL
    canvas.drawLine(Offset.zero, const Offset(c, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, c), paint);
    // TR
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - c, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, c), paint);
    // BL
    canvas.drawLine(Offset(0, size.height), Offset(c, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - c), paint);
    // BR
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - c, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - c), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
