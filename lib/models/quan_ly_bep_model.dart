class QuanLyBepModel {
  final int? maBep;
  final int maDon;
  final String trangThaiBep;
  final String? thoiGianXacNhan;
  final String? thoiGianHoanThanh;
  final String? ghiChuBep;

  QuanLyBepModel({
    this.maBep,
    required this.maDon,
    required this.trangThaiBep,
    this.thoiGianXacNhan,
    this.thoiGianHoanThanh,
    this.ghiChuBep,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maBep != null) 'ma_bep': maBep,
      'ma_don': maDon,
      'trang_thai_bep': trangThaiBep,
      'thoi_gian_xac_nhan': thoiGianXacNhan,
      'thoi_gian_hoan_thanh': thoiGianHoanThanh,
      'ghi_chu_bep': ghiChuBep,
    };
  }

  factory QuanLyBepModel.fromMap(Map<String, dynamic> map) {
    return QuanLyBepModel(
      maBep: map['ma_bep'] is int
          ? map['ma_bep']
          : int.tryParse(map['ma_bep']?.toString() ?? ''),
      maDon: map['ma_don'] is int
          ? map['ma_don']
          : int.tryParse(map['ma_don']?.toString() ?? '0') ?? 0,
      trangThaiBep: map['trang_thai_bep']?.toString() ?? 'cho_xac_nhan',
      thoiGianXacNhan: map['thoi_gian_xac_nhan']?.toString(),
      thoiGianHoanThanh: map['thoi_gian_hoan_thanh']?.toString(),
      ghiChuBep: map['ghi_chu_bep']?.toString(),
    );
  }
}

