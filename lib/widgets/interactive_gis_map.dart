import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tb_models.dart';
import '../data/mock_data.dart';

enum MapDrillLevel { kota, kecamatan, kelurahan }

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
  final bool _showFaskesMarkers = true;
  final bool _showLabels = true;
  final bool _showCasesBadge = true;

  bool _isLegendExpanded = false;

  // State Drill-Down Pemetaan Bertingkat: Kota -> Kecamatan -> Kelurahan
  MapDrillLevel _drillLevel = MapDrillLevel.kota;
  KecamatanData? _activeKecamatan;
  KelurahanData? _activeKelurahan;

  final List<KelurahanData> _allKelurahan = MockDataRepository.getInitialKelurahanList();

  static const double mapCanvasWidth = 1000.0;
  static const double mapCanvasHeight = 900.0;

  bool _hasInitialCentered = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedKecamatan != null) {
      _activeKecamatan = widget.selectedKecamatan;
      _drillLevel = MapDrillLevel.kecamatan;
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveGisMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedKecamatan != null && widget.selectedKecamatan != _activeKecamatan) {
      _activeKecamatan = widget.selectedKecamatan;
      _drillLevel = MapDrillLevel.kecamatan;
      _activeKelurahan = null;
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _centerAndFitMap(Size viewportSize, {Offset? targetCentroid, double zoomFactor = 1.0}) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return;

    final scaleX = viewportSize.width / mapCanvasWidth;
    final scaleY = viewportSize.height / mapCanvasHeight;
    double scale = (scaleX < scaleY ? scaleX : scaleY) * (widget.isCompact ? 1.05 : 0.95);
    scale *= zoomFactor;

    double dx;
    double dy;

    if (targetCentroid != null) {
      dx = (viewportSize.width / 2) - (targetCentroid.dx * scale);
      dy = (viewportSize.height / 2) - (targetCentroid.dy * scale);
    } else {
      dx = (viewportSize.width - (mapCanvasWidth * scale)) / 2;
      dy = (viewportSize.height - (mapCanvasHeight * scale)) / 2;
    }

    final matrix = Matrix4.identity();
    matrix.setTranslationRaw(dx, dy, 0.0);
    _transformController.value = matrix.scaledByDouble(scale, scale, 1.0, 1.0);
  }

  void _drillDownToKecamatan(KecamatanData kec, Size viewportSize) {
    setState(() {
      _activeKecamatan = kec;
      _drillLevel = MapDrillLevel.kecamatan;
      _activeKelurahan = null;
    });
    widget.onSelectKecamatan(kec);

    final points = _districtPolygons[kec.id];
    if (points != null && points.isNotEmpty) {
      final centroid = _calculateCentroid(points);
      _centerAndFitMap(viewportSize, targetCentroid: centroid, zoomFactor: 2.2);
    }
  }

  void _drillDownToKelurahan(KelurahanData kel) {
    setState(() {
      _activeKelurahan = kel;
      _drillLevel = MapDrillLevel.kelurahan;
    });
  }

  void _drillUpToKota(Size viewportSize) {
    setState(() {
      _drillLevel = MapDrillLevel.kota;
      _activeKecamatan = null;
      _activeKelurahan = null;
    });
    widget.onSelectKecamatan(null);
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

        if (!_hasInitialCentered && viewportSize.width > 0 && viewportSize.height > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _centerAndFitMap(viewportSize);
              _hasInitialCentered = true;
            }
          });
        }

        // Sub-kelurahan jika sedang di level kecamatan
        List<KelurahanData> activeKelurahanList = [];
        if (_activeKecamatan != null) {
          activeKelurahanList = _allKelurahan.where((k) => k.kecamatanId == _activeKecamatan!.id).toList();
          if (activeKelurahanList.isEmpty) {
            // Fallback dari daftar kelurahan di KecamatanData
            activeKelurahanList = _activeKecamatan!.daftarKelurahan.map((name) {
              return KelurahanData(
                id: 'kel_${name.toLowerCase().replaceAll(' ', '_')}',
                nama: name,
                kecamatanId: _activeKecamatan!.id,
                jumlahKasus: (_activeKecamatan!.jumlahKasus / _activeKecamatan!.daftarKelurahan.length).round(),
                jumlahPenduduk: (_activeKecamatan!.jumlahPenduduk / _activeKecamatan!.daftarKelurahan.length).round(),
              );
            }).toList();
          }
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF090E1A),
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.2,
                maxScale: 6.0,
                boundaryMargin: const EdgeInsets.all(2500),
                constrained: false,
                child: SizedBox(
                  width: mapCanvasWidth,
                  height: mapCanvasHeight,
                  child: Stack(
                    children: [
                      // 1. Basemap Laut & Grid
                      CustomPaint(
                        size: const Size(mapCanvasWidth, mapCanvasHeight),
                        painter: _BandarLampungBasemapPainter(),
                      ),

                      // 2. Poligon Wilayah 20 Kecamatan
                      ..._districtPolygons.entries.map((entry) {
                        final kecId = entry.key;
                        final points = entry.value;

                        final kec = widget.kecamatanList.firstWhere(
                          (k) => k.id == kecId,
                          orElse: () => widget.kecamatanList.first,
                        );

                        final isCurrentKec = _activeKecamatan?.id == kec.id;
                        final isDrilled = _drillLevel != MapDrillLevel.kota;

                        final riskColor = _getRiskColor(kec.riskLevel);
                        final fillAlpha = isDrilled
                            ? (isCurrentKec ? 210 : 35)
                            : (widget.selectedKecamatan?.id == kec.id ? 190 : 95);

                        return Positioned.fill(
                          child: CustomPaint(
                            painter: _DistrictPolygonPainter(
                              points: points,
                              fillColor: riskColor.withAlpha(fillAlpha),
                              strokeColor: isCurrentKec
                                  ? Colors.white
                                  : (isDrilled ? Colors.blueGrey.withAlpha(60) : riskColor.withAlpha(220)),
                              strokeWidth: isCurrentKec ? 3.5 : 1.2,
                              glow: isCurrentKec,
                            ),
                          ),
                        );
                      }),

                      // 3. Label & Badge Interaktif Tiap Kecamatan (Level Kota)
                      if (_drillLevel == MapDrillLevel.kota)
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
                            left: centroid.dx - 60,
                            top: centroid.dy - 28,
                            child: GestureDetector(
                              onTap: () => _drillDownToKecamatan(kec, viewportSize),
                              behavior: HitTestBehavior.opaque,
                              child: Tooltip(
                                message: 'Klik untuk masuk ke tingkat Kelurahan di ${kec.nama}',
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.black.withAlpha(230) : Colors.black.withAlpha(140),
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
                                          kec.nama.replaceAll('Tanjung Karang ', 'TK ').replaceAll('Teluk Betung ', 'TB '),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: Colors.white,
                                            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
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
                                            '${kec.jumlahKasus} Kasus (Zoom 🔍)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                      // 4. Sub-Kelurahan View (Tampil Saat Drill-Down ke Kecamatan)
                      if (_drillLevel != MapDrillLevel.kota && _activeKecamatan != null)
                        ..._renderKelurahanClusters(activeKelurahanList),

                      // 5. Marker Faskes (Puskesmas / RS TCM)
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
                                      BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 6, offset: const Offset(0, 2)),
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

              // BREADCRUMB NAVIGASI BERTINGKAT (Kota -> Kecamatan -> Kelurahan)
              Positioned(
                top: 12,
                left: 12,
                right: widget.selectedKecamatan != null ? (isSmallScreen ? 12 : 270) : 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withAlpha(240),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(120), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => _drillUpToKota(viewportSize),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public, color: Color(0xFF38BDF8), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              isSmallScreen ? 'Kota BDL' : 'Kota Bandar Lampung',
                              style: TextStyle(
                                color: _drillLevel == MapDrillLevel.kota ? Colors.white : const Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_activeKecamatan != null) ...[
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                        InkWell(
                          onTap: () => _drillDownToKecamatan(_activeKecamatan!, viewportSize),
                          child: Text(
                            'Kec. ${_activeKecamatan!.nama}',
                            style: TextStyle(
                              color: _drillLevel == MapDrillLevel.kecamatan ? Colors.white : const Color(0xFF38BDF8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (_activeKelurahan != null) ...[
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                        Text(
                          'Kel. ${_activeKelurahan!.nama}',
                          style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const Spacer(),
                      if (_drillLevel != MapDrillLevel.kota)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _drillUpToKota(viewportSize),
                          icon: const Icon(Icons.arrow_upward, size: 12),
                          label: const Text('Ke Tingkat Kota', style: TextStyle(fontSize: 10)),
                        ),
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
                    _MapControlButton(icon: Icons.add, tooltip: 'Perbesar Peta', onTap: _zoomIn),
                    const SizedBox(height: 6),
                    _MapControlButton(icon: Icons.remove, tooltip: 'Perkecil Peta', onTap: _zoomOut),
                    const SizedBox(height: 6),
                    _MapControlButton(icon: Icons.crop_free, tooltip: 'Pusatkan Peta', onTap: () => _centerAndFitMap(viewportSize)),
                  ],
                ),
              ),

              // Legenda Kerawanan Collapsible
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
                            Text(
                              _drillLevel == MapDrillLevel.kota ? 'Legenda Kasus Kota' : 'Legenda Kasus Kelurahan',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Icon(_isLegendExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.white60, size: 16),
                          ],
                        ),
                      ),
                      if (_isLegendExpanded || !isSmallScreen) ...[
                        const SizedBox(height: 6),
                        _LegendRow(color: const Color(0xFFDC2626), label: _drillLevel == MapDrillLevel.kota ? 'Tinggi (≥ 35 Kasus)' : 'Tinggi (≥ 8 Kasus)'),
                        const SizedBox(height: 4),
                        _LegendRow(color: const Color(0xFFF59E0B), label: _drillLevel == MapDrillLevel.kota ? 'Sedang (18–34 Kasus)' : 'Sedang (4–7 Kasus)'),
                        const SizedBox(height: 4),
                        _LegendRow(color: const Color(0xFF10B981), label: _drillLevel == MapDrillLevel.kota ? 'Rendah (< 18 Kasus)' : 'Rendah (< 4 Kasus)'),
                        const SizedBox(height: 4),
                        _LegendRow(color: const Color(0xFFEF4444), label: 'Faskes Rujukan TCM', isCircle: true),
                      ],
                    ],
                  ),
                ),
              ),

              // Modal Detail Wilayah Terpilih (Kecamatan atau Kelurahan)
              if (widget.selectedKecamatan != null)
                Positioned(
                  top: 54,
                  right: 12,
                  child: _SelectedKecamatanCard(
                    kecamatan: widget.selectedKecamatan!,
                    activeKelurahan: _activeKelurahan,
                    isSmall: isSmallScreen,
                    drillLevel: _drillLevel,
                    onDrillToKelurahan: _drillDownToKelurahan,
                    onClose: () => widget.onSelectKecamatan(null),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Render Sub-Kelurahan di dalam batas kecamatan yang di-zoom
  List<Widget> _renderKelurahanClusters(List<KelurahanData> kelurahanList) {
    if (_activeKecamatan == null) return [];
    final points = _districtPolygons[_activeKecamatan!.id];
    if (points == null || points.isEmpty) return [];

    final centroid = _calculateCentroid(points);
    final count = kelurahanList.length;
    final List<Widget> widgets = [];

    // Distribusikan kelurahan secara radial di sekitar centroid kecamatan
    for (int i = 0; i < count; i++) {
      final kel = kelurahanList[i];
      final angle = (i * 2 * math.pi) / count;
      final distance = 46.0;

      final posX = centroid.dx + (distance * math.cos(angle));
      final posY = centroid.dy + (distance * math.sin(angle));

      final isSelected = _activeKelurahan?.id == kel.id;
      final riskColor = _getRiskColor(kel.riskLevel);

      widgets.add(
        Positioned(
          left: posX - 48,
          top: posY - 22,
          child: GestureDetector(
            onTap: () => _drillDownToKelurahan(kel),
            child: Container(
              width: 96,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withAlpha(240) : const Color(0xFF0F172A).withAlpha(190),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFBBF24) : riskColor,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(color: riskColor.withAlpha(100), blurRadius: isSelected ? 12 : 4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kel. ${kel.nama}',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFBBF24) : Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: riskColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${kel.jumlahKasus} Kasus',
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

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
        return const Color(0xFFDC2626);
      case RiskLevel.medium:
        return const Color(0xFFF59E0B);
      case RiskLevel.low:
        return const Color(0xFF10B981);
    }
  }

  static final Map<String, List<Offset>> _districtPolygons = {
    'kec_rbs': [const Offset(270, 75), const Offset(390, 65), const Offset(425, 140), const Offset(370, 175), const Offset(305, 190), const Offset(260, 140)],
    'kec_tjs': [const Offset(390, 65), const Offset(600, 70), const Offset(635, 160), const Offset(545, 195), const Offset(425, 140)],
    'kec_lbr': [const Offset(370, 175), const Offset(425, 140), const Offset(480, 190), const Offset(460, 255), const Offset(370, 245), const Offset(305, 190)],
    'kec_kdt': [const Offset(370, 245), const Offset(460, 255), const Offset(480, 325), const Offset(400, 350), const Offset(350, 300)],
    'kec_whl': [const Offset(480, 190), const Offset(545, 195), const Offset(615, 240), const Offset(590, 325), const Offset(480, 325), const Offset(460, 255)],
    'kec_skr': [const Offset(600, 70), const Offset(755, 100), const Offset(780, 250), const Offset(680, 315), const Offset(615, 240), const Offset(545, 195), const Offset(635, 160)],
    'kec_skb': [const Offset(680, 315), const Offset(780, 250), const Offset(845, 390), const Offset(810, 490), const Offset(710, 465), const Offset(645, 385)],
    'kec_kml': [const Offset(90, 225), const Offset(235, 215), const Offset(245, 350), const Offset(180, 440), const Offset(90, 390)],
    'kec_lkp': [const Offset(235, 215), const Offset(305, 190), const Offset(370, 245), const Offset(350, 300), const Offset(300, 325), const Offset(245, 350)],
    'kec_tkb': [const Offset(245, 350), const Offset(300, 325), const Offset(350, 300), const Offset(400, 350), const Offset(370, 420), const Offset(290, 430), const Offset(180, 440)],
    'kec_tkp': [const Offset(400, 350), const Offset(480, 325), const Offset(490, 400), const Offset(440, 430), const Offset(370, 420)],
    'kec_tkt': [const Offset(480, 325), const Offset(590, 325), const Offset(580, 415), const Offset(490, 400)],
    'kec_kdm': [const Offset(590, 325), const Offset(645, 385), const Offset(710, 465), const Offset(635, 490), const Offset(580, 415)],
    'kec_eng': [const Offset(440, 430), const Offset(490, 400), const Offset(510, 470), const Offset(450, 495)],
    'kec_tbu': [const Offset(390, 465), const Offset(450, 495), const Offset(470, 560), const Offset(400, 545)],
    'kec_tbb': [const Offset(180, 440), const Offset(290, 430), const Offset(390, 465), const Offset(400, 545), const Offset(370, 650), const Offset(225, 640), const Offset(155, 540)],
    'kec_tbs': [const Offset(400, 545), const Offset(470, 560), const Offset(485, 640), const Offset(430, 670), const Offset(370, 650)],
    'kec_tbt': [const Offset(370, 650), const Offset(430, 670), const Offset(460, 765), const Offset(360, 790), const Offset(290, 715)],
    'kec_bmw': [const Offset(470, 560), const Offset(510, 470), const Offset(580, 500), const Offset(560, 640), const Offset(485, 640)],
    'kec_pnj': [const Offset(580, 500), const Offset(635, 490), const Offset(710, 465), const Offset(810, 490), const Offset(845, 600), const Offset(790, 730), const Offset(645, 745), const Offset(560, 640)],
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

    final fillPaint = Paint()..color = fillColor..style = PaintingStyle.fill;
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
    return oldDelegate.fillColor != fillColor || oldDelegate.strokeColor != strokeColor || oldDelegate.glow != glow;
  }
}

class _BandarLampungBasemapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = const Color(0xFF1E293B).withAlpha(90)..strokeWidth = 0.8;
    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final seaPaint = Paint()..color = const Color(0xFF0369A1).withAlpha(65)..style = PaintingStyle.fill;
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

    final seaCoastlinePaint = Paint()..color = const Color(0xFF38BDF8).withAlpha(150)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawPath(seaPath, seaCoastlinePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'PERAIRAN TELUK LAMPUNG (SELAT SUNDA)',
        style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0),
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 9.5)),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.tooltip, required this.onTap});

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

class _SelectedKecamatanCard extends StatelessWidget {
  final KecamatanData kecamatan;
  final KelurahanData? activeKelurahan;
  final bool isSmall;
  final MapDrillLevel drillLevel;
  final Function(KelurahanData) onDrillToKelurahan;
  final VoidCallback onClose;

  const _SelectedKecamatanCard({
    required this.kecamatan,
    this.activeKelurahan,
    required this.isSmall,
    required this.drillLevel,
    required this.onDrillToKelurahan,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmall ? 230 : 270,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withAlpha(245),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 14, offset: const Offset(0, 4)),
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
                  activeKelurahan != null ? 'Kel. ${activeKelurahan!.nama}' : 'Kec. ${kecamatan.nama}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
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
          if (activeKelurahan != null) ...[
            _infoRow('Tingkat Wilayah:', 'Kelurahan Administrasi'),
            _infoRow('Kecamatan Induk:', kecamatan.nama),
            _infoRow('Akumulasi Kasus:', '${activeKelurahan!.jumlahKasus} Kasus TB'),
            _infoRow('Jumlah Penduduk:', '${activeKelurahan!.jumlahPenduduk} Jiwa'),
            _infoRow(
              'Zonasi Kelurahan:',
              activeKelurahan!.riskLevel == RiskLevel.high
                  ? 'ZONA MERAH (Tinggi)'
                  : (activeKelurahan!.riskLevel == RiskLevel.medium ? 'ZONA ORANYE (Sedang)' : 'ZONA HIJAU (Rendah)'),
            ),
          ] else ...[
            _infoRow('Tingkat Wilayah:', 'Kecamatan (20 di BDL)'),
            _infoRow('Akumulasi Kasus:', '${kecamatan.jumlahKasus} Kasus TB'),
            _infoRow('Jumlah Penduduk:', '${kecamatan.jumlahPenduduk} Jiwa'),
            _infoRow('Laju Insidensi:', '${kecamatan.caseRatePer10k.toStringAsFixed(1)} / 10k'),
            _infoRow(
              'Zonasi Kecamatan:',
              kecamatan.riskLevel == RiskLevel.high
                  ? 'ZONA MERAH'
                  : (kecamatan.riskLevel == RiskLevel.medium ? 'ZONA ORANYE' : 'ZONA HIJAU'),
            ),
            const SizedBox(height: 4),
            const Text('Daftar Kelurahan:', style: TextStyle(color: Colors.white60, fontSize: 9.5)),
            Text(
              kecamatan.daftarKelurahan.join(', '),
              style: TextStyle(color: Colors.grey.shade300, fontSize: 9.0),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
