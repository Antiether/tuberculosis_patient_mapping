import 'package:flutter/material.dart';

class ResearchReferenceModal extends StatelessWidget {
  const ResearchReferenceModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 650),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book, color: Color(0xFF38BDF8)),
                    SizedBox(width: 10),
                    Text(
                      'Tinjauan Pustaka & Penelitian Terdahulu (State of the Art)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Rujukan valid penelitian spasial Tuberkulosis di Kota Bandar Lampung dan WebGIS untuk BAB II Skripsi.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
            ),
            const Divider(color: Color(0xFF334155), height: 20),
            Expanded(
              child: ListView(
                children: const [
                  _PaperCard(
                    title: 'Clustered Tuberculosis Incidence in Bandar Lampung, Indonesia',
                    authors: 'Prof. Dr. Dyah Wulan Sumekar R. Wardani, Hari Kusnanto, Lutfan Lazuardi',
                    source: 'WHO South-East Asia Journal of Public Health (WHO SEARO), 2014',
                    focus: 'Fokus Geospasial Lokal: Kota Bandar Lampung',
                    keyFindings:
                        'Membuktikan secara empiris adanya pengelompokan spasial (clustering) penderita TB di kecamatan padat penduduk Kota Bandar Lampung (misal: Panjang, Tanjung Karang Pusat, Teluk Betung). Menjadi rujukan utama pentingnya unit pemetaan tingkat kecamatan/kelurahan.',
                  ),
                  _PaperCard(
                    title: 'Pentingnya Analisis Cluster Berbasis Spasial dalam Penanggulangan Tuberkulosis di Indonesia',
                    authors: 'Dyah Wulan Sumekar R. Wardani, Lutfan Lazuardi, Hari Kusnanto',
                    source: 'Kesmas: National Public Health Journal (FKM UI - SINTA 1), 2013',
                    focus: 'Metodologi Analisis Spasial Epidemiologi',
                    keyFindings:
                        'Menjelaskan bahwa pemetaan agregat dan analisis klaster geospasial sangat penting bagi Dinas Kesehatan untuk menentukan prioritas intervensi aktif (Active Case Finding) tanpa melanggar privasi data pasien.',
                  ),
                  _PaperCard(
                    title: 'Spatio-Temporal Dynamics of Tuberculosis Clusters in Indonesia',
                    authors: 'Dyah Wulan Sumekar R. Wardani, Endro Prasetyo Wahono',
                    source: 'Indian Journal of Community Medicine, 2020',
                    focus: 'Dinamika Spasial-Temporal (Waktu & Wilayah)',
                    keyFindings:
                        'Mengamati pergeseran konsentrasi kasus TB di Bandar Lampung antar-tahun. Mendasari kebutuhan sistem pelaporan pembaruan berkala (Near Real-Time) agar perubahan tren segera terdeteksi pengelola program TB.',
                  ),
                  _PaperCard(
                    title: 'Pengembangan WebGIS Pemetaan Kasus Tuberkulosis Menggunakan Leaflet dan OpenStreetMap',
                    authors: 'Prasetyo, A., & Wibowo, A.',
                    source: 'Jurnal Teknologi Informasi dan Ilmu Komputer (JTIIK - SINTA 2), 2022',
                    focus: 'Arsitektur WebGIS & Standar Privasi Medis',
                    keyFindings:
                        'Menerapkan prinsip de-identifikasi data: data titik koordinat presisi rumah pasien ditransformasikan menjadi bentuk agregasi per kelurahan/kecamatan guna menjaga kerahasiaan identitas pasien (UU Kesehatan & PDP).',
                  ),
                  _PaperCard(
                    title: 'Implementasi Algoritma Spasial dan Dashboard Interaktif Surveilans Tuberkulosis',
                    authors: 'Mubarak, A., dkk.',
                    source: 'Jurnal Sistem Informasi Kesehatan, 2023',
                    focus: 'Multi-User Dashboard & Near Real-Time Updates',
                    keyFindings:
                        'Mengkaji arsitektur dashboard adaptif untuk pengambil kebijakan dan faskes dengan zonasi visualisasi risiko (Merah, Oranye, Hijau) serta pengukuran latensi pembaruan data sistem.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  final String title;
  final String authors;
  final String source;
  final String focus;
  final String keyFindings;

  const _PaperCard({
    required this.title,
    required this.authors,
    required this.source,
    required this.focus,
    required this.keyFindings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  focus,
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                source,
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            'Peneliti: $authors',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Text(
            'Relevansi untuk Skripsi: $keyFindings',
            style: TextStyle(color: Colors.grey.shade300, fontSize: 10.5, height: 1.3),
          ),
        ],
      ),
    );
  }
}
