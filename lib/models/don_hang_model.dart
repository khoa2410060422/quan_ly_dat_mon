class DonHangModel {
  final int? maDon;
  final String maSv;
  final String ngayDat;
  final String thoiGianDat;
  final double tongTien;
  final String trangThaiDon;
  final String? ghiChu;
  final String? phuongThucThanhToan;

  // Thuộc tính join từ QUAN_LY_BEP & SINH_VIEN
  final String? trangThaiBep;
  final String? thoiGianXacNhan;
  final String? thoiGianHoanThanh;
  final String? ghiChuBep;
  final String? hoTenSv;
  final String? soDienThoaiSv;

  DonHangModel({
    this.maDon,
    required this.maSv,
    required this.ngayDat,
    required this.thoiGianDat,
    required this.tongTien,
    required this.trangThaiDon,
    this.ghiChu,
    this.phuongThucThanhToan = 'Chuyển khoản QR',
    this.trangThaiBep,
    this.thoiGianXacNhan,
    this.thoiGianHoanThanh,
    this.ghiChuBep,
    this.hoTenSv,
    this.soDienThoaiSv,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maDon != null) 'ma_don': maDon,
      'ma_sv': maSv,
      'ngay_dat': ngayDat,
      'thoi_gian_dat': thoiGianDat,
      'tong_tien': tongTien,
      'trang_thai_don': trangThaiDon,
      'ghi_chu': ghiChu,
      'phuong_thuc_thanh_toan': phuongThucThanhToan,
    };
  }

  factory DonHangModel.fromMap(Map<String, dynamic> map) {
    return DonHangModel(
      maDon: map['ma_don'] is int
          ? map['ma_don']
          : int.tryParse(map['ma_don']?.toString() ?? ''),
      maSv: map['ma_sv']?.toString() ?? '',
      ngayDat: map['ngay_dat']?.toString() ?? '',
      thoiGianDat: map['thoi_gian_dat']?.toString() ?? '',
      tongTien: (map['tong_tien'] as num?)?.toDouble() ?? 0.0,
      trangThaiDon: map['trang_thai_don']?.toString() ?? 'cho_xac_nhan',
      ghiChu: map['ghi_chu']?.toString(),
      phuongThucThanhToan: map['phuong_thuc_thanh_toan']?.toString() ?? 'Chuyển khoản QR',
      trangThaiBep: map['trang_thai_bep']?.toString(),
      thoiGianXacNhan: map['thoi_gian_xac_nhan']?.toString(),
      thoiGianHoanThanh: map['thoi_gian_hoan_thanh']?.toString(),
      ghiChuBep: map['ghi_chu_bep']?.toString(),
      hoTenSv: map['ho_ten']?.toString(),
      soDienThoaiSv: map['so_dien_thoai']?.toString(),
    );
  }
}
