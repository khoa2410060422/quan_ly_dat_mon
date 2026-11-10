class ChiTietDonHangModel {
  final int? maChiTietDon;
  final int maDon;
  final int maThucDon;
  final int soLuong;
  final double giaBan;

  // Thuộc tính join
  final String? tenMon;
  final String? hinhAnh;

  ChiTietDonHangModel({
    this.maChiTietDon,
    required this.maDon,
    required this.maThucDon,
    required this.soLuong,
    required this.giaBan,
    this.tenMon,
    this.hinhAnh,
  });

  double get thanhTien => soLuong * giaBan;

  Map<String, dynamic> toMap() {
    return {
      if (maChiTietDon != null) 'ma_chi_det_don': maChiTietDon,
      'ma_don': maDon,
      'ma_thuc_don': maThucDon,
      'so_luong': soLuong,
      'gia_ban': giaBan,
    };
  }

  factory ChiTietDonHangModel.fromMap(Map<String, dynamic> map) {
    return ChiTietDonHangModel(
      maChiTietDon: map['ma_chi_det_don'] is int
          ? map['ma_chi_det_don']
          : int.tryParse(map['ma_chi_det_don']?.toString() ?? ''),
      maDon: map['ma_don'] is int
          ? map['ma_don']
          : int.tryParse(map['ma_don']?.toString() ?? '0') ?? 0,
      maThucDon: map['ma_thuc_don'] is int
          ? map['ma_thuc_don']
          : int.tryParse(map['ma_thuc_don']?.toString() ?? '0') ?? 0,
      soLuong: (map['so_luong'] as num?)?.toInt() ?? 0,
      giaBan: (map['gia_ban'] as num?)?.toDouble() ?? 0.0,
      tenMon: map['ten_mon']?.toString(),
      hinhAnh: map['hinh_anh']?.toString(),
    );
  }
}

