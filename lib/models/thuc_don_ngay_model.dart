class ThucDonNgayModel {
  final int? maThucDon;
  final int maMon;
  final String ngayBan; // YYYY-MM-DD
  final int soLuongCungCap;
  final int soLuongDaDat;

  // Thuộc tính từ JOIN bảng QUAY_BAN_MON_AN
  final String tenMon;
  final double giaMonAn;
  final String? hinhAnh;
  final String? moTa;

  ThucDonNgayModel({
    this.maThucDon,
    required this.maMon,
    required this.ngayBan,
    required this.soLuongCungCap,
    this.soLuongDaDat = 0,
    this.tenMon = '',
    this.giaMonAn = 0.0,
    this.hinhAnh,
    this.moTa,
  });

  /// Số lượng còn lại có thể đặt
  int get soLuongConLai {
    int conLai = soLuongCungCap - soLuongDaDat;
    return conLai > 0 ? conLai : 0;
  }

  /// Kiểm tra xem món ăn này đã hết chưa
  bool get daHetMon => soLuongConLai <= 0;

  Map<String, dynamic> toMap() {
    return {
      if (maThucDon != null) 'ma_thuc_don': maThucDon,
      'ma_mon': maMon,
      'ngay_ban': ngayBan,
      'so_luong_cung_cap': soLuongCungCap,
      'so_luong_da_dat': soLuongDaDat,
    };
  }

  factory ThucDonNgayModel.fromMap(Map<String, dynamic> map) {
    return ThucDonNgayModel(
      maThucDon: map['ma_thuc_don'] is int
          ? map['ma_thuc_don']
          : int.tryParse(map['ma_thuc_don']?.toString() ?? ''),
      maMon: map['ma_mon'] is int
          ? map['ma_mon']
          : int.tryParse(map['ma_mon']?.toString() ?? '0') ?? 0,
      ngayBan: map['ngay_ban']?.toString() ?? '',
      soLuongCungCap: (map['so_luong_cung_cap'] as num?)?.toInt() ?? 0,
      soLuongDaDat: (map['so_luong_da_dat'] as num?)?.toInt() ?? 0,
      tenMon: map['ten_mon']?.toString() ?? '',
      giaMonAn: (map['gia_mon_an'] as num?)?.toDouble() ?? 0.0,
      hinhAnh: map['hinh_anh']?.toString(),
      moTa: map['mo_ta']?.toString(),
    );
  }
}

