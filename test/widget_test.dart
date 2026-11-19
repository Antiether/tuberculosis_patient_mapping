import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuberculosis_mapping/main.dart';
import 'package:tuberculosis_mapping/data/mock_data.dart';
import 'package:tuberculosis_mapping/models/tb_models.dart';
import 'package:tuberculosis_mapping/views/admin_view.dart';
import 'package:tuberculosis_mapping/views/petugas_view.dart';

void main() {
  testWidgets('TB Mapping smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TbMappingApp());
    expect(find.textContaining('TB'), findsWidgets);
  });

  testWidgets('admin tab controllers mount without ticker errors', (
    WidgetTester tester,
  ) async {
    final users = MockDataRepository.getMockUsers();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminView(
          currentUser: users.firstWhere((user) => user.role == UserRole.admin),
          kecamatanList: MockDataRepository.getInitialKecamatanList(),
          faskesList: MockDataRepository.getInitialFaskesList(),
          caseRecords: MockDataRepository.getInitialCaseRecords(),
          patientList: MockDataRepository.getInitialPatients(),
          latestLog: null,
          selectedKecamatan: null,
          onSelectKecamatan: (_) {},
          onSelectFaskes: (_) {},
          onAddCase: (_, _) {},
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peta'), findsOneWidget);
    expect(find.text('Statistik'), findsOneWidget);
  });

  testWidgets('petugas view provides an area map tab', (
    WidgetTester tester,
  ) async {
    final users = MockDataRepository.getMockUsers();
    await tester.pumpWidget(
      MaterialApp(
        home: PetugasView(
          currentUser: users.firstWhere(
            (user) => user.role == UserRole.petugas,
          ),
          kecamatanList: MockDataRepository.getInitialKecamatanList(),
          kelurahanList: MockDataRepository.getInitialKelurahanList(),
          faskesList: MockDataRepository.getInitialFaskesList(),
          caseRecords: MockDataRepository.getInitialCaseRecords(),
          patientList: MockDataRepository.getInitialPatients(),
          selectedKecamatan: null,
          onSelectKecamatan: (_) {},
          onSelectFaskes: (_) {},
          onAddCase: (_, _) {},
          onUpdatePatient: (_) {},
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peta Wilayah'), findsOneWidget);
    expect(find.text('Daftar Pasien Faskes'), findsOneWidget);
  });
}
