import 'package:flutter/material.dart';
import '../models/tb_models.dart';
import '../widgets/interactive_gis_map.dart';
import '../widgets/stats_and_charts.dart';
import '../widgets/case_simulation_modal.dart';
import '../widgets/research_reference_modal.dart';

class MobileView extends StatefulWidget {
  final List<KecamatanData> kecamatanList;
  final List<FaskesData> faskesList;
  final List<CaseRecord> caseRecords;
  final RealTimeUpdateLog? latestLog;
  final KecamatanData? selectedKecamatan;
  final Function(KecamatanData?) onSelectKecamatan;
  final Function(FaskesData) onSelectFaskes;
  final Function(CaseRecord, int) onAddCase;

  const MobileView({
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
  State<MobileView> createState() => _MobileViewState();
}

class _MobileViewState extends State<MobileView> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleSpacing: 12,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: Color(0xFF38BDF8), size: 18),
                SizedBox(width: 6),
                Text(
                  'TB GIS Kota Bandar Lampung',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              'Pemetaan Spasial Real-Time • Akses Langsung',
              style: TextStyle(color: Colors.grey, fontSize: 9.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Penelitian Terdahulu (Bab II)',
            icon: const Icon(Icons.menu_book, color: Color(0xFF38BDF8), size: 18),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const ResearchReferenceModal(),
              );
            },
          ),
          IconButton(
            tooltip: 'Input Kasus Simulasi (+)',
            icon: const Icon(Icons.add_location_alt, color: Color(0xFF34D399), size: 20),
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
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            // TAB 0: Peta GIS Spasial Interaktif Full Screen Tanpa Padding
            SizedBox.expand(
              child: InteractiveGisMap(
                kecamatanList: widget.kecamatanList,
                faskesList: widget.faskesList,
                selectedKecamatan: widget.selectedKecamatan,
                onSelectKecamatan: widget.onSelectKecamatan,
                onSelectFaskes: widget.onSelectFaskes,
                isCompact: true,
              ),
            ),

            // TAB 1: Statistik & Tren Epidemiologi
            SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: StatsAndCharts(
                kecamatanList: widget.kecamatanList,
                caseRecords: widget.caseRecords,
                latestLog: widget.latestLog,
                isCompact: true,
              ),
            ),

            // TAB 2: Daftar Kasus Pasien
            _buildCasesTab(),

            // TAB 3: Direktori Faskes Rujukan TCM
            _buildFaskesTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) => setState(() => _currentTabIndex = index),
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: const Color(0xFF38BDF8),
          unselectedItemColor: Colors.grey.shade500,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Peta Spasial',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Statistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_list_outlined),
              activeIcon: Icon(Icons.view_list),
              label: 'Kasus',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital_outlined),
              activeIcon: Icon(Icons.local_hospital),
              label: 'Faskes',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton.small(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              tooltip: 'Simulasi Kasus Baru',
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
              child: const Icon(Icons.add_location_alt, size: 18),
            )
          : null,
    );
  }

  Widget _buildCasesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: widget.caseRecords.length,
      itemBuilder: (context, index) {
        final item = widget.caseRecords[index];
        final kec = widget.kecamatanList.firstWhere(
          (k) => k.id == item.kecamatanId,
          orElse: () => widget.kecamatanList.first,
        );

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.kodeKasus,
                      style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(item.status).withAlpha(46),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _statusColor(item.status), width: 0.8),
                      ),
                      child: Text(
                        item.status.label,
                        style: TextStyle(color: _statusColor(item.status), fontSize: 9.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Wilayah: ${kec.nama} • Kel. ${item.kelurahan}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pasien: Usia ${item.usia} th (${item.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'}) • Diagnosis: ${item.tanggalDiagnosis.day}/${item.tanggalDiagnosis.month}/${item.tanggalDiagnosis.year}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
                if (item.catatan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Catatan: ${item.catatan}',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 9.5, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaskesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
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
