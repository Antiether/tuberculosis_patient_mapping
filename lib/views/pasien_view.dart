import 'package:flutter/material.dart';
import '../models/tb_models.dart';

class PasienView extends StatefulWidget {
  final UserAccount currentUser;
  final PatientProfile patientProfile;
  final Function(MedicationSchedule) onConfirmMedication;
  final VoidCallback onLogout;

  const PasienView({
    super.key,
    required this.currentUser,
    required this.patientProfile,
    required this.onConfirmMedication,
    required this.onLogout,
  });

  @override
  State<PasienView> createState() => _PasienViewState();
}

class _PasienViewState extends State<PasienView> {
  late PatientProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.patientProfile;
  }

  void _handleConfirmDose(MedicationSchedule schedule) {
    setState(() {
      schedule.isTakenToday = true;
      schedule.takenAt = DateTime.now();
    });
    widget.onConfirmMedication(schedule);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 26),
            SizedBox(width: 10),
            Text('Konfirmasi Berhasil!', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terima kasih telah meminum obat ${schedule.medicineName} secara teratur.',
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(90)),
              ),
              child: Text(
                'Tercatat pada: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB\nKepatuhan Anda sangat penting agar kuman TB tuntas dan tidak menjadi kebal obat.',
                style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Selesai', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTaken = _profile.medicationSchedules.every((s) => s.isTakenToday);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 6),
                Text(
                  _profile.namaLengkap,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                  ),
                  child: const Text(
                    'PORTAL PASIEN',
                    style: TextStyle(color: Color(0xFFFBBF24), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Text(
              'No. Registrasi TB: ${_profile.kodePasien} • Faskes: Puskesmas Simpur',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar (Logout)',
            icon: const Icon(Icons.logout, color: Color(0xFFF87171), size: 18),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Pengingat Hari Ini
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: allTaken
                          ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                          : [const Color(0xFF78350F), const Color(0xFFB45309)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          allTaken ? Icons.check_circle_rounded : Icons.alarm_on_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              allTaken
                                  ? 'Hebat! Obat Hari Ini Sudah Diminum'
                                  : 'Pengingat Minum Obat Hari Ini',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              allTaken
                                  ? 'Tetap jaga pola makan dan istirahat cukup. Jadwal berikutnya: Besok pukul 06:30 WIB.'
                                  : 'Silakan konsumsi obat OAT sesuai instruksi dokter sebelum sarapan pagi.',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Kartu Informasi Pasien & Progres Pengobatan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Informasi Terapi OAT Saya',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text('Privasi Terlindungi (UU PDP)', style: TextStyle(color: Color(0xFF64748B), fontSize: 9.5, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      const Divider(color: Color(0xFF1E293B), height: 18),
                      Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _infoItem('Status Pengobatan', _profile.status.label, const Color(0xFF38BDF8)),
                          _infoItem('Fase Terapi', 'Fase Intensif (4FDC)', Colors.amberAccent),
                          _infoItem('Wilayah Domisili', 'Kel. ${_profile.kelurahanNama}, Kec. Tanjung Karang Pusat', Colors.white),
                          _infoItem('PMO Pendamping', '${_profile.pmoNama} (${_profile.pmoKontak})', const Color(0xFF34D399)),
                          _infoItem('Hasil Pemeriksaan Awal', _profile.hasilBtaAwal, Colors.white70),
                          _infoItem('Berat Badan Pasien', '${_profile.beratBadanKg} kg', Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Daftar Jadwal Obat yang Harus Diminum
                const Text(
                  'Jadwal Obat Harian & Konfirmasi Konsumsi',
                  style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Setiap kali Anda meminum obat, tekan tombol konfirmasi agar tercatat oleh petugas Puskesmas.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
                const SizedBox(height: 10),

                ..._profile.medicationSchedules.map((schedule) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: schedule.isTakenToday ? const Color(0xFF10B981) : const Color(0xFFF59E0B).withAlpha(120),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medication_rounded, color: schedule.isTakenToday ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  schedule.medicineName,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: schedule.isTakenToday ? const Color(0xFF10B981).withAlpha(30) : const Color(0xFFEF4444).withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: schedule.isTakenToday ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                ),
                              ),
                              child: Text(
                                schedule.isTakenToday ? '✓ Sudah Diminum' : 'Belum Diminum',
                                style: TextStyle(
                                  color: schedule.isTakenToday ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Dosis: ${schedule.dosage} • Waktu: ${schedule.timeSlot}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(schedule.instruction, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5)),
                        const SizedBox(height: 8),

                        // Progress Hari
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: schedule.currentDay / schedule.totalDays,
                                  backgroundColor: const Color(0xFF0F172A),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Hari ke-${schedule.currentDay} dari ${schedule.totalDays}',
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tombol Konfirmasi Minum Obat
                        if (!schedule.isTakenToday)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _handleConfirmDose(schedule),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text(
                              'Konfirmasi Saya Sudah Minum Obat Ini',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.done_all, color: Color(0xFF10B981), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Dikonfirmasi pada ${schedule.takenAt != null ? "${schedule.takenAt!.hour.toString().padLeft(2, '0')}:${schedule.takenAt!.minute.toString().padLeft(2, '0')} WIB" : "hari ini"}',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Edukasi Pasien TB
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Color(0xFFFBBF24), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Pesan Kesehatan untuk Pasien TB',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _eduBullet('Jangan pernah menghentikan konsumsi obat meskipun badan sudah terasa sehat.'),
                      _eduBullet('Bila air seni/kencing berwarna kemerahan, hal ini wajar karena pengaruh obat Rifampisin.'),
                      _eduBullet('Terapkan etika batuk dengan menutup mulut menggunakan lengan atau tisu.'),
                      _eduBullet('Bila ada keluhan mual hebat atau gatal, segera hubungi petugas Puskesmas.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _eduBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10.5))),
        ],
      ),
    );
  }
}
