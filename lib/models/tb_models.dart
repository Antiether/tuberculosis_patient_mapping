enum RiskLevel { high, medium, low }

enum CaseStatus {
  pengobatanIntensif,
  pengobatanLanjutan,
  sembuh,
  putusObat,
  meninggal,
}

extension CaseStatusExt on CaseStatus {
  String get label {
    switch (this) {
      case CaseStatus.pengobatanIntensif:
        return 'Tahap Intensif';
      case CaseStatus.pengobatanLanjutan:
        return 'Tahap Lanjutan';
      case CaseStatus.sembuh:
        return 'Sembuh Total';
      case CaseStatus.putusObat:
        return 'Putus Obat (Default)';
      case CaseStatus.meninggal:
        return 'Meninggal Dunia';
    }
  }
}

enum UserRole {
  admin,    // Admin / Pengelola Program Dinkes
  petugas,  // Petugas Kesehatan Faskes
  pasien,   // Pasien TB
}

extension UserRoleExt on UserRole {
  String get title {
    switch (this) {
      case UserRole.admin:
        return 'Admin / Pengelola Program';
      case UserRole.petugas:
        return 'Petugas Kesehatan Faskes';
      case UserRole.pasien:
        return 'Pasien TB';
    }
  }
}

class UserAccount {
  final String id;
  final String username;
  final String password;
  final String fullName;
  final UserRole role;
  final String? facilityId;
  final String? facilityName;
  final String? patientId;

  UserAccount({
    required this.id,
    required this.username,
    required this.password,
    required this.fullName,
    required this.role,
    this.facilityId,
    this.facilityName,
    this.patientId,
  });
}

class KelurahanData {
  final String id;
  final String nama;
  final String kecamatanId;
  int jumlahKasus;
  final int jumlahPenduduk;

  KelurahanData({
    required this.id,
    required this.nama,
    required this.kecamatanId,
    required this.jumlahKasus,
    required this.jumlahPenduduk,
  });

  RiskLevel get riskLevel {
    if (jumlahKasus >= 8) return RiskLevel.high;
    if (jumlahKasus >= 4) return RiskLevel.medium;
    return RiskLevel.low;
  }
}

class KecamatanData {
  final String id;
  final String nama;
  final double lat;
  final double lng;
  final int jumlahPenduduk;
  int jumlahKasus;
  final List<String> faskesIds;
  final List<String> daftarKelurahan;

  KecamatanData({
    required this.id,
    required this.nama,
    required this.lat,
    required this.lng,
    required this.jumlahPenduduk,
    required this.jumlahKasus,
    required this.faskesIds,
    required this.daftarKelurahan,
  });

  RiskLevel get riskLevel {
    if (jumlahKasus >= 35) return RiskLevel.high;
    if (jumlahKasus >= 18) return RiskLevel.medium;
    return RiskLevel.low;
  }

  double get caseRatePer10k => (jumlahKasus / jumlahPenduduk) * 10000;
}

class FaskesData {
  final String id;
  final String nama;
  final String tipe; // Puskesmas / Rumah Sakit
  final String alamat;
  final double lat;
  final double lng;
  final String kontak;
  final bool hasTCM; // Tes Cepat Molekuler

  FaskesData({
    required this.id,
    required this.nama,
    required this.tipe,
    required this.alamat,
    required this.lat,
    required this.lng,
    required this.kontak,
    required this.hasTCM,
  });
}

class MedicationSchedule {
  final String id;
  final String patientId;
  final String medicineName;
  final String dosage;
  final String instruction;
  final String timeSlot;
  final String phase;
  final int totalDays;
  final int currentDay;
  bool isTakenToday;
  DateTime? takenAt;

  MedicationSchedule({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.instruction,
    required this.timeSlot,
    required this.phase,
    required this.totalDays,
    required this.currentDay,
    this.isTakenToday = false,
    this.takenAt,
  });
}

class PatientProfile {
  final String id;
  final String kodePasien;
  final String namaLengkap;
  final String nikMasked;
  final int usia;
  final String jenisKelamin; // 'L' / 'P'
  final String kecamatanId;
  final String kelurahanId;
  final String kelurahanNama;
  final String facilityId;
  CaseStatus status;
  final DateTime tanggalMulai;
  final double beratBadanKg;
  final String hasilBtaAwal;
  final String pmoNama; // Pengawas Menelan Obat
  final String pmoKontak;
  final List<MedicationSchedule> medicationSchedules;

  PatientProfile({
    required this.id,
    required this.kodePasien,
    required this.namaLengkap,
    required this.nikMasked,
    required this.usia,
    required this.jenisKelamin,
    required this.kecamatanId,
    required this.kelurahanId,
    required this.kelurahanNama,
    required this.facilityId,
    required this.status,
    required this.tanggalMulai,
    required this.beratBadanKg,
    required this.hasilBtaAwal,
    required this.pmoNama,
    required this.pmoKontak,
    required this.medicationSchedules,
  });
}

class CaseRecord {
  final String id;
  final String kodeKasus;
  final String? patientId;
  final String kecamatanId;
  final String? kelurahanId;
  final String kelurahan;
  final int usia;
  final String jenisKelamin; // 'L' / 'P'
  CaseStatus status;
  final DateTime tanggalDiagnosis;
  final String faskesId;
  final String catatan;

  CaseRecord({
    required this.id,
    required this.kodeKasus,
    this.patientId,
    required this.kecamatanId,
    this.kelurahanId,
    required this.kelurahan,
    required this.usia,
    required this.jenisKelamin,
    required this.status,
    required this.tanggalDiagnosis,
    required this.faskesId,
    required this.catatan,
  });
}

class RealTimeUpdateLog {
  final DateTime timestamp;
  final String aksi;
  final String detail;
  final int latensiMs;

  RealTimeUpdateLog({
    required this.timestamp,
    required this.aksi,
    required this.detail,
    required this.latensiMs,
  });
}
