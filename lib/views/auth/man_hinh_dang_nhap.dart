import 'package:flutter/material.dart';
import '../../repositories/sinh_vien_repository.dart';
import '../thuc_don/man_hinh_thuc_don.dart';
import '../bep/man_hinh_quan_ly_bep.dart';
import 'man_hinh_dang_ky.dart';

class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({super.key});

  @override
  State<ManHinhDangNhap> createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  bool _isAdminMode = false; // false = Sinh viên, true = Admin / Bếp

  // Form Sinh viên
  final _svFormKey = GlobalKey<FormState>();
  final _maSvController = TextEditingController(text: 'SV001');
  final _svMatKhauController = TextEditingController(text: '123456');

  // Form Admin / Bếp
  final _adminFormKey = GlobalKey<FormState>();
  final _adminUserController = TextEditingController(text: 'admin');
  final _adminPassController = TextEditingController(text: 'admin123');

  final _sinhVienRepo = SinhVienRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _dangNhapSinhVien() async {
    if (!_svFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sv = await _sinhVienRepo.dangNhap(
        _maSvController.text,
        _svMatKhauController.text,
      );

      if (!mounted) return;

      if (sv != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xin chào sinh viên ${sv.hoTen}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ManHinhThucDon(sinhVien: sv),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã sinh viên hoặc mật khẩu không đúng!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dangNhapAdmin() async {
    if (!_adminFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _adminUserController.text.trim().toLowerCase();
      final pass = _adminPassController.text.trim();

      // Kiểm tra tài khoản Admin / Bếp
      bool hopLe = (user == 'admin' && (pass == 'admin123' || pass == '123456' || pass == 'admin')) ||
          (user == 'bep' && (pass == '123456' || pass == 'bep'));

      if (hopLe) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đăng nhập Quản Trị / Bếp thành công!'),
            backgroundColor: Colors.deepPurple,
            duration: Duration(seconds: 1),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManHinhQuanLyBep()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tài khoản hoặc mật khẩu Quản Trị Viên không chính xác!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = _isAdminMode ? Colors.deepPurple : Colors.deepOrange;

    return Scaffold(
      backgroundColor: _isAdminMode ? Colors.deepPurple.shade50 : Colors.orange.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Tiêu đề
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isAdminMode ? Icons.soup_kitchen_rounded : Icons.restaurant_menu_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isAdminMode ? 'HỆ THỐNG QUẢN LÝ BẾP' : 'CANTIN SINH VIÊN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isAdminMode
                      ? 'Dành riêng cho Quản lý & Nhân viên Bếp tiếp nhận đơn'
                      : 'Đặt món ăn trưa nhanh chóng, tiện lợi & chuẩn vị',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card Đăng nhập
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tab chuyển vai trò đăng nhập
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Tooltip(
                                  message: 'Đăng nhập dành cho Sinh Viên đặt món',
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_isAdminMode) setState(() => _isAdminMode = false);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: !_isAdminMode ? Colors.deepOrange : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: !_isAdminMode
                                            ? [
                                                const BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                )
                                              ]
                                            : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.school_rounded,
                                            size: 18,
                                            color: !_isAdminMode ? Colors.white : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Sinh Viên',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: !_isAdminMode ? Colors.white : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Tooltip(
                                  message: 'Đăng nhập dành cho Quản lý & Nhà Bếp',
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!_isAdminMode) setState(() => _isAdminMode = true);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isAdminMode ? Colors.deepPurple : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: _isAdminMode
                                            ? [
                                                const BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                )
                                              ]
                                            : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.admin_panel_settings_rounded,
                                            size: 18,
                                            color: _isAdminMode ? Colors.white : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Bếp (Admin)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _isAdminMode ? Colors.white : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Form đăng nhập tương ứng
                        if (!_isAdminMode) _buildSinhVienForm() else _buildAdminForm(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                Text(
                  _isAdminMode
                      ? 'Tài khoản Admin: admin | Mật khẩu: admin123'
                      : 'Tài khoản mẫu: SV001 hoặc SV002 | Mật khẩu: 123456',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinhVienForm() {
    return Form(
      key: _svFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Đăng Nhập Sinh Viên',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Ô nhập Mã sinh viên
          TextFormField(
            controller: _maSvController,
            decoration: InputDecoration(
              labelText: 'Mã Sinh Viên',
              hintText: 'Ví dụ: SV001',
              prefixIcon: const Icon(Icons.badge_outlined, color: Colors.deepOrange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã sinh viên' : null,
          ),
          const SizedBox(height: 14),

          // Ô nhập Mật khẩu
          TextFormField(
            controller: _svMatKhauController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật Khẩu',
              hintText: 'Nhập mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepOrange),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
          ),
          const SizedBox(height: 20),

          // Nút Đăng nhập SV
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: _isLoading ? null : _dangNhapSinhVien,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'ĐĂNG NHẬP SINH VIÊN',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 12),

          // Nút Chuyển sang Đăng ký
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepOrange,
              side: const BorderSide(color: Colors.deepOrange),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Chưa có tài khoản? Đăng ký ngay'),
            onPressed: () async {
              final newMaSv = await Navigator.push<String?>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManHinhDangKy(),
                ),
              );
              if (newMaSv != null && newMaSv.isNotEmpty) {
                setState(() {
                  _maSvController.text = newMaSv;
                  _svMatKhauController.clear();
                  _isAdminMode = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminForm() {
    return Form(
      key: _adminFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Đăng Nhập Quản Trị / Bếp',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Chỉ tài khoản admin mới có quyền truy cập tiếp nhận và xử lý đơn bếp.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          // Ô nhập Tài khoản Admin
          TextFormField(
            controller: _adminUserController,
            decoration: InputDecoration(
              labelText: 'Tài Khoản Admin',
              hintText: 'admin',
              prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.deepPurple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tài khoản admin' : null,
          ),
          const SizedBox(height: 14),

          // Ô nhập Mật khẩu Admin
          TextFormField(
            controller: _adminPassController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật Khẩu Quản Trị',
              hintText: 'Nhập mật khẩu admin',
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepPurple),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu admin' : null,
          ),
          const SizedBox(height: 20),

          // Nút Đăng nhập Admin
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.login_rounded),
            onPressed: _isLoading ? null : _dangNhapAdmin,
            label: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'ĐĂNG NHẬP VÀO NHÀ BẾP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
