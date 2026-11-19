import 'package:flutter/material.dart';
import 'models/tb_models.dart';
import 'data/mock_data.dart';
import 'views/login_view.dart';
import 'views/admin_view.dart';
import 'views/petugas_view.dart';
import 'views/pasien_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TbMappingApp());
}

class TbMappingApp extends StatelessWidget {
  const TbMappingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemetaan Persebaran Pasien Tuberkulosis Bandar Lampung',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0284C7),
        scaffoldBackgroundColor: const Color(0xFF090E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0284C7),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF0F172A),
        ),
        fontFamily: 'Segoe UI',
      ),
      home: const MainRoutingScreen(),
    );
  }
}

class MainRoutingScreen extends StatefulWidget {
  const MainRoutingScreen({super.key});

  @override
  State<MainRoutingScreen> createState() => _MainRoutingScreenState();
}

class _MainRoutingScreenState extends State<MainRoutingScreen> {
  UserAccount? _currentUser;

  late List<KecamatanData> _kecamatanList;
  late List<KelurahanData> _kelurahanList;
  late List<FaskesData> _faskesList;
  late List<CaseRecord> _caseRecords;
  late List<PatientProfile> _patientList;

  RealTimeUpdateLog? _latestLog;
  KecamatanData? _selectedKecamatan;

  @override
  void initState() {
    super.initState();
    _kecamatanList = MockDataRepository.getInitialKecamatanList();
    _kelurahanList = MockDataRepository.getInitialKelurahanList();
    _faskesList = MockDataRepository.getInitialFaskesList();
    _caseRecords = MockDataRepository.getInitialCaseRecords();
    _patientList = MockDataRepository.getInitialPatients();
  }

  void _handleLoginSuccess(UserAccount user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _handleContinueAsGuest() {
    setState(() {
      _currentUser = UserAccount(
        id: 'guest_user',
        username: 'guest',
        password: '',
        fullName: 'Pengguna Publik (Tamu)',
        role: UserRole.admin,
        facilityName: 'Akses Data Agregat Terbuka',
      );
    });
  }

  void _handleLogout() {
    setState(() {
      _currentUser = null;
      _selectedKecamatan = null;
    });
  }

  void _handleSelectKecamatan(KecamatanData? kec) {
    setState(() {
      _selectedKecamatan = kec;
    });
  }

  void _handleSelectFaskes(FaskesData faskes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              faskes.tipe.contains('Rumah Sakit')
                  ? Icons.local_hospital
                  : Icons.medical_services,
              color: faskes.tipe.contains('Rumah Sakit')
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0284C7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                faskes.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _faskesInfoRow('Kategori Faskes:', faskes.tipe),
            _faskesInfoRow('Alamat:', faskes.alamat),
            _faskesInfoRow('Kontak:', faskes.kontak),
            _faskesInfoRow(
              'Alat TCM GeneXpert:',
              faskes.hasTCM
                  ? 'Tersedia & Siap Uji Cepat'
                  : 'Tidak Tersedia (Rujukan ke Faskes TCM)',
            ),
            _faskesInfoRow(
              'Koordinat Spasial:',
              '${faskes.lat.toStringAsFixed(4)}, ${faskes.lng.toStringAsFixed(4)}',
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

  Widget _faskesInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddNewCase(CaseRecord newCase, int latensiMs) {
    setState(() {
      _caseRecords.insert(0, newCase);

      // Sinkronisasi data agregat ke kecamatan
      final idx = _kecamatanList.indexWhere((k) => k.id == newCase.kecamatanId);
      if (idx != -1) {
        _kecamatanList[idx].jumlahKasus += 1;
      }

      // Sinkronisasi data agregat ke kelurahan jika ada
      final kelIdx = _kelurahanList.indexWhere(
        (k) => k.nama.toLowerCase() == newCase.kelurahan.toLowerCase(),
      );
      if (kelIdx != -1) {
        _kelurahanList[kelIdx].jumlahKasus += 1;
      }

      // Tambahkan ke pasien mock jika didaftarkan
      _patientList.insert(
        0,
        PatientProfile(
          id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
          kodePasien: newCase.kodeKasus,
          namaLengkap: 'Pasien ${newCase.kodeKasus}',
          nikMasked: '187101******${1000 + _patientList.length}',
          usia: newCase.usia,
          jenisKelamin: newCase.jenisKelamin,
          kecamatanId: newCase.kecamatanId,
          kelurahanId: newCase.kelurahanId ?? 'kel_default',
          kelurahanNama: newCase.kelurahan,
          facilityId: newCase.faskesId,
          status: newCase.status,
          tanggalMulai: newCase.tanggalDiagnosis,
          beratBadanKg: 52.0,
          hasilBtaAwal: 'BTA Positif (+2)',
          pmoNama: 'Keluarga Pasien',
          pmoKontak: '0812-xxxx-xxxx',
          medicationSchedules: [
            MedicationSchedule(
              id: 'med_${DateTime.now().millisecondsSinceEpoch}',
              patientId: 'patient_${DateTime.now().millisecondsSinceEpoch}',
              medicineName: 'Kombipak OAT Kategori 1 (4FDC)',
              dosage: '4 Tablet',
              instruction: 'Diminum pagi hari 1 jam sebelum makan.',
              timeSlot: '06:30 WIB',
              phase: 'Fase Intensif',
              totalDays: 60,
              currentDay: 1,
              isTakenToday: false,
            ),
          ],
        ),
      );

      _latestLog = RealTimeUpdateLog(
        timestamp: DateTime.now(),
        aksi: 'Input Kasus Baru (${newCase.kodeKasus})',
        detail:
            'Kecamatan: ${_kecamatanList[idx].nama}, Kelurahan: ${newCase.kelurahan}',
        latensiMs: latensiMs,
      );
    });
  }

  void _handleUpdatePatient(PatientProfile updated) {
    setState(() {
      final index = _patientList.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        _patientList[index] = updated;
      }
    });
  }

  void _handleConfirmMedication(MedicationSchedule schedule) {
    setState(() {
      // Sinkronisasi status kepatuhan pasien di memori
      for (var p in _patientList) {
        if (p.id == schedule.patientId) {
          final sIndex = p.medicationSchedules.indexWhere(
            (s) => s.id == schedule.id,
          );
          if (sIndex != -1) {
            p.medicationSchedules[sIndex].isTakenToday = true;
            p.medicationSchedules[sIndex].takenAt = DateTime.now();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Jika belum login dan bukan mode guest, tampilkan halaman Login
    if (_currentUser == null) {
      return LoginView(
        onLoginSuccess: _handleLoginSuccess,
        onContinueAsGuest: _handleContinueAsGuest,
      );
    }

    // 2. Routing berdasarkan Role Pengguna
    switch (_currentUser!.role) {
      case UserRole.admin:
        return AdminView(
          currentUser: _currentUser!,
          kecamatanList: _kecamatanList,
          faskesList: _faskesList,
          caseRecords: _caseRecords,
          patientList: _patientList,
          latestLog: _latestLog,
          selectedKecamatan: _selectedKecamatan,
          onSelectKecamatan: _handleSelectKecamatan,
          onSelectFaskes: _handleSelectFaskes,
          onAddCase: _handleAddNewCase,
          onLogout: _handleLogout,
        );

      case UserRole.petugas:
        return PetugasView(
          currentUser: _currentUser!,
          kecamatanList: _kecamatanList,
          kelurahanList: _kelurahanList,
          faskesList: _faskesList,
          caseRecords: _caseRecords,
          patientList: _patientList,
          selectedKecamatan: _selectedKecamatan,
          onSelectKecamatan: _handleSelectKecamatan,
          onSelectFaskes: _handleSelectFaskes,
          onAddCase: _handleAddNewCase,
          onUpdatePatient: _handleUpdatePatient,
          onLogout: _handleLogout,
        );

      case UserRole.pasien:
        // Cari profil spesifik milik pasien yang login
        final matchingProfiles = _patientList.where(
          (p) => p.id == _currentUser!.patientId,
        );
        if (matchingProfiles.isEmpty) {
          return _AccessDeniedView(onLogout: _handleLogout);
        }

        return PasienView(
          currentUser: _currentUser!,
          patientProfile: matchingProfiles.first,
          onConfirmMedication: _handleConfirmMedication,
          onLogout: _handleLogout,
        );
    }
  }
}

class _AccessDeniedView extends StatelessWidget {
  final VoidCallback onLogout;

  const _AccessDeniedView({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090E1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Color(0xFFF87171), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Profil pasien tidak ditemukan.',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onLogout,
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }
}
