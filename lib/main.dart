import 'package:flutter/material.dart';
import 'models/tb_models.dart';
import 'data/mock_data.dart';
import 'views/mobile_view.dart';
import 'views/web_view.dart';

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
      home: const MainMappingScreen(),
    );
  }
}

class MainMappingScreen extends StatefulWidget {
  const MainMappingScreen({super.key});

  @override
  State<MainMappingScreen> createState() => _MainMappingScreenState();
}

class _MainMappingScreenState extends State<MainMappingScreen> {
  late List<KecamatanData> _kecamatanList;
  late List<FaskesData> _faskesList;
  late List<CaseRecord> _caseRecords;
  RealTimeUpdateLog? _latestLog;
  KecamatanData? _selectedKecamatan;

  @override
  void initState() {
    super.initState();
    _kecamatanList = MockDataRepository.getInitialKecamatanList();
    _faskesList = MockDataRepository.getInitialFaskesList();
    _caseRecords = MockDataRepository.getInitialCaseRecords();
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
              faskes.tipe.contains('Rumah Sakit') ? Icons.local_hospital : Icons.medical_services,
              color: faskes.tipe.contains('Rumah Sakit') ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                faskes.nama,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
              faskes.hasTCM ? 'Tersedia & Siap Uji Cepat' : 'Tidak Tersedia (Rujukan ke Faskes TCM)',
            ),
            _faskesInfoRow('Koordinat Spasial:', '${faskes.lat.toStringAsFixed(4)}, ${faskes.lng.toStringAsFixed(4)}'),
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
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _handleAddNewCase(CaseRecord newCase, int latensiMs) {
    setState(() {
      _caseRecords.insert(0, newCase);

      final idx = _kecamatanList.indexWhere((k) => k.id == newCase.kecamatanId);
      if (idx != -1) {
        _kecamatanList[idx].jumlahKasus += 1;
      }

      _latestLog = RealTimeUpdateLog(
        timestamp: DateTime.now(),
        aksi: 'Input Kasus Baru (${newCase.kodeKasus})',
        detail: 'Kecamatan: ${_kecamatanList[idx].nama}, Kelurahan: ${newCase.kelurahan}',
        latensiMs: latensiMs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint adaptif: jika lebar jendela < 900px gunakan layout mobile, jika >= 900px gunakan layout web
        if (constraints.maxWidth < 900) {
          return MobileView(
            kecamatanList: _kecamatanList,
            faskesList: _faskesList,
            caseRecords: _caseRecords,
            latestLog: _latestLog,
            selectedKecamatan: _selectedKecamatan,
            onSelectKecamatan: _handleSelectKecamatan,
            onSelectFaskes: _handleSelectFaskes,
            onAddCase: _handleAddNewCase,
          );
        }

        return WebViewLayout(
          kecamatanList: _kecamatanList,
          faskesList: _faskesList,
          caseRecords: _caseRecords,
          latestLog: _latestLog,
          selectedKecamatan: _selectedKecamatan,
          onSelectKecamatan: _handleSelectKecamatan,
          onSelectFaskes: _handleSelectFaskes,
          onAddCase: _handleAddNewCase,
        );
      },
    );
  }
}
