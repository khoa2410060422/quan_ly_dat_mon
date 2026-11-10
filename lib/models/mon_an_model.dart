class MonAnModel {
  final int? maMon;
  final String tenMon;
  final double giaMonAn;
  final String? hinhAnh;
  final String? moTa;

  MonAnModel({
    this.maMon,
    required this.tenMon,
    required this.giaMonAn,
    this.hinhAnh,
    this.moTa,
  });

  Map<String, dynamic> toMap() {
    return {
      if (maMon != null) 'ma_mon': maMon,
      'ten_mon': tenMon,
      'gia_mon_an': giaMonAn,
      'hinh_anh': hinhAnh,
      'mo_ta': moTa,
    };
  }

  factory MonAnModel.fromMap(Map<String, dynamic> map) {
    return MonAnModel(
      maMon: map['ma_mon'] is int ? map['ma_mon'] : int.tryParse(map['ma_mon'].toString()),
      tenMon: map['ten_mon']?.toString() ?? '',
      giaMonAn: (map['gia_mon_an'] as num?)?.toDouble() ?? 0.0,
      hinhAnh: map['hinh_anh']?.toString(),
      moTa: map['mo_ta']?.toString(),
    );
  }
}

