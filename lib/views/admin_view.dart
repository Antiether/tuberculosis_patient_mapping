import 'package:flutter/material.dart';
import '../models/tb_models.dart';
import '../widgets/interactive_gis_map.dart';
import '../widgets/stats_and_charts.dart';
import '../widgets/case_simulation_modal.dart';
import '../widgets/research_reference_modal.dart';

class AdminView extends StatefulWidget {
  final UserAccount currentUser;
  final List<KecamatanData> kecamatanList;
  final List<FaskesData> faskesList;
  final List<CaseRecord> caseRecords;
  final List<PatientProfile> patientList;
  final RealTimeUpdateLog? latestLog;
  final KecamatanData? selectedKecamatan;
  final Function(KecamatanData?) onSelectKecamatan;
  final Function(FaskesData) onSelectFaskes;
  final Function(CaseRecord, int) onAddCase;
  final VoidCallback onLogout;

  const AdminView({
    super.key,
    required this.currentUser,
    required this.kecamatanList,
    required this.faskesList,
    required this.caseRecords,
    required this.patientList,
    required this.latestLog,
    required this.selectedKecamatan,
    required this.onSelectKecamatan,
    required this.onSelectFaskes,
    required this.onAddCase,
    required this.onLogout,
  });

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _mobileTabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _mobileTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobileWidth = constraints.maxWidth < 900;

        if (isMobileWidth) {
          return _buildMobileAdminView();
        }

        return _buildDesktopAdminView();
      },
    );
  }

  Widget _buildDesktopAdminView() {
    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      body: Column(
        children: [
          _buildAdminHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kolom Kiri: Peta Spasial Bertingkat
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

                  // Kolom Kanan: Tab Statistik, Kasus Terdata, Faskes
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
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: const Color(0xFF38BDF8),
                              indicatorWeight: 3,
                              labelColor: const Color(0xFF38BDF8),
                              unselectedLabelColor: Colors.grey.shade400,
                              labelStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              tabs: const [
                                Tab(
                                  icon: Icon(Icons.analytics, size: 16),
                                  text: 'Statistik & Tren',
                                ),
                                Tab(
                                  icon: Icon(Icons.table_chart, size: 16),
                                  text: 'Data Kasus',
                                ),
                                Tab(
                                  icon: Icon(Icons.local_hospital, size: 16),
                                  text: 'Faskes Rujukan',
                                ),
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

  Widget _buildMobileAdminView() {
    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF38BDF8),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.currentUser.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Text(
              'Admin / Pengelola Program Dinkes Bandar Lampung',
              style: TextStyle(color: Colors.grey, fontSize: 9.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Penelitian Terdahulu',
            icon: const Icon(
              Icons.menu_book,
              color: Color(0xFF38BDF8),
              size: 18,
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const ResearchReferenceModal(),
            ),
          ),
          IconButton(
            tooltip: 'Simulasi Kasus (+)',
            icon: const Icon(
              Icons.add_location_alt,
              color: Color(0xFF34D399),
              size: 20,
            ),
            onPressed: () => _openSimulationDialog(),
          ),
          IconButton(
            tooltip: 'Keluar (Logout)',
            icon: const Icon(Icons.logout, color: Color(0xFFF87171), size: 18),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _mobileTabController,
          children: [
            InteractiveGisMap(
              kecamatanList: widget.kecamatanList,
              faskesList: widget.faskesList,
              selectedKecamatan: widget.selectedKecamatan,
              onSelectKecamatan: widget.onSelectKecamatan,
              onSelectFaskes: widget.onSelectFaskes,
              isCompact: true,
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: StatsAndCharts(
                kecamatanList: widget.kecamatanList,
                caseRecords: widget.caseRecords,
                latestLog: widget.latestLog,
                isCompact: true,
              ),
            ),
            _buildCaseTableTab(),
            _buildFaskesListTab(),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: const Color(0xFF0F172A),
        child: TabBar(
          controller: _mobileTabController,
          indicatorColor: const Color(0xFF38BDF8),
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.map, size: 19), text: 'Peta'),
            Tab(icon: Icon(Icons.analytics, size: 19), text: 'Statistik'),
            Tab(icon: Icon(Icons.table_chart, size: 19), text: 'Kasus'),
            Tab(icon: Icon(Icons.local_hospital, size: 19), text: 'Faskes'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHeader() {
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
              color: const Color(0xFF0284C7).withAlpha(46),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0284C7)),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Color(0xFF38BDF8),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.currentUser.fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF38BDF8),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'ADMIN / PENGELOLA DINKES',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Pemetaan Bertingkat (Kota → Kecamatan → Kelurahan) • Data Agregat & Privasi Medis',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF38BDF8),
              side: const BorderSide(color: Color(0xFF0284C7)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => const ResearchReferenceModal(),
            ),
            icon: const Icon(Icons.menu_book, size: 15),
            label: const Text(
              'Penelitian Terdahulu',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _openSimulationDialog,
            icon: const Icon(Icons.add_location_alt, size: 16),
            label: const Text(
              '+ Input Kasus Simulasi',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Keluar (Logout)',
            icon: const Icon(Icons.logout, color: Color(0xFFF87171), size: 20),
            onPressed: widget.onLogout,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Standar Privasi UU PDP',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: widget.caseRecords.length,
            separatorBuilder: (ctx, i) =>
                const Divider(color: Colors.blueGrey, height: 12),
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
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.status.label,
                                  style: TextStyle(
                                    color: _statusColor(item.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (item.patientId != null) ...[
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () =>
                                        _showPatientDetail(item.patientId!),
                                    child: const Icon(
                                      Icons.visibility,
                                      color: Color(0xFF38BDF8),
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kec. ${kec.nama} • Kel. ${item.kelurahan}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Usia ${item.usia} th (${item.jenisKelamin}) • Tanggal: ${item.tanggalDiagnosis.day}/${item.tanggalDiagnosis.month}/${item.tanggalDiagnosis.year}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.5,
                          ),
                        ),
                        if (item.catatan.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.catatan,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 9.5,
                                fontStyle: FontStyle.italic,
                              ),
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

  void _showPatientDetail(String patientId) {
    final matches = widget.patientList.where((p) => p.id == patientId);
    final patient = matches.isEmpty ? null : matches.first;
    if (patient == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          patient.namaLengkap,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Kode pasien', patient.kodePasien),
              _detailRow('NIK', patient.nikMasked),
              _detailRow(
                'Usia / Jenis kelamin',
                '${patient.usia} tahun / ${patient.jenisKelamin}',
              ),
              _detailRow('Domisili', 'Kel. ${patient.kelurahanNama}'),
              _detailRow('Status terapi', patient.status.label),
              _detailRow('Hasil pemeriksaan', patient.hasilBtaAwal),
              _detailRow('Faskes', _facilityName(patient.facilityId)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _facilityName(String facilityId) {
    for (final facility in widget.faskesList) {
      if (facility.id == facilityId) return facility.nama;
    }
    return facilityId;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
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
              backgroundColor: isRS
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0284C7),
              child: Icon(
                isRS ? Icons.local_hospital : Icons.medical_services,
                color: Colors.white,
                size: 16,
              ),
            ),
            title: Text(
              f.nama,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  f.alamat,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kontak: ${f.kontak} • Fasilitas: ${f.hasTCM ? "TCM GeneXpert Aktif" : "Mikroskopis BTA"}',
                  style: TextStyle(
                    color: f.hasTCM
                        ? const Color(0xFF34D399)
                        : Colors.grey.shade400,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSimulationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CaseSimulationModal(
        kecamatanList: widget.kecamatanList,
        faskesList: widget.faskesList,
        onCaseAdded: widget.onAddCase,
      ),
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
