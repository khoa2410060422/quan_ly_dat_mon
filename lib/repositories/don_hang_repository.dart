import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/don_hang_model.dart';
import '../models/chi_tiet_don_hang_model.dart';

class DonHangRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Thêm đơn hàng mới và tự động trừ số lượng món ăn trong ngày
  Future<int> taoDonHangMoi({
    required Map<String, dynamic> donHang,
    required List<Map<String, dynamic>> chiTietList,
  }) async {
    return await _dbHelper.taoDonHangMoi(
      donHang: donHang,
      chiTietList: chiTietList,
    );
  }

  /// Lấy danh sách đơn hàng của sinh viên
  Future<List<DonHangModel>> getDanhSachDonHang(String maSv) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
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
      LEFT JOIN QUAN_LY_BEP BP ON DH.ma_don = BP.ma_don
      LEFT JOIN SINH_VIEN SV ON DH.ma_sv = SV.ma_sv
      WHERE DH.ma_sv = ?
      ORDER BY DH.ma_don DESC
    ''', [maSv]);

    return res.map((e) => DonHangModel.fromMap(e)).toList();
  }

  /// Lấy chi tiết đơn hàng (thông tin đơn + trạng thái bếp)
  Future<DonHangModel?> getDonHangById(int maDon) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
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
      LEFT JOIN QUAN_LY_BEP BP ON DH.ma_don = BP.ma_don
      LEFT JOIN SINH_VIEN SV ON DH.ma_sv = SV.ma_sv
      WHERE DH.ma_don = ?
    ''', [maDon]);

    if (res.isNotEmpty) {
      return DonHangModel.fromMap(res.first);
    }
    return null;
  }

  /// Lấy danh sách các món ăn trong đơn hàng
  Future<List<ChiTietDonHangModel>> getChiTietDonHang(int maDon) async {
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

  /// Hủy đơn hàng và tự động CỘNG HOÀN TRẢ lại số lượng món ăn vào thực đơn ngày
  Future<void> huyDonHang(int maDon, {required String lyDoHuy}) async {
    await _dbHelper.bepHuyDon(maDon, lyDoHuy: lyDoHuy);
  }
}
