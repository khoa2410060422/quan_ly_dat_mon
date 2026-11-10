import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/sinh_vien_model.dart';

class SinhVienRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Đăng ký tài khoản sinh viên mới
  Future<bool> dangKy(SinhVienModel sv) async {
    Database db = await _dbHelper.database;
    // Kiểm tra xem mã sinh viên đã tồn tại chưa
    final check = await db.query(
      'SINH_VIEN',
      where: 'ma_sv = ?',
      whereArgs: [sv.maSv.trim()],
    );
    if (check.isNotEmpty) {
      final daXoa = (check.first['da_xoa'] as num?)?.toInt() ?? 0;
      if (daXoa == 1) {
        throw Exception('Mã sinh viên "${sv.maSv}" trước đó đã bị xóa khỏi hệ thống!');
      }
      throw Exception('Mã sinh viên "${sv.maSv}" đã tồn tại trên hệ thống!');
    }

    int result = await db.insert('SINH_VIEN', sv.toMap());
    return result > 0;
  }

  /// Đăng nhập tài khoản sinh viên:
  /// - Kiểm tra xem mã sinh viên có tồn tại hay không
  /// - Nếu tồn tại nhưng tài khoản đã bị admin xóa (da_xoa == 1) -> ném ngoại lệ thông báo
  /// - Nếu hợp lệ và đúng mật khẩu -> trả về SinhVienModel
  Future<SinhVienModel?> dangNhap(String maSv, String matKhau) async {
    Database db = await _dbHelper.database;
    // 1. Kiểm tra tài khoản theo mã sinh viên
    final checkSv = await db.query(
      'SINH_VIEN',
      where: 'ma_sv = ?',
      whereArgs: [maSv.trim()],
    );

    if (checkSv.isEmpty) {
      return null;
    }

    final svData = checkSv.first;
    final int daXoa = (svData['da_xoa'] as num?)?.toInt() ?? 0;
    if (daXoa == 1) {
      throw Exception('Tài khoản đã bị xóa!');
    }

    // 2. Kiểm tra mật khẩu
    if (svData['mat_khau']?.toString() == matKhau) {
      return SinhVienModel.fromMap(svData);
    }

    return null;
  }

  /// Lấy thông tin sinh viên theo mã SV
  Future<SinhVienModel?> getSinhVien(String maSv) async {
    Database db = await _dbHelper.database;
    final res = await db.query(
      'SINH_VIEN',
      where: 'ma_sv = ?',
      whereArgs: [maSv.trim()],
    );
    if (res.isNotEmpty) {
      return SinhVienModel.fromMap(res.first);
    }
    return null;
  }

  /// Lấy danh sách sinh viên (mặc định chỉ lấy tài khoản chưa bị xóa, hoặc tất cả)
  Future<List<SinhVienModel>> getTatCaSinhVien({bool baoGomDaXoa = false}) async {
    Database db = await _dbHelper.database;
    final res = await db.query(
      'SINH_VIEN',
      where: baoGomDaXoa ? null : 'da_xoa = 0',
      orderBy: 'ma_sv ASC',
    );
    return res.map((e) => SinhVienModel.fromMap(e)).toList();
  }

  /// Admin xóa tài khoản sinh viên
  Future<bool> xoaSinhVien(String maSv) async {
    int rows = await _dbHelper.xoaSinhVien(maSv);
    return rows > 0;
  }

  /// Admin khôi phục tài khoản sinh viên
  Future<bool> khoiPhucSinhVien(String maSv) async {
    int rows = await _dbHelper.khoiPhucSinhVien(maSv);
    return rows > 0;
  }
}

