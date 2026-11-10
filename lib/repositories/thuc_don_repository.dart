import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/thuc_don_ngay_model.dart';
import '../models/mon_an_model.dart';

class ThucDonRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Lấy danh sách thực đơn theo ngày bán (YYYY-MM-DD):
  /// - Mỗi món ăn luôn chuẩn 50 phần (vào đầu ngày tự động làm mới đủ 50 suất).
  /// - Khi sinh viên hoàn tất đặt hàng thì trừ số lượng.
  /// - Nếu đơn hàng bị hủy thì tự động cộng hoàn trả lại đủ số lượng.
  Future<List<ThucDonNgayModel>> getThucDonTheoNgay(String ngayBan) async {
    // 1. Tự động đồng bộ và làm mới thực đơn ngày
    await _dbHelper.dongBoThucDonNgay(ngayBan);

    // 2. Truy vấn danh sách món ăn của ngày
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT 
        TD.ma_thuc_don,
        TD.ma_mon,
        TD.ngay_ban,
        TD.so_luong_cung_cap,
        TD.so_luong_da_dat,
        M.ten_mon,
        M.gia_mon_an,
        M.hinh_anh,
        M.mo_ta
      FROM THUC_DON_NGAY TD
      JOIN QUAY_BAN_MON_AN M ON TD.ma_mon = M.ma_mon
      WHERE TD.ngay_ban = ?
      ORDER BY TD.ma_thuc_don ASC
    ''', [ngayBan]);

    return res.map((e) => ThucDonNgayModel.fromMap(e)).toList();
  }

  /// Lấy danh sách tất cả các ngày có thực đơn
  Future<List<String>> getDanhSachNgayCoThucDon() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT DISTINCT ngay_ban FROM THUC_DON_NGAY ORDER BY ngay_ban ASC
    ''');
    return res.map((e) => e['ngay_ban'] as String).toList();
  }

  /// Lấy danh mục món ăn gốc của quầy cantin
  Future<List<MonAnModel>> getTatCaMonAn() async {
    Database db = await _dbHelper.database;
    final res = await db.query('QUAY_BAN_MON_AN', orderBy: 'ma_mon ASC');
    return res.map((e) => MonAnModel.fromMap(e)).toList();
  }

  /// Lấy thông tin 1 món trong thực đơn ngày
  Future<ThucDonNgayModel?> getChiTietThucDon(int maThucDon) async {
    Database db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT 
        TD.ma_thuc_don,
        TD.ma_mon,
        TD.ngay_ban,
        TD.so_luong_cung_cap,
        TD.so_luong_da_dat,
        M.ten_mon,
        M.gia_mon_an,
        M.hinh_anh,
        M.mo_ta
      FROM THUC_DON_NGAY TD
      JOIN QUAY_BAN_MON_AN M ON TD.ma_mon = M.ma_mon
      WHERE TD.ma_thuc_don = ?
    ''', [maThucDon]);

    if (res.isNotEmpty) {
      return ThucDonNgayModel.fromMap(res.first);
    }
    return null;
  }
}

