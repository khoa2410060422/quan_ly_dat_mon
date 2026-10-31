import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/don_hang_model.dart';
import '../models/chi_tiet_don_hang_model.dart';

class BepRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Lấy danh sách tất cả các đơn hàng cho quầy Bếp
  Future<List<DonHangModel>> getDanhSachDonBep({String? locTrangThai}) async {
    Database db = await _dbHelper.database;
    String sql = '''
      SELECT 
        DH.ma_don,
        DH.ma_sv,
        DH.ngay_dat,
        DH.thoi_gian_dat,
        DH.tong_tien,
        DH.trang_thai_don,
        DH.ghi_chu,
        DH.phuong_thuc_thanh_toan,
        BP.trang_thai_bep,
        BP.thoi_gian_xac_nhan,
        BP.thoi_gian_hoan_thanh,
        BP.ghi_chu_bep,
        SV.ho_ten,
        SV.so_dien_thoai
      FROM DON_HANG DH
      JOIN QUAN_LY_BEP BP ON DH.ma_don = BP.ma_don
      JOIN SINH_VIEN SV ON DH.ma_sv = SV.ma_sv
    ''';

    List<dynamic> args = [];
    if (locTrangThai != null && locTrangThai.isNotEmpty) {
      sql += ' WHERE BP.trang_thai_bep = ? ';
      args.add(locTrangThai);
    }

    sql += ' ORDER BY DH.ma_don DESC ';

    final List<Map<String, dynamic>> res = await db.rawQuery(sql, args);
    return res.map((e) => DonHangModel.fromMap(e)).toList();
  }

  /// Lấy chi tiết món ăn của 1 đơn hàng cho Bếp theo dõi
  Future<List<ChiTietDonHangModel>> getChiTietDonChoBep(int maDon) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT 
        CT.ma_chi_det_don,
        CT.ma_don,
        CT.ma_thuc_don,
        CT.so_luong,
        CT.gia_ban,
        M.ten_mon,
        M.hinh_anh
      FROM CHI_TIET_DON_HANG CT
      JOIN THUC_DON_NGAY TD ON CT.ma_thuc_don = TD.ma_thuc_don
      JOIN QUAY_BAN_MON_AN M ON TD.ma_mon = M.ma_mon
      WHERE CT.ma_don = ?
      ORDER BY CT.ma_chi_det_don ASC
    ''', [maDon]);

    return res.map((e) => ChiTietDonHangModel.fromMap(e)).toList();
  }

  /// Bếp xác nhận nhận đơn -> bắt đầu nấu
  Future<void> xacNhanNhanDon(int maDon, {String? ghiChu}) async {
    await _dbHelper.bepXacNhanDon(maDon, ghiChuBep: ghiChu);
  }

  /// Bếp hủy đơn -> CỘNG HOÀN TRẢ SỐ LƯỢNG MÓN ĂN
  Future<void> huyDonHang(int maDon, {required String lyDoHuy}) async {
    await _dbHelper.bepHuyDon(maDon, lyDoHuy: lyDoHuy);
  }

  /// Bếp nấu xong -> Báo cho sinh viên đến lấy
  Future<void> hoanTatNau(int maDon, {String? ghiChu}) async {
    await _dbHelper.bepHoanTatNau(maDon, ghiChuBep: ghiChu);
  }

  /// Đã giao món cho sinh viên
  Future<void> giaoMonHoanTat(int maDon) async {
    await _dbHelper.bepGiaoXongDon(maDon);
  }

  /// Thống kê số lượng đơn theo các trạng thái
  Future<Map<String, int>> thongKeSoLuongDon() async {
    Database db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT trang_thai_bep, COUNT(*) as so_luong
      FROM QUAN_LY_BEP
      GROUP BY trang_thai_bep
    ''');

    Map<String, int> counts = {
      'cho_xac_nhan': 0,
      'dang_che_bien': 0,
      'cho_nhan': 0,
      'da_hoan_thanh': 0,
      'da_huy': 0,
    };

    for (var r in res) {
      String key = r['trang_thai_bep'] as String;
      int count = (r['so_luong'] as num).toInt();
      counts[key] = count;
    }
    return counts;
  }

  /// Thống kê tổng quan cho Quản lý Bếp:
  /// - Tổng đơn đã hoàn tất
  /// - Tổng đơn đã hủy
  /// - Tổng doanh thu (tổng tiền các đơn đã hoàn tất)
  Future<Map<String, dynamic>> thongKeTongQuanBep() async {
    Database db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT 
        COUNT(CASE WHEN COALESCE(BP.trang_thai_bep, DH.trang_thai_don) = 'da_hoan_thanh' THEN 1 END) as tong_hoan_thanh,
        COUNT(CASE WHEN COALESCE(BP.trang_thai_bep, DH.trang_thai_don) = 'da_huy' THEN 1 END) as tong_huy,
        COALESCE(SUM(CASE WHEN COALESCE(BP.trang_thai_bep, DH.trang_thai_don) = 'da_hoan_thanh' THEN DH.tong_tien ELSE 0 END), 0) as tong_doanh_thu
      FROM DON_HANG DH
      LEFT JOIN QUAN_LY_BEP BP ON DH.ma_don = BP.ma_don
    ''');

    if (res.isNotEmpty) {
      return {
        'tong_hoan_thanh': (res.first['tong_hoan_thanh'] as num?)?.toInt() ?? 0,
        'tong_huy': (res.first['tong_huy'] as num?)?.toInt() ?? 0,
        'tong_doanh_thu': (res.first['tong_doanh_thu'] as num?)?.toDouble() ?? 0.0,
      };
    }
    return {
      'tong_hoan_thanh': 0,
      'tong_huy': 0,
      'tong_doanh_thu': 0.0,
    };
  }
}

