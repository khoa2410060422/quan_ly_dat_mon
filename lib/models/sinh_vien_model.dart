class SinhVienModel {
  final String maSv;
  final String hoTen;
  final String soDienThoai;
  final String email;
  final String khoaLop;
  final String matKhau;
  final int daXoa; // 0: hoạt động, 1: đã bị xóa bởi admin

  SinhVienModel({
    required this.maSv,
    required this.hoTen,
    required this.soDienThoai,
    required this.email,
    required this.khoaLop,
    this.matKhau = '123456',
    this.daXoa = 0,
  });

  bool get isDaXoa => daXoa == 1;

  Map<String, dynamic> toMap() {
    return {
      'ma_sv': maSv,
      'ho_ten': hoTen,
      'so_dien_thoai': soDienThoai,
      'Email': email,
      'khoa_lop': khoaLop,
      'mat_khau': matKhau,
      'da_xoa': daXoa,
    };
  }

  factory SinhVienModel.fromMap(Map<String, dynamic> map) {
    return SinhVienModel(
      maSv: map['ma_sv']?.toString() ?? '',
      hoTen: map['ho_ten']?.toString() ?? '',
      soDienThoai: map['so_dien_thoai']?.toString() ?? '',
      email: (map['Email'] ?? map['email'])?.toString() ?? '',
      khoaLop: map['khoa_lop']?.toString() ?? '',
      matKhau: map['mat_khau']?.toString() ?? '123456',
      daXoa: (map['da_xoa'] as num?)?.toInt() ?? 0,
    );
  }
}


