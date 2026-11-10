import 'package:flutter/material.dart';
import '../../models/sinh_vien_model.dart';
import '../auth/man_hinh_dang_nhap.dart';
import '../don_hang/man_hinh_danh_sach_don_hang.dart';

class ManHinhThongTinSv extends StatelessWidget {
  final SinhVienModel sinhVien;

  const ManHinhThongTinSv({super.key, required this.sinhVien});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Hồ Sơ Sinh Viên'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar & Tên
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepOrange.shade100,
                    child: Text(
                      sinhVien.hoTen.isNotEmpty ? sinhVien.hoTen[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sinhVien.hoTen,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'MSSV: ${sinhVien.maSv}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card chi tiết thông tin
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông Tin Chi Tiết (SINH_VIEN)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.badge_outlined, 'Mã sinh viên', sinhVien.maSv),
                    _buildInfoRow(Icons.person_outline, 'Họ và tên', sinhVien.hoTen),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', sinhVien.soDienThoai),
                    _buildInfoRow(Icons.email_outlined, 'Email HUTECH', sinhVien.email),
                    _buildInfoRow(Icons.school_outlined, 'Khoá / Lớp', sinhVien.khoaLop),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Các chức năng tiện ích
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Xem Lịch Sử Đơn Hàng Của Tôi'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManHinhDanhSachDonHang(maSv: sinhVien.maSv)),
                );
              },
            ),
            const SizedBox(height: 14),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng Xuất Tài Khoản'),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ManHinhDangNhap()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.deepOrange),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

