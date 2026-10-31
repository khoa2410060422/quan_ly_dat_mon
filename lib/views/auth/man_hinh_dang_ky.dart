import 'package:flutter/material.dart';
import '../../models/sinh_vien_model.dart';
import '../../repositories/sinh_vien_repository.dart';
import 'man_hinh_dang_nhap.dart';

class ManHinhDangKy extends StatefulWidget {
  const ManHinhDangKy({super.key});

  @override
  State<ManHinhDangKy> createState() => _ManHinhDangKyState();
}

class _ManHinhDangKyState extends State<ManHinhDangKy> {
  final _formKey = GlobalKey<FormState>();

  final _maSvController = TextEditingController();
  final _hoTenController = TextEditingController();
  final _sdtController = TextEditingController();
  final _emailController = TextEditingController();
  final _khoaLopController = TextEditingController();
  final _matKhauController = TextEditingController();

  final _sinhVienRepo = SinhVienRepository();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _dangKy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sv = SinhVienModel(
        maSv: _maSvController.text.trim().toUpperCase(),
        hoTen: _hoTenController.text.trim(),
        soDienThoai: _sdtController.text.trim(),
        email: _emailController.text.trim(),
        khoaLop: _khoaLopController.text.trim(),
        matKhau: _matKhauController.text.trim(),
      );

      await _sinhVienRepo.dangKy(sv);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo tài khoản "${sv.maSv}" thành công! Vui lòng đăng nhập.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Trở về màn hình đăng nhập
      if (Navigator.canPop(context)) {
        Navigator.pop(context, sv.maSv);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ManHinhDangNhap()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký thất bại: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản Sinh Viên'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Thông Tin Sinh Viên',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vui lòng điền đúng thông tin sinh viên để cantin chuẩn bị món và liên hệ nhận suất ăn.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // 1. Mã Sinh Viên (PK)
                TextFormField(
                  controller: _maSvController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Mã Sinh Viên (PK) *',
                    hintText: 'Ví dụ: SV003, B20DCCN001',
                    prefixIcon: const Icon(Icons.badge, color: Colors.deepOrange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mã sinh viên';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 2. Họ và Tên
                TextFormField(
                  controller: _hoTenController,
                  decoration: InputDecoration(
                    labelText: 'Họ và Tên *',
                    hintText: 'Ví dụ: Nguyễn Văn Bình',
                    prefixIcon: const Icon(Icons.person, color: Colors.deepOrange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 3. Số Điện Thoại
                TextFormField(
                  controller: _sdtController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số Điện Thoại *',
                    hintText: 'Ví dụ: 0912345678',
                    prefixIcon: const Icon(Icons.phone, color: Colors.deepOrange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                    if (v.trim().length < 9) return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 4. Email cơ sở
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email của cơ sở *',
                    hintText: 'Ví dụ: binh.nv@stu.edu.vn',
                    prefixIcon: const Icon(Icons.email, color: Colors.deepOrange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 5. Khoa - Lớp
                TextFormField(
                  controller: _khoaLopController,
                  decoration: InputDecoration(
                    labelText: 'Khoá / Lớp *',
                    hintText: 'Ví dụ: CNTT K18 - Lớp D18CN01',
                    prefixIcon: const Icon(Icons.school, color: Colors.deepOrange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập khoá / lớp';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 6. Mật khẩu
                TextFormField(
                  controller: _matKhauController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật Khẩu *',
                    hintText: 'Tối thiểu 6 ký tự',
                    prefixIcon: const Icon(Icons.lock, color: Colors.deepOrange),
                    suffixIcon: IconButton(
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.length < 4) return 'Mật khẩu phải từ 4 ký tự trở lên';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Nút Đăng Ký
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _dangKy,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'HOÀN TẤT ĐĂNG KÝ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),

                // Nút quay lại Đăng nhập
                TextButton.icon(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ManHinhDangNhap()),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
                  label: const Text(
                    'Đã có tài khoản? Quay lại Đăng nhập',
                    style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

