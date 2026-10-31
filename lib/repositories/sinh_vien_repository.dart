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
      throw Exception('Mã sinh viên "${sv.maSv}" đã tồn tại trên hệ thống!');
    }

    int result = await db.insert('SINH_VIEN', sv.toMap());
    return result > 0;
  }

  /// Đăng nhập tài khoản sinh viên
  Future<SinhVienModel?> dangNhap(String maSv, String matKhau) async {
    Database db = await _dbHelper.database;
    final res = await db.query(
      'SINH_VIEN',
      where: 'ma_sv = ? AND mat_khau = ?',
      whereArgs: [maSv.trim(), matKhau],
    );
    if (res.isNotEmpty) {
      return SinhVienModel.fromMap(res.first);
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

  /// Lấy danh sách tất cả sinh viên
  Future<List<SinhVienModel>> getTatCaSinhVien() async {
    Database db = await _dbHelper.database;
    final res = await db.query('SINH_VIEN');
    return res.map((e) => SinhVienModel.fromMap(e)).toList();
  }
}

