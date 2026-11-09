import 'dart:math';
import 'package:flutter/material.dart';
import '../models/tb_models.dart';

class CaseSimulationModal extends StatefulWidget {
  final List<KecamatanData> kecamatanList;
  final List<FaskesData> faskesList;
  final Function(CaseRecord, int latensiMs) onCaseAdded;

  const CaseSimulationModal({
    super.key,
    required this.kecamatanList,
    required this.faskesList,
    required this.onCaseAdded,
  });

  @override
  State<CaseSimulationModal> createState() => _CaseSimulationModalState();
}

class _CaseSimulationModalState extends State<CaseSimulationModal> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedKecamatanId;
  String _selectedKelurahan = '';
  String _selectedFaskesId = '';
  CaseStatus _selectedStatus = CaseStatus.pengobatanIntensif;
  String _jenisKelamin = 'L';
  int _usia = 34;
  String _catatan = 'Pasien baru terkonfirmasi bakteriologis mikroskopis BTA (+2).';

  @override
  void initState() {
    super.initState();
    _selectedKecamatanId = widget.kecamatanList.first.id;
    _updateKelurahanList();
    _selectedFaskesId = widget.faskesList.first.id;
  }

  void _updateKelurahanList() {
    final kec = widget.kecamatanList.firstWhere((k) => k.id == _selectedKecamatanId);
    _selectedKelurahan = kec.daftarKelurahan.first;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final stopwatch = Stopwatch()..start();

    // Buat record baru
    final newCase = CaseRecord(
      id: 'case_${DateTime.now().millisecondsSinceEpoch}',
      kodeKasus: 'TBC-BDL-${DateTime.now().year}-${100 + Random().nextInt(899)}',
      kecamatanId: _selectedKecamatanId,
      kelurahan: _selectedKelurahan,
      usia: _usia,
      jenisKelamin: _jenisKelamin,
      status: _selectedStatus,
      tanggalDiagnosis: DateTime.now(),
      faskesId: _selectedFaskesId,
      catatan: _catatan,
    );

    // Simulasi jeda validasi backend lokal modular monolith (50 - 140 ms)
    final latensi = stopwatch.elapsedMilliseconds + 45 + Random().nextInt(75);

    widget.onCaseAdded(newCase, latensi);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amberAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Data Kasus ${newCase.kodeKasus} Disimpan! Peta diperbarui secara Real-Time ($latensi ms)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kec = widget.kecamatanList.firstWhere((k) => k.id == _selectedKecamatanId);

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_location_alt_outlined, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'Simulasi Input Kasus TB Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
                  'Fitur demonstrasi pengujian latensi Near Real-Time & perubahan zonasi peta agregat.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
                const Divider(color: Color(0xFF334155), height: 24),

                // Pilih Kecamatan
                const Text('Pilih Kecamatan Domisili:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedKecamatanId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration(),
                  items: widget.kecamatanList.map((k) {
                    return DropdownMenuItem(
                      value: k.id,
                      child: Text('${k.nama} (${k.jumlahKasus} kasus aktif)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedKecamatanId = val;
                        _updateKelurahanList();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Pilih Kelurahan
                const Text('Kelurahan:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedKelurahan,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration(),
                  items: kec.daftarKelurahan.map((kel) {
                    return DropdownMenuItem(value: kel, child: Text(kel));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedKelurahan = val);
                  },
                ),
                const SizedBox(height: 12),

                // Faskes Pelapor
                const Text('Faskes Penemu / Rujukan:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFaskesId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration(),
                  items: widget.faskesList.map((f) {
                    return DropdownMenuItem(
                      value: f.id,
                      child: Text(f.nama, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedFaskesId = val);
                  },
                ),
                const SizedBox(height: 12),

                // Usia & Gender
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Usia (Tahun):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 4),
                          TextFormField(
                            initialValue: '$_usia',
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: _inputDecoration(),
                            onChanged: (val) => _usia = int.tryParse(val) ?? 30,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jenis Kelamin:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _jenisKelamin,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: _inputDecoration(),
                            items: const [
                              DropdownMenuItem(value: 'L', child: Text('Laki-laki (L)')),
                              DropdownMenuItem(value: 'P', child: Text('Perempuan (P)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _jenisKelamin = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status Pasien
                const Text('Status Pengobatan TB:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                DropdownButtonFormField<CaseStatus>(
                  initialValue: _selectedStatus,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration(),
                  items: CaseStatus.values.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s.label));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
                const SizedBox(height: 12),

                // Catatan Klinis
                const Text('Catatan Tambahan (De-Identified):', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: _catatan,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: _inputDecoration(),
                  onChanged: (val) => _catatan = val,
                ),
                const SizedBox(height: 20),

                // Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.flash_on, size: 16),
                      label: const Text('Simpan & Siarkan Pembaruan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      fillColor: const Color(0xFF1E293B),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    );
  }
}
