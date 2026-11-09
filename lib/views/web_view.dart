import 'package:flutter/material.dart';
import '../models/tb_models.dart';
import '../widgets/interactive_gis_map.dart';
import '../widgets/stats_and_charts.dart';
import '../widgets/case_simulation_modal.dart';
import '../widgets/research_reference_modal.dart';

class WebViewLayout extends StatefulWidget {
  final List<KecamatanData> kecamatanList;
  final List<FaskesData> faskesList;
  final List<CaseRecord> caseRecords;
  final RealTimeUpdateLog? latestLog;
  final KecamatanData? selectedKecamatan;
  final Function(KecamatanData?) onSelectKecamatan;
  final Function(FaskesData) onSelectFaskes;
  final Function(CaseRecord, int) onAddCase;

  const WebViewLayout({
    super.key,
    required this.kecamatanList,
    required this.faskesList,
    required this.caseRecords,
    required this.latestLog,
    required this.selectedKecamatan,
    required this.onSelectKecamatan,
    required this.onSelectFaskes,
    required this.onAddCase,
  });

  @override
  State<WebViewLayout> createState() => _WebViewLayoutState();
}

class _WebViewLayoutState extends State<WebViewLayout> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      body: Column(
        children: [
          // Header Web Portal
          _buildWebHeader(),

          // Konten Utama: 2 Kolom (Kiri: Peta Spasial, Kanan: Panel Tab Analitik)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kolom Kiri: Peta Spasial Vektor Interaktif
                  Expanded(
                    flex: 6,
                    child: InteractiveGisMap(
                      kecamatanList: widget.kecamatanList,
                      faskesList: widget.faskesList,
                      selectedKecamatan: widget.selectedKecamatan,
                      onSelectKecamatan: widget.onSelectKecamatan,
                      onSelectFaskes: widget.onSelectFaskes,
                      isCompact: false,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Kolom Kanan: Tab Statistik, Tabel Kasus, Faskes
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: const Color(0xFF38BDF8),
                              indicatorWeight: 3,
                              labelColor: const Color(0xFF38BDF8),
                              unselectedLabelColor: Colors.grey.shade400,
                              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              tabs: const [
                                Tab(icon: Icon(Icons.analytics, size: 16), text: 'Statistik & Tren'),
                                Tab(icon: Icon(Icons.table_chart, size: 16), text: 'Data Kasus'),
                                Tab(icon: Icon(Icons.local_hospital, size: 16), text: 'Faskes Rujukan'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(14),
                                  child: StatsAndCharts(
                                    kecamatanList: widget.kecamatanList,
                                    caseRecords: widget.caseRecords,
                                    latestLog: widget.latestLog,
                                    isCompact: false,
                                  ),
                                ),
                                _buildCaseTableTab(),
                                _buildFaskesListTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0284C7)),
            ),
            child: const Icon(Icons.public, color: Color(0xFF38BDF8), size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'SISTEM PEMETAAN PERSEBARAN PASIEN TUBERKULOSIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF10B981), width: 0.8),
                    ),
                    child: const Text(
                      'REAL-TIME WEBGIS',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 9.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Wilayah Pemetaan: Kota Bandar Lampung • Akses Terbuka Tanpa Autentikasi',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF0284C7)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const ResearchReferenceModal(),
              );
            },
            icon: const Icon(Icons.menu_book, size: 15),
            label: const Text('Penelitian Terdahulu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => CaseSimulationModal(
                  kecamatanList: widget.kecamatanList,
                  faskesList: widget.faskesList,
                  onCaseAdded: widget.onAddCase,
                ),
              );
            },
            icon: const Icon(Icons.add_location_alt, size: 16),
            label: const Text('+ Input Kasus Simulasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseTableTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF1E293B),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Data Kasus De-Identifikasi (${widget.caseRecords.length} Data)',
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              Text(
                'Standar Privasi UU PDP',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: widget.caseRecords.length,
            separatorBuilder: (ctx, i) => const Divider(color: Colors.blueGrey, height: 12),
            itemBuilder: (context, index) {
              final item = widget.caseRecords[index];
              final kec = widget.kecamatanList.firstWhere(
                (k) => k.id == item.kecamatanId,
                orElse: () => widget.kecamatanList.first,
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.kodeKasus,
                              style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            Text(
                              item.status.label,
                              style: TextStyle(color: _statusColor(item.status), fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kec. ${kec.nama} • Kel. ${item.kelurahan}',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Usia ${item.usia} th (${item.jenisKelamin == 'L' ? 'L' : 'P'}) • Tanggal: ${item.tanggalDiagnosis.day}/${item.tanggalDiagnosis.month}/${item.tanggalDiagnosis.year}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 9.5),
                        ),
                        if (item.catatan.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.catatan,
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 9.5, fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFaskesListTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: widget.faskesList.length,
      itemBuilder: (context, index) {
        final f = widget.faskesList[index];
        final isRS = f.tipe.contains('Rumah Sakit');

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isRS ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
              child: Icon(isRS ? Icons.local_hospital : Icons.medical_services, color: Colors.white, size: 16),
            ),
            title: Text(
              f.nama,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(f.alamat, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  'Kontak: ${f.kontak} • Fasilitas: ${f.hasTCM ? 'TCM GeneXpert Aktif' : 'Mikroskopis BTA'}',
                  style: TextStyle(color: f.hasTCM ? const Color(0xFF34D399) : Colors.grey.shade400, fontSize: 9.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.pengobatanIntensif:
        return Colors.blueAccent;
      case CaseStatus.pengobatanLanjutan:
        return Colors.tealAccent;
      case CaseStatus.sembuh:
        return Colors.greenAccent;
      case CaseStatus.putusObat:
        return Colors.amberAccent;
      case CaseStatus.meninggal:
        return Colors.redAccent;
    }
  }
}
