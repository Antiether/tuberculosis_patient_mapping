import 'package:flutter/material.dart';
import '../models/tb_models.dart';
import '../data/mock_data.dart';

class LoginView extends StatefulWidget {
  final Function(UserAccount) onLoginSuccess;
  final VoidCallback onContinueAsGuest;

  const LoginView({
    super.key,
    required this.onLoginSuccess,
    required this.onContinueAsGuest,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController(text: 'admin_dinkes');
  final _passwordController = TextEditingController(text: 'admin123');
  bool _obscurePassword = true;
  String? _errorMessage;

  final List<UserAccount> _mockUsers = MockDataRepository.getMockUsers();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _performLogin([String? username, String? password]) {
    final user = username ?? _usernameController.text.trim();
    final pass = password ?? _passwordController.text.trim();

    setState(() => _errorMessage = null);

    final match = _mockUsers.firstWhere(
      (u) => u.username.toLowerCase() == user.toLowerCase() && u.password == pass,
      orElse: () => UserAccount(
        id: '',
        username: '',
        password: '',
        fullName: '',
        role: UserRole.admin,
      ),
    );

    if (match.id.isNotEmpty) {
      widget.onLoginSuccess(match);
    } else {
      setState(() {
        _errorMessage = 'Username atau password tidak sesuai. Gunakan kartu akun demo di bawah.';
      });
    }
  }

  void _quickFill(String username, String password) {
    _usernameController.text = username;
    _passwordController.text = password;
    _performLogin(username, password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Logo
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withAlpha(45),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF38BDF8), size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sistem Informasi Spasial TB',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dinas Kesehatan Kota Bandar Lampung • Surveilans Real-Time',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 28),

                // Form Login Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(120),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Masuk ke Sistem (RBAC Routing)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih hak akses: Admin/Pengelola, Petugas Faskes, atau Pasien',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                      const SizedBox(height: 20),

                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Input Username
                      const Text('Nama Pengguna (Username)', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDeco(Icons.person_outline, 'Masukkan username'),
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      const Text('Kata Sandi (Password)', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: _inputDeco(
                          Icons.lock_outline,
                          'Masukkan kata sandi',
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade400,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Tombol Submit
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 3,
                        ),
                        onPressed: () => _performLogin(),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Masuk ke Sistem',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Akses Tamu / Publik
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFF334155)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: widget.onContinueAsGuest,
                        icon: const Icon(Icons.public, size: 16),
                        label: const Text('Lihat Peta Agregat Publik (Tanpa Login)', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Kartu Bantuan Akun Uji Coba Demo (1-Click Login)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B132B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.touch_app_rounded, color: Color(0xFFFBBF24), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Akun Uji Coba Demo (1-Click Quick Login):',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Klik salah satu kartu di bawah untuk langsung mencoba routing peran:',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                      ),
                      const SizedBox(height: 12),

                      // Role 1: Admin Dinkes
                      _DemoRoleCard(
                        roleTitle: '1. Admin / Pengelola Program (Dinkes)',
                        username: 'admin_dinkes',
                        password: 'admin123',
                        badgeColor: const Color(0xFF38BDF8),
                        icon: Icons.admin_panel_settings,
                        description: 'Dashboard Kota, Pemetaan bertingkat (Kota→Kecamatan→Kelurahan), Laporan.',
                        onTap: () => _quickFill('admin_dinkes', 'admin123'),
                      ),
                      const SizedBox(height: 8),

                      // Role 2: Petugas Faskes
                      _DemoRoleCard(
                        roleTitle: '2. Petugas Kesehatan (Puskesmas Simpur)',
                        username: 'petugas_simpur',
                        password: 'petugas123',
                        badgeColor: const Color(0xFF34D399),
                        icon: Icons.medical_services_rounded,
                        description: 'Manajemen pasien wilayah, jadwal obat (OAT), pantau kepatuhan harian.',
                        onTap: () => _quickFill('petugas_simpur', 'petugas123'),
                      ),
                      const SizedBox(height: 8),

                      // Role 3: Pasien TB
                      _DemoRoleCard(
                        roleTitle: '3. Pasien TB (Ahmad S. - Rawat Jalan)',
                        username: 'pasien_ahmad',
                        password: 'pasien123',
                        badgeColor: const Color(0xFFF59E0B),
                        icon: Icons.person_rounded,
                        description: 'Privasi 100%, Jadwal minum obat OAT hari ini, tombol konfirmasi minum obat.',
                        onTap: () => _quickFill('pasien_ahmad', 'pasien123'),
                      ),
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

  InputDecoration _inputDeco(IconData icon, String hint, {Widget? suffix}) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF0284C7), size: 18),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 12),
      fillColor: const Color(0xFF1E293B),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
      ),
    );
  }
}

class _DemoRoleCard extends StatelessWidget {
  final String roleTitle;
  final String username;
  final String password;
  final Color badgeColor;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _DemoRoleCard({
    required this.roleTitle,
    required this.username,
    required this.password,
    required this.badgeColor,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withAlpha(150),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: badgeColor.withAlpha(90), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: badgeColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          roleTitle,
                          style: TextStyle(color: badgeColor, fontSize: 11.5, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Klik Masuk', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'User: $username  •  Pass: $password',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
