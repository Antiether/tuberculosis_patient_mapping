import 'package:flutter/material.dart';
import '../models/tb_models.dart';

class InteractiveGisMap extends StatefulWidget {
  final List<KecamatanData> kecamatanList;
  final List<FaskesData> faskesList;
  final KecamatanData? selectedKecamatan;
  final Function(KecamatanData?) onSelectKecamatan;
  final Function(FaskesData) onSelectFaskes;
  final bool isCompact;

  const InteractiveGisMap({
    super.key,
    required this.kecamatanList,
    required this.faskesList,
    required this.selectedKecamatan,
    required this.onSelectKecamatan,
    required this.onSelectFaskes,
    this.isCompact = false,
  });

  @override
  State<InteractiveGisMap> createState() => _InteractiveGisMapState();
}

class _InteractiveGisMapState extends State<InteractiveGisMap> {
  final TransformationController _transformController = TransformationController();
  bool _showFaskesMarkers = true;
  bool _showLabels = true;
  bool _showCasesBadge = true;

  bool _isLegendExpanded = false;
  bool _isFilterExpanded = false;

  // Ukuran kanvas peta virtual Bandar Lampung
  static const double mapCanvasWidth = 1000.0;
  static const double mapCanvasHeight = 900.0;

  bool _hasInitialCentered = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _centerAndFitMap(Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    // Hitung skala agar peta muat di viewport tanpa terpotong
    final scaleX = viewportSize.width / mapCanvasWidth;
    final scaleY = viewportSize.height / mapCanvasHeight;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * (widget.isCompact ? 1.05 : 0.95);

    // Pusatkan peta ke tengah viewport
    final dx = (viewportSize.width - (mapCanvasWidth * scale)) / 2;
    final dy = (viewportSize.height - (mapCanvasHeight * scale)) / 2;

    final matrix = Matrix4.identity();
    matrix.setTranslationRaw(dx, dy, 0.0);
    _transformController.value = matrix.scaledByDouble(scale, scale, 1.0, 1.0);
  }

  void _resetZoom(Size viewportSize) {
    _centerAndFitMap(viewportSize);
  }

  void _zoomIn() {
    _transformController.value = _transformController.value.scaledByDouble(1.25, 1.25, 1.0, 1.0);
  }

  void _zoomOut() {
    _transformController.value = _transformController.value.scaledByDouble(0.8, 0.8, 1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final isSmallScreen = constraints.maxWidth < 650;

        // Auto center pertama kali saat layout diketahui
        if (!_hasInitialCentered && viewportSize.width > 0 && viewportSize.height > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _centerAndFitMap(viewportSize);
              _hasInitialCentered = true;
            }
          });
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF090E1A), // Seamless background color
          child: Stack(
            fit: StackFit.expand,
            children: [
              // InteractiveViewer unconstrained dengan boundary margin luas sehingga saat digeser TIDAK TERPOTONG!
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.2,
                maxScale: 5.0,
                boundaryMargin: const EdgeInsets.all(2500),
                constrained: false,
                child: SizedBox(
                  width: mapCanvasWidth,
                  height: mapCanvasHeight,
                  child: Stack(
                    children: [
                      // 1. Layer Laut Teluk Lampung, Garis Pantai, dan Grid Spasial
                      CustomPaint(
                        size: const Size(mapCanvasWidth, mapCanvasHeight),
                        painter: _BandarLampungBasemapPainter(),
                      ),

                      // 2. Layer Poligon Vektor Wilayah 20 Kecamatan
                      ..._districtPolygons.entries.map((entry) {
                        final kecId = entry.key;
                        final points = entry.value;

                        final kec = widget.kecamatanList.firstWhere(
                          (k) => k.id == kecId,
                          orElse: () => widget.kecamatanList.first,
                        );

                        final isSelected = widget.selectedKecamatan?.id == kec.id;
                        final riskColor = _getRiskColor(kec.riskLevel);

                        return Positioned.fill(
                          child: CustomPaint(
                            painter: _DistrictPolygonPainter(
                              points: points,
                              fillColor: riskColor.withAlpha(isSelected ? 190 : 95),
                              strokeColor: isSelected ? Colors.white : riskColor.withAlpha(225),
                              strokeWidth: isSelected ? 3.0 : 1.4,
                              glow: isSelected,
                            ),
                          ),
                        );
                      }),

                      // 3. Layer Label & Badge Centroid Tiap Kecamatan
                      ..._districtPolygons.entries.map((entry) {
                        final kecId = entry.key;
                        final points = entry.value;

                        final kec = widget.kecamatanList.firstWhere(
                          (k) => k.id == kecId,
                          orElse: () => widget.kecamatanList.first,
                        );

                        final isSelected = widget.selectedKecamatan?.id == kec.id;
                        final riskColor = _getRiskColor(kec.riskLevel);
                        final centroid = _calculateCentroid(points);

                        return Positioned(
                          left: centroid.dx - 58,
                          top: centroid.dy - 26,
                          child: GestureDetector(
                            onTap: () => widget.onSelectKecamatan(kec),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 116,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black.withAlpha(220) : Colors.black.withAlpha(120),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.white : riskColor.withAlpha(180),
                                  width: isSelected ? 1.6 : 0.8,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_showLabels)
                                    Text(
                                      kec.nama
                                          .replaceAll('Tanjung Karang ', 'TK ')
                                          .replaceAll('Teluk Betung ', 'TB '),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(color: Colors.black, blurRadius: 4),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (_showCasesBadge)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: riskColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${kec.jumlahKasus} Kasus',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      // 4. Layer Pin Marker Faskes (Puskesmas / RS Rujukan TCM)
                      if (_showFaskesMarkers)
                        ...widget.faskesList.map((faskes) {
                          final point = _geoToCanvas(faskes.lat, faskes.lng);
                          final isRS = faskes.tipe.contains('Rumah Sakit');

                          return Positioned(
                            left: point.dx - 13,
                            top: point.dy - 13,
                            child: Tooltip(
                              message: '${faskes.nama}\n${faskes.alamat}\n${faskes.hasTCM ? "Fasilitas TCM Tersedia" : ""}',
                              child: InkWell(
                                onTap: () => widget.onSelectFaskes(faskes),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isRS ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(128),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isRS ? Icons.local_hospital : Icons.medical_services,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Kontrol Zoom di pojok kanan bawah
              Positioned(
                right: 12,
                bottom: 12,
                child: Column(
                  children: [
                    _MapControlButton(
                      icon: Icons.add,
                      tooltip: 'Perbesar Peta',
                      onTap: _zoomIn,
                    ),
                    const SizedBox(height: 6),
                    _MapControlButton(
                      icon: Icons.remove,
                      tooltip: 'Perkecil Peta',
                      onTap: _zoomOut,
                    ),
                    const SizedBox(height: 6),
                    _MapControlButton(
                      icon: Icons.crop_free,
                      tooltip: 'Pusatkan Peta',
                      onTap: () => _resetZoom(viewportSize),
                    ),
                  ],
                ),
              ),

              // Top Header Panel / Filter Collapsible (Pojok Kiri Atas)
              Positioned(
                left: 12,
                top: 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withAlpha(235),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map, color: Color(0xFF38BDF8), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isSmallScreen ? 'PETA SPASIAL TB' : 'PETA SPASIAL TB KOTA BANDAR LAMPUNG',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                            child: Icon(
                              _isFilterExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      if (_isFilterExpanded || !isSmallScreen) ...[
                        const SizedBox(height: 4),
                        Text(
                          '20 Kecamatan • Vektor Spasial WGS 84',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 9.5),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _FilterChipMap(
                              label: 'Faskes',
                              isSelected: _showFaskesMarkers,
                              onToggle: () => setState(() => _showFaskesMarkers = !_showFaskesMarkers),
                            ),
                            _FilterChipMap(
                              label: 'Nama',
                              isSelected: _showLabels,
                              onToggle: () => setState(() => _showLabels = !_showLabels),
                            ),
                            _FilterChipMap(
                              label: 'Kasus',
                              isSelected: _showCasesBadge,
                              onToggle: () => setState(() => _showCasesBadge = !_showCasesBadge),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Legenda Kerawanan Collapsible (Pojok Kiri Bawah)
              Positioned(
                left: 12,
                bottom: 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withAlpha(235),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _isLegendExpanded = !_isLegendExpanded),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              'Tingkat Kerawanan',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isLegendExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                              color: Colors.white60,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      if (_isLegendExpanded || !isSmallScreen) ...[
                        const SizedBox(height: 6),
                        _LegendRow(color: const Color(0xFFDC2626), label: 'Risiko Tinggi (≥ 35 Kasus)'),
                        const SizedBox(height: 4),
                        _LegendRow(color: const Color(0xFFF59E0B), label: 'Risiko Sedang (18–34 Kasus)'),
                        const SizedBox(height: 4),
                        _LegendRow(color: const Color(0xFF10B981), label: 'Risiko Rendah (< 18 Kasus)'),
                        const SizedBox(height: 4),
                        _LegendRow(color: const Color(0xFFEF4444), label: 'Faskes Rujukan TCM', isCircle: true),
                      ],
                    ],
                  ),
                ),
              ),

              // Modal Floating Detail Wilayah Terpilih
              if (widget.selectedKecamatan != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _SelectedKecamatanCard(
                    kecamatan: widget.selectedKecamatan!,
                    isSmall: isSmallScreen,
                    onClose: () => widget.onSelectKecamatan(null),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Konversi Lat/Lng nyata ke Kanvas Peta 1000x900
  Offset _geoToCanvas(double lat, double lng) {
    const double minLat = -5.4850;
    const double maxLat = -5.3450;
    const double minLng = 105.1800;
    const double maxLng = 105.3450;

    final normX = (lng - minLng) / (maxLng - minLng);
    final normY = (maxLat - lat) / (maxLat - minLat);

    const double paddingX = 70.0;
    const double paddingY = 80.0;
    final usableW = mapCanvasWidth - (paddingX * 2);
    final usableH = mapCanvasHeight - (paddingY * 2);

    return Offset(paddingX + (normX * usableW), paddingY + (normY * usableH));
  }

  Offset _calculateCentroid(List<Offset> points) {
    double sumX = 0;
    double sumY = 0;
    for (var p in points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return const Color(0xFFDC2626); // Crimson Red
      case RiskLevel.medium:
        return const Color(0xFFF59E0B); // Amber Orange
      case RiskLevel.low:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  // Poligon Vektor Spasial 20 Kecamatan Kota Bandar Lampung yang saling menyambung secara topologis
  static final Map<String, List<Offset>> _districtPolygons = {
    // 1. RAJABASA (Utara Barat)
    'kec_rbs': [
      const Offset(270, 75),
      const Offset(390, 65),
      const Offset(425, 140),
      const Offset(370, 175),
      const Offset(305, 190),
      const Offset(260, 140),
    ],

    // 2. TANJUNG SENANG (Utara Timur)
    'kec_tjs': [
      const Offset(390, 65),
      const Offset(600, 70),
      const Offset(635, 160),
      const Offset(545, 195),
      const Offset(425, 140),
    ],

    // 3. LABUHAN RATU (Tengah Utara)
    'kec_lbr': [
      const Offset(370, 175),
      const Offset(425, 140),
      const Offset(480, 190),
      const Offset(460, 255),
      const Offset(370, 245),
      const Offset(305, 190),
    ],

    // 4. KEDATON (Tengah Pusat)
    'kec_kdt': [
      const Offset(370, 245),
      const Offset(460, 255),
      const Offset(480, 325),
      const Offset(400, 350),
      const Offset(350, 300),
    ],

    // 5. WAY HALIM (Tengah Timur)
    'kec_whl': [
      const Offset(480, 190),
      const Offset(545, 195),
      const Offset(615, 240),
      const Offset(590, 325),
      const Offset(480, 325),
      const Offset(460, 255),
    ],

    // 6. SUKARAME (Timur)
    'kec_skr': [
      const Offset(600, 70),
      const Offset(755, 100),
      const Offset(780, 250),
      const Offset(680, 315),
      const Offset(615, 240),
      const Offset(545, 195),
      const Offset(635, 160),
    ],

    // 7. SUKABUMI (Tenggara Pedalaman)
    'kec_skb': [
      const Offset(680, 315),
      const Offset(780, 250),
      const Offset(845, 390),
      const Offset(810, 490),
      const Offset(710, 465),
      const Offset(645, 385),
    ],

    // 8. KEMILING (Barat Perbukitan)
    'kec_kml': [
      const Offset(90, 225),
      const Offset(235, 215),
      const Offset(245, 350),
      const Offset(180, 440),
      const Offset(90, 390),
    ],

    // 9. LANGKAPURA (Barat Tengah)
    'kec_lkp': [
      const Offset(235, 215),
      const Offset(305, 190),
      const Offset(370, 245),
      const Offset(350, 300),
      const Offset(300, 325),
      const Offset(245, 350),
    ],

    // 10. TANJUNG KARANG BARAT (Pusat Barat)
    'kec_tkb': [
      const Offset(245, 350),
      const Offset(300, 325),
      const Offset(350, 300),
      const Offset(400, 350),
      const Offset(370, 420),
      const Offset(290, 430),
      const Offset(180, 440),
    ],

    // 11. TANJUNG KARANG PUSAT (Jantung Kota BDL)
    'kec_tkp': [
      const Offset(400, 350),
      const Offset(480, 325),
      const Offset(490, 400),
      const Offset(440, 430),
      const Offset(370, 420),
    ],

    // 12. TANJUNG KARANG TIMUR
    'kec_tkt': [
      const Offset(480, 325),
      const Offset(590, 325),
      const Offset(580, 415),
      const Offset(490, 400),
    ],

    // 13. KEDAMAIAN
    'kec_kdm': [
      const Offset(590, 325),
      const Offset(645, 385),
      const Offset(710, 465),
      const Offset(635, 490),
      const Offset(580, 415),
    ],

    // 14. ENGGAL (Pusat Selatan)
    'kec_eng': [
      const Offset(440, 430),
      const Offset(490, 400),
      const Offset(510, 470),
      const Offset(450, 495),
    ],

    // 15. TELUK BETUNG UTARA
    'kec_tbu': [
      const Offset(390, 465),
      const Offset(450, 495),
      const Offset(470, 560),
      const Offset(400, 545),
    ],

    // 16. TELUK BETUNG BARAT (Barat Daya Pesisir)
    'kec_tbb': [
      const Offset(180, 440),
      const Offset(290, 430),
      const Offset(390, 465),
      const Offset(400, 545),
      const Offset(370, 650),
      const Offset(225, 640),
      const Offset(155, 540),
    ],

    // 17. TELUK BETUNG SELATAN (Pesisir Teluk Pusat)
    'kec_tbs': [
      const Offset(400, 545),
      const Offset(470, 560),
      const Offset(485, 640),
      const Offset(430, 670),
      const Offset(370, 650),
    ],

    // 18. TELUK BETUNG TIMUR (Pesisir Selatan Barat)
    'kec_tbt': [
      const Offset(370, 650),
      const Offset(430, 670),
      const Offset(460, 765),
      const Offset(360, 790),
      const Offset(290, 715),
    ],

    // 19. BUMI WARAS (Pesisir Teluk Timur)
    'kec_bmw': [
      const Offset(470, 560),
      const Offset(510, 470),
      const Offset(580, 500),
      const Offset(560, 640),
      const Offset(485, 640),
    ],

    // 20. PANJANG (Tenggara Pesisir & Pelabuhan Samudera)
    'kec_pnj': [
      const Offset(580, 500),
      const Offset(635, 490),
      const Offset(710, 465),
      const Offset(810, 490),
      const Offset(845, 600),
      const Offset(790, 730),
      const Offset(645, 745),
      const Offset(560, 640),
    ],
  };
}

class _DistrictPolygonPainter extends CustomPainter {
  final List<Offset> points;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final bool glow;

  _DistrictPolygonPainter({
    required this.points,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (glow) {
      final glowPaint = Paint()
        ..color = strokeColor.withAlpha(128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DistrictPolygonPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.glow != glow;
  }
}

class _BandarLampungBasemapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid Koordinat Halus
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withAlpha(90)
      ..strokeWidth = 0.8;

    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Perairan Teluk Lampung (Sisi Selatan Teluk Betung & Panjang)
    final seaPaint = Paint()
      ..color = const Color(0xFF0369A1).withAlpha(65)
      ..style = PaintingStyle.fill;

    final seaPath = Path()
      ..moveTo(290, 715)
      ..lineTo(360, 790)
      ..lineTo(460, 765)
      ..lineTo(430, 670)
      ..lineTo(485, 640)
      ..lineTo(560, 640)
      ..lineTo(645, 745)
      ..lineTo(790, 730)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 690)
      ..close();

    canvas.drawPath(seaPath, seaPaint);

    final seaCoastlinePaint = Paint()
      ..color = const Color(0xFF38BDF8).withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(seaPath, seaCoastlinePaint);

    // Label Teluk Lampung Watermark
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'PERAIRAN TELUK LAMPUNG (SELAT SUNDA)',
        style: TextStyle(
          color: Color(0xFF38BDF8),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(380, 830));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCircle;

  const _LegendRow({required this.color, required this.label, this.isCircle = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCircle ? 10 : 12,
          height: isCircle ? 10 : 8,
          decoration: BoxDecoration(
            color: color,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 9.5),
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _FilterChipMap extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onToggle;

  const _FilterChipMap({
    required this.label,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.lightBlueAccent : const Color(0xFF334155),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 11,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedKecamatanCard extends StatelessWidget {
  final KecamatanData kecamatan;
  final bool isSmall;
  final VoidCallback onClose;

  const _SelectedKecamatanCard({
    required this.kecamatan,
    required this.isSmall,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmall ? 220 : 260,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(245),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  kecamatan.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 10),
          _infoRow('Akumulasi Kasus:', '${kecamatan.jumlahKasus} Kasus TB'),
          _infoRow('Jumlah Penduduk:', '${kecamatan.jumlahPenduduk} Jiwa'),
          _infoRow('Laju Insidensi:', '${kecamatan.caseRatePer10k.toStringAsFixed(1)} / 10k'),
          _infoRow(
            'Zonasi Wilayah:',
            kecamatan.riskLevel == RiskLevel.high
                ? 'ZONA MERAH'
                : (kecamatan.riskLevel == RiskLevel.medium ? 'ZONA ORANYE' : 'ZONA HIJAU'),
          ),
          const SizedBox(height: 4),
          const Text('Kelurahan:', style: TextStyle(color: Colors.white60, fontSize: 9.5)),
          Text(
            kecamatan.daftarKelurahan.join(', '),
            style: TextStyle(color: Colors.grey.shade300, fontSize: 9.0),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9.5)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
