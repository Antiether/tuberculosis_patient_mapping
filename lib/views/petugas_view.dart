import 'package:flutter/material.dart';
import '../models/tb_models.dart';
import '../widgets/case_simulation_modal.dart';
import '../widgets/interactive_gis_map.dart';

class PetugasView extends StatefulWidget {
  final UserAccount currentUser;
  final List<KecamatanData> kecamatanList;
  final List<KelurahanData> kelurahanList;
  final List<FaskesData> faskesList;
  final List<CaseRecord> caseRecords;
  final List<PatientProfile> patientList;
  final KecamatanData? selectedKecamatan;
  final Function(KecamatanData?) onSelectKecamatan;
  final Function(FaskesData) onSelectFaskes;
  final Function(CaseRecord, int latensiMs) onAddCase;
  final Function(PatientProfile) onUpdatePatient;
  final VoidCallback onLogout;

  const PetugasView({
    super.key,
    required this.currentUser,
    required this.kecamatanList,
    required this.kelurahanList,
    required this.faskesList,
    required this.caseRecords,
    required this.patientList,
    required this.selectedKecamatan,
    required this.onSelectKecamatan,
    required this.onSelectFaskes,
    required this.onAddCase,
    required this.onUpdatePatient,
    required this.onLogout,
  });

  @override
  State<PetugasView> createState() => _PetugasViewState();
}

class _PetugasViewState extends State<PetugasView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  CaseStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter pasien faskes petugas
    final faskesId = widget.currentUser.facilityId ?? 'faskes_simpur';
    final facilityPatients = widget.patientList.where((p) {
      if (p.facilityId != faskesId) return false;
      if (_filterStatus != null && p.status != _filterStatus) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.namaLengkap.toLowerCase().contains(q) ||
            p.kodePasien.toLowerCase().contains(q) ||
            p.kelurahanNama.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_services_rounded,
                  color: Color(0xFF34D399),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.currentUser.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withAlpha(35),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF34D399),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'PETUGAS FASKES',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              widget.currentUser.facilityName ?? 'Puskesmas Wilayah Kerja',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah Pasien Baru',
            icon: const Icon(
              Icons.person_add_alt_1,
              color: Color(0xFF38BDF8),
              size: 20,
            ),
            onPressed: () => _showAddPatientDialog(context),
          ),
          IconButton(
            tooltip: 'Keluar (Logout)',
            icon: const Icon(Icons.logout, color: Color(0xFFF87171), size: 18),
            onPressed: widget.onLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF34D399),
          indicatorWeight: 3,
          labelColor: const Color(0xFF34D399),
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
          ),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined, size: 16), text: 'Peta Wilayah'),
            Tab(
              icon: Icon(Icons.groups_rounded, size: 16),
              text: 'Daftar Pasien Faskes',
            ),
            Tab(
              icon: Icon(Icons.calendar_month_rounded, size: 16),
              text: 'Pantauan Jadwal OAT',
            ),
            Tab(
              icon: Icon(Icons.history_edu_rounded, size: 16),
              text: 'Riwayat Kasus Terdata',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InteractiveGisMap(
            kecamatanList: widget.kecamatanList,
            faskesList: widget.faskesList,
            selectedKecamatan: widget.selectedKecamatan,
            onSelectKecamatan: widget.onSelectKecamatan,
            onSelectFaskes: widget.onSelectFaskes,
            isCompact: true,
          ),
          // Tab 1: Manajemen Pasien Faskes
          _buildPatientListTab(facilityPatients),

          // Tab 2: Monitoring Kepatuhan Minum Obat
          _buildMedicationMonitoringTab(facilityPatients),

          // Tab 3: Riwayat Kasus Wilayah Kerja
          _buildCaseHistoryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Registrasi Pasien Baru',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddPatientDialog(context),
      ),
    );
  }

  Widget _buildPatientListTab(List<PatientProfile> patients) {
    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Cari nama pasien, kode TB, atau kelurahan...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<CaseStatus?>(
                value: _filterStatus,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 11),
                hint: const Text(
                  'Semua Status',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua Status'),
                  ),
                  ...CaseStatus.values.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  ),
                ],
                onChanged: (val) => setState(() => _filterStatus = val),
              ),
            ],
          ),
        ),

        // List Pasien
        Expanded(
          child: patients.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada pasien yang sesuai filter.',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final p = patients[index];

                    return Card(
                      color: const Color(0xFF0F172A),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF1E293B)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(
                                        0xFF0284C7,
                                      ).withAlpha(40),
                                      child: Text(
                                        p.jenisKelamin,
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.namaLengkap,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Kode: ${p.kodePasien} • NIK: ${p.nikMasked}',
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(p.status).withAlpha(35),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _statusColor(p.status),
                                    ),
                                  ),
                                  child: Text(
                                    p.status.label,
                                    style: TextStyle(
                                      color: _statusColor(p.status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF1E293B), height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Domisili: Kel. ${p.kelurahanNama}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'PMO: ${p.pmoNama}',
                                  style: const TextStyle(
                                    color: Color(0xFF34D399),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hasil Awal: ${p.hasilBtaAwal}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF38BDF8),
                                    side: const BorderSide(
                                      color: Color(0xFF0284C7),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showEditStatusDialog(context, p),
                                  icon: const Icon(Icons.edit_note, size: 14),
                                  label: const Text(
                                    'Ubah Status Terapi',
                                    style: TextStyle(fontSize: 10.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E293B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showPatientScheduleDialog(context, p),
                                  icon: const Icon(Icons.medication, size: 14),
                                  label: const Text(
                                    'Atur Jadwal OAT',
                                    style: TextStyle(fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMedicationMonitoringTab(List<PatientProfile> patients) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final p = patients[index];
        final schedules = p.medicationSchedules;
        final isAllTaken = schedules.every((s) => s.isTakenToday);

        return Card(
          color: const Color(0xFF0F172A),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isAllTaken
                  ? const Color(0xFF10B981).withAlpha(100)
                  : const Color(0xFFF59E0B).withAlpha(100),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${p.namaLengkap} (${p.kodePasien})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isAllTaken
                              ? const Color(0xFF10B981).withAlpha(30)
                              : const Color(0xFFF59E0B).withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isAllTaken
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        child: Text(
                          isAllTaken
                              ? '✓ Kepatuhan Hari Ini: Terpenuhi'
                              : '⚠ Belum Konfirmasi Minum Obat',
                          style: TextStyle(
                            color: isAllTaken
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFCD34D),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pengawas Menelan Obat (PMO): ${p.pmoNama} (${p.pmoKontak})',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 10),
                ...schedules.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 4,
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.medicineName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Dosis: ${s.dosage} • Waktu: ${s.timeSlot}',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          s.isTakenToday
                              ? 'Sudah Minum'
                              : 'Menunggu Konfirmasi',
                          style: TextStyle(
                            color: s.isTakenToday
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF87171),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaseHistoryTab() {
    final facilityId = widget.currentUser.facilityId;
    final facilityCases = widget.caseRecords.where((caseRecord) {
      if (facilityId == null) return false;
      return caseRecord.faskesId == facilityId;
    }).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: facilityCases.length,
      separatorBuilder: (ctx, i) => const Divider(color: Color(0xFF1E293B)),
      itemBuilder: (context, index) {
        final c = facilityCases[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            '${c.kodeKasus} • Kel. ${c.kelurahan}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Usia ${c.usia} th (${c.jenisKelamin}) • Diagnosis: ${c.tanggalDiagnosis.day}/${c.tanggalDiagnosis.month}/${c.tanggalDiagnosis.year}\nCatatan: ${c.catatan}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor(c.status).withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _statusColor(c.status), width: 0.8),
            ),
            child: Text(
              c.status.label,
              style: TextStyle(
                color: _statusColor(c.status),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddPatientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => CaseSimulationModal(
        kecamatanList: widget.kecamatanList,
        faskesList: widget.faskesList,
        onCaseAdded: widget.onAddCase,
      ),
    );
  }

  void _showEditStatusDialog(BuildContext context, PatientProfile patient) {
    CaseStatus selectedStatus = patient.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              'Perbarui Status Terapi: ${patient.namaLengkap}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Status Terapi Baru Pasien:',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CaseStatus>(
                  initialValue: selectedStatus,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF1E293B),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: CaseStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedStatus = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                ),
                onPressed: () {
                  setState(() => patient.status = selectedStatus);
                  widget.onUpdatePatient(patient);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF059669),
                      content: Text(
                        'Status pasien ${patient.namaLengkap} berhasil diperbarui ke ${selectedStatus.label}.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPatientScheduleDialog(
    BuildContext context,
    PatientProfile patient,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Jadwal OAT: ${patient.namaLengkap}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...patient.medicationSchedules.map(
              (s) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.medicineName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      'Dosis: ${s.dosage} (${s.timeSlot})',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      s.instruction,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup', style: TextStyle(color: Colors.white70)),
          ),
        ],
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
