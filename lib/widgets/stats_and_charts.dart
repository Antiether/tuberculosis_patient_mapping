import 'package:flutter/material.dart';
import '../models/tb_models.dart';

class StatsAndCharts extends StatelessWidget {
  final List<KecamatanData> kecamatanList;
  final List<CaseRecord> caseRecords;
  final RealTimeUpdateLog? latestLog;
  final bool isCompact;

  const StatsAndCharts({
    super.key,
    required this.kecamatanList,
    required this.caseRecords,
    this.latestLog,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalKasus = kecamatanList.fold<int>(0, (sum, k) => sum + k.jumlahKasus);
    final totalPenduduk = kecamatanList.fold<int>(0, (sum, k) => sum + k.jumlahPenduduk);
    final highRiskCount = kecamatanList.where((k) => k.riskLevel == RiskLevel.high).length;
    final mediumRiskCount = kecamatanList.where((k) => k.riskLevel == RiskLevel.medium).length;
    final lowRiskCount = kecamatanList.where((k) => k.riskLevel == RiskLevel.low).length;

    // Status breakdown
    final intensifCount = caseRecords.where((c) => c.status == CaseStatus.pengobatanIntensif).length;
    final lanjutanCount = caseRecords.where((c) => c.status == CaseStatus.pengobatanLanjutan).length;
    final sembuhCount = caseRecords.where((c) => c.status == CaseStatus.sembuh).length;
    final putusObatCount = caseRecords.where((c) => c.status == CaseStatus.putusObat).length;
    final meninggalCount = caseRecords.where((c) => c.status == CaseStatus.meninggal).length;

    // Gender breakdown
    final priaCount = caseRecords.where((c) => c.jenisKelamin == 'L').length;
    final wanitaCount = caseRecords.where((c) => c.jenisKelamin == 'P').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Latency and Near-Real-Time indicator badge
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                  boxShadow: [
                    BoxShadow(color: Color(0xFF10B981), blurRadius: 6, spreadRadius: 2),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS SURVEILANS: NEAR REAL-TIME AKTIF',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      latestLog != null
                          ? 'Pembaruan terakhir: ${latestLog!.aksi} (Latensi proses: ${latestLog!.latensiMs} ms)'
                          : 'Sinkronisasi siap. Latensi rata-rata pengujian lokal: ~120 ms',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid Kartu Ringkasan
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatCard(
              title: 'Total Akumulasi Kasus',
              value: '$totalKasus',
              subtitle: 'Kasus TB Paru Tercatat',
              icon: Icons.personal_injury,
              color: const Color(0xFF3B82F6),
              width: isCompact ? 160 : 180,
            ),
            _StatCard(
              title: 'Populasi Wilayah',
              value: '${(totalPenduduk / 1000).toStringAsFixed(1)}k',
              subtitle: 'Total Jiwa BDL',
              icon: Icons.people_alt,
              color: const Color(0xFF6366F1),
              width: isCompact ? 160 : 180,
            ),
            _StatCard(
              title: 'Kecamatan Rawan',
              value: '$highRiskCount',
              subtitle: 'Zona Merah (≥ 35 Kasus)',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEF4444),
              width: isCompact ? 160 : 180,
            ),
            _StatCard(
              title: 'Keberhasilan Sembuh',
              value: '${((sembuhCount / (caseRecords.isEmpty ? 1 : caseRecords.length)) * 100).toStringAsFixed(0)}%',
              subtitle: 'Target Nasional ≥ 90%',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF10B981),
              width: isCompact ? 160 : 180,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Distribusi Zonasi Wilayah
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribusi Zonasi 20 Kecamatan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _RiskBar(label: 'Risiko Tinggi', count: highRiskCount, total: 20, color: const Color(0xFFDC2626)),
              const SizedBox(height: 6),
              _RiskBar(label: 'Risiko Sedang', count: mediumRiskCount, total: 20, color: const Color(0xFFF59E0B)),
              const SizedBox(height: 6),
              _RiskBar(label: 'Risiko Rendah', count: lowRiskCount, total: 20, color: const Color(0xFF10B981)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status Pengobatan Klinis Kasus Terdaftar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade800),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Status Klinis Pasien Terdata',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total Sampel: ${caseRecords.length}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatusItem(label: 'Tahap Intensif (2 bln pertama)', count: intensifCount, total: caseRecords.length, color: Colors.blue),
              _StatusItem(label: 'Tahap Lanjutan (4 bln)', count: lanjutanCount, total: caseRecords.length, color: Colors.teal),
              _StatusItem(label: 'Sembuh Total / Tuntas', count: sembuhCount, total: caseRecords.length, color: Colors.green),
              _StatusItem(label: 'Putus Obat / Default', count: putusObatCount, total: caseRecords.length, color: Colors.amber),
              _StatusItem(label: 'Meninggal Dunia', count: meninggalCount, total: caseRecords.length, color: Colors.red),
              const Divider(color: Colors.blueGrey, height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DemographicBadge(label: 'Laki-laki', count: priaCount, icon: Icons.male, color: Colors.blue),
                  _DemographicBadge(label: 'Perempuan', count: wanitaCount, icon: Icons.female, color: Colors.pinkAccent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _RiskBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
            Text('$count Kec (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.blueGrey.shade900,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
          ),
          Text('$count (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DemographicBadge extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _DemographicBadge({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        Text('$count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
