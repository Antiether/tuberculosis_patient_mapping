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

class CaseRecord {
  final String id;
  final String kodeKasus;
  final String kecamatanId;
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
    required this.kecamatanId,
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
