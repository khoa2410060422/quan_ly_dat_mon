import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'quan_ly_dat_mon.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Nếu nâng cấp từ v1 lên v2 thì tạo lại bảng
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS QUAN_LY_BEP');
          await db.execute('DROP TABLE IF EXISTS CHI_TIET_DON_HANG');
          await db.execute('DROP TABLE IF EXISTS DON_HANG');
          await db.execute('DROP TABLE IF EXISTS THUC_DON_NGAY');
          await db.execute('DROP TABLE IF EXISTS QUAY_BAN_MON_AN');
          await db.execute('DROP TABLE IF EXISTS SINH_VIEN');
          await _onCreate(db, newVersion);
          return;
        }
        // Nâng cấp lên v3: Thêm cột da_xoa vào SINH_VIEN
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE SINH_VIEN ADD COLUMN da_xoa INTEGER NOT NULL DEFAULT 0');
          } catch (_) {}
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        // Đảm bảo cột da_xoa luôn tồn tại trên mọi thiết bị
        try {
          await db.execute('ALTER TABLE SINH_VIEN ADD COLUMN da_xoa INTEGER NOT NULL DEFAULT 0');
        } catch (_) {}

        // Đồng bộ/cập nhật thông tin tài khoản mẫu SV001 & SV002 theo yêu cầu mới nhất
        await _dongBoTaiKhoanMau(db);
      },
    );
  }

  /// Đồng bộ thông tin tài khoản sinh viên mẫu: SV001 (Lê Ngọc Minh Trang), SV002 (Phùng Minh Khoa)
  static Future<void> _dongBoTaiKhoanMau(Database db) async {
    try {
      // SV001: Lê Ngọc Minh Trang, 0914978732, trang@hutech.edu.vn, CNTT, 123456
      final sv1Count = await db.update(
        'SINH_VIEN',
        {
          'ho_ten': 'Lê Ngọc Minh Trang',
          'so_dien_thoai': '0914978732',
          'Email': 'trang@hutech.edu.vn',
          'khoa_lop': 'CNTT',
          'mat_khau': '123456',
        },
        where: 'ma_sv = ?',
        whereArgs: ['SV001'],
      );
      if (sv1Count == 0) {
        await db.insert('SINH_VIEN', {
          'ma_sv': 'SV001',
          'ho_ten': 'Lê Ngọc Minh Trang',
          'so_dien_thoai': '0914978732',
          'Email': 'trang@hutech.edu.vn',
          'khoa_lop': 'CNTT',
          'mat_khau': '123456',
          'da_xoa': 0,
        });
      }

      // SV002: Phùng Minh Khoa, 0910100200, khoa@hutech.edu.vn, CNTT, 654321
      final sv2Count = await db.update(
        'SINH_VIEN',
        {
          'ho_ten': 'Phùng Minh Khoa',
          'so_dien_thoai': '0910100200',
          'Email': 'khoa@hutech.edu.vn',
          'khoa_lop': 'CNTT',
          'mat_khau': '654321',
        },
        where: 'ma_sv = ?',
        whereArgs: ['SV002'],
      );
      if (sv2Count == 0) {
        await db.insert('SINH_VIEN', {
          'ma_sv': 'SV002',
          'ho_ten': 'Phùng Minh Khoa',
          'so_dien_thoai': '0910100200',
          'Email': 'khoa@hutech.edu.vn',
          'khoa_lop': 'CNTT',
          'mat_khau': '654321',
          'da_xoa': 0,
        });
      }
    } catch (_) {}
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng SINH_VIEN (theo ảnh thiết kế 2)
    await db.execute('''
      CREATE TABLE SINH_VIEN (
        ma_sv TEXT PRIMARY KEY,
        ho_ten TEXT NOT NULL,
        so_dien_thoai TEXT NOT NULL,
        Email TEXT NOT NULL,
        khoa_lop TEXT NOT NULL,
        mat_khau TEXT NOT NULL DEFAULT '123456',
        da_xoa INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Bảng QUAY_BAN_MON_AN (theo ảnh thiết kế 2 + hình ảnh, mô tả)
    await db.execute('''
      CREATE TABLE QUAY_BAN_MON_AN (
        ma_mon INTEGER PRIMARY KEY AUTOINCREMENT,
        ten_mon TEXT NOT NULL,
        gia_mon_an REAL NOT NULL,
        hinh_anh TEXT,
        mo_ta TEXT
      )
    ''');

    // 3. Bảng THUC_DON_NGAY (theo ảnh thiết kế 2)
    await db.execute('''
      CREATE TABLE THUC_DON_NGAY (
        ma_thuc_don INTEGER PRIMARY KEY AUTOINCREMENT,
        ma_mon INTEGER NOT NULL,
        ngay_ban TEXT NOT NULL,
        so_luong_cung_cap INTEGER NOT NULL,
        so_luong_da_dat INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (ma_mon) REFERENCES QUAY_BAN_MON_AN (ma_mon) ON DELETE CASCADE
      )
    ''');

    // 4. Bảng DON_HANG (theo ảnh thiết kế 2)
    await db.execute('''
      CREATE TABLE DON_HANG (
        ma_don INTEGER PRIMARY KEY AUTOINCREMENT,
        ma_sv TEXT NOT NULL,
        ngay_dat TEXT NOT NULL,
        thoi_gian_dat TEXT NOT NULL,
        tong_tien REAL NOT NULL,
        trang_thai_don TEXT NOT NULL,
        ghi_chu TEXT,
        phuong_thuc_thanh_toan TEXT DEFAULT 'Chuyển khoản QR',
        FOREIGN KEY (ma_sv) REFERENCES SINH_VIEN (ma_sv) ON DELETE CASCADE
      )
    ''');

    // 5. Bảng CHI_TIET_DON_HANG (theo ảnh thiết kế 2)
    await db.execute('''
      CREATE TABLE CHI_TIET_DON_HANG (
        ma_chi_det_don INTEGER PRIMARY KEY AUTOINCREMENT,
        ma_don INTEGER NOT NULL,
        ma_thuc_don INTEGER NOT NULL,
        so_luong INTEGER NOT NULL,
        gia_ban REAL NOT NULL,
        FOREIGN KEY (ma_don) REFERENCES DON_HANG (ma_don) ON DELETE CASCADE,
        FOREIGN KEY (ma_thuc_don) REFERENCES THUC_DON_NGAY (ma_thuc_don) ON DELETE CASCADE
      )
    ''');

    // 6. Bảng QUAN_LY_BEP (theo ảnh thiết kế 1)
    await db.execute('''
      CREATE TABLE QUAN_LY_BEP (
        ma_bep INTEGER PRIMARY KEY AUTOINCREMENT,
        ma_don INTEGER NOT NULL,
        trang_thai_bep TEXT NOT NULL,
        thoi_gian_xac_nhan TEXT,
        thoi_gian_hoan_thanh TEXT,
        ghi_chu_bep TEXT,
        FOREIGN KEY (ma_don) REFERENCES DON_HANG (ma_don) ON DELETE CASCADE
      )
    ''');

    // Nạp dữ liệu mẫu ban đầu
    await _seedInitialData(db);
  }

  /// Nạp sẵn dữ liệu mẫu cho sinh viên, món ăn và thực đơn các ngày trong tuần
  Future<void> _seedInitialData(Database db) async {
    // 1. Thêm tài khoản Sinh Viên mẫu (SV001 & SV002 theo yêu cầu)
    await db.insert('SINH_VIEN', {
      'ma_sv': 'SV001',
      'ho_ten': 'Lê Ngọc Minh Trang',
      'so_dien_thoai': '0914978732',
      'Email': 'trang@hutech.edu.vn',
      'khoa_lop': 'CNTT',
      'mat_khau': '123456',
      'da_xoa': 0,
    });

    await db.insert('SINH_VIEN', {
      'ma_sv': 'SV002',
      'ho_ten': 'Phùng Minh Khoa',
      'so_dien_thoai': '0910100200',
      'Email': 'khoa@hutech.edu.vn',
      'khoa_lop': 'CNTT',
      'mat_khau': '654321',
      'da_xoa': 0,
    });

    // 2. Thêm danh mục món ăn quầy cantin
    final List<Map<String, dynamic>> monAnList = [
      {
        'ten_mon': 'Cơm sườn nướng mật ong',
        'gia_mon_an': 35000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
        'mo_ta': 'Sườn heo nướng mật ong vàng ươm, kèm canh rau ngót và dưa góp chua ngọt.',
      },
      {
        'ten_mon': 'Cơm gà xối mỡ giòn rụm',
        'gia_mon_an': 35000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=500&q=80',
        'mo_ta': 'Đùi gà chiên da giòn rụm, cơm rang nghệ vàng ươm và xốt chấm đậm vị.',
      },
      {
        'ten_mon': 'Cơm bò lúc lắc khoai tây',
        'gia_mon_an': 40000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=500&q=80',
        'mo_ta': 'Thịt bò tươi xào ớt chuông hành tây thơm lừng, khoai tây chiên giòn.',
      },
      {
        'ten_mon': 'Bún chả nướng Hà Nội',
        'gia_mon_an': 35000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500&q=80',
        'mo_ta': 'Chả băm nướng than hoa thơm nức mũi, nước chấm đu đủ cà rốt ấm nóng.',
      },
      {
        'ten_mon': 'Phở bò tái nạm đặc biệt',
        'gia_mon_an': 40000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500&q=80',
        'mo_ta': 'Nước dùng ninh xương bò 12 tiếng ngọt thanh, thịt bò tươi mềm ngọt.',
      },
      {
        'ten_mon': 'Cơm sườn bì chả Sài Gòn',
        'gia_mon_an': 35000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=500&q=80',
        'mo_ta': 'Đầy đặn sườn nướng, chả trứng hấp, bì thăn giòn rụm và mỡ hành béo ngậy.',
      },
      {
        'ten_mon': 'Mì xào bò rau cải thanh ngọt',
        'gia_mon_an': 30000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=500&q=80',
        'mo_ta': 'Sợi mì trứng dai ngon, thịt bò ướp tỏi xào nhanh cùng cải ngọt giòn.',
      },
      {
        'ten_mon': 'Bánh mì chảo xíu mại trứng ốp',
        'gia_mon_an': 25000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=500&q=80',
        'mo_ta': 'Xíu mại sốt cà chua sánh mịn, trứng ốp la lòng đào và bánh mì nóng giòn.',
      },
      {
        'ten_mon': 'Canh bí đao nấu thịt băm',
        'gia_mon_an': 10000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=500&q=80',
        'mo_ta': 'Canh bí đao ngọt mát, bổ sung rau xanh và dinh dưỡng cho bữa trưa.',
      },
      {
        'ten_mon': 'Trà tắc sả hạt chia mát lạnh',
        'gia_mon_an': 10000.0,
        'hinh_anh': 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&q=80',
        'mo_ta': 'Trà tắc sả chua ngọt sảng khoái, giải nhiệt tuyệt vời sau giờ học căng thẳng.',
      },
    ];

    List<int> maMonIds = [];
    for (var m in monAnList) {
      int id = await db.insert('QUAY_BAN_MON_AN', m);
      maMonIds.add(id);
    }

    // 3. Tạo thực đơn sẵn trong tuần (Thứ 2 đến Chủ Nhật) với mỗi món chuẩn đúng 50 phần
    // Tính toán ngày Thứ 2 của tuần hiện tại
    DateTime today = DateTime.now();
    DateTime monday = today.subtract(Duration(days: today.weekday - 1));

    // Sinh thực đơn cho cả 7 ngày trong tuần: mỗi món có 50 phần, 0 phần đã đặt
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      DateTime targetDate = monday.add(Duration(days: dayOffset));
      String ngayStr = _formatYMD(targetDate);

      for (int i = 0; i < maMonIds.length; i++) {
        await db.insert('THUC_DON_NGAY', {
          'ma_mon': maMonIds[i],
          'ngay_ban': ngayStr,
          'so_luong_cung_cap': 50,
          'so_luong_da_dat': 0,
        });
      }
    }
  }

  static String _formatYMD(DateTime dt) {
    String nam = dt.year.toString();
    String thang = dt.month.toString().padLeft(2, '0');
    String ngay = dt.day.toString().padLeft(2, '0');
    return '$nam-$thang-$ngay';
  }

  /// Đồng bộ và làm mới thực đơn theo ngày:
  /// - Mỗi món ăn được cung cấp đúng chuẩn 50 phần (so_luong_cung_cap = 50).
  /// - Vào đầu ngày hoặc ngày mới chưa có đơn: số lượng đã đặt = 0 (đủ 50 suất).
  /// - Khi sinh viên hoàn tất đặt đơn: trừ số lượng.
  /// - Nếu đơn bị hủy: tự động cộng hoàn trả lại đủ số lượng!
  Future<void> dongBoThucDonNgay(String ngayBan) async {
    final db = await database;

    // 1. Kiểm tra xem ngày này đã có danh sách món trong THUC_DON_NGAY chưa
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM THUC_DON_NGAY WHERE ngay_ban = ?',
      [ngayBan],
    )) ?? 0;

    if (count == 0) {
      // Nếu ngày mới chưa có thực đơn: nạp toàn bộ danh mục món với chuẩn 50 phần, 0 đã đặt
      final tatCaMon = await db.query('QUAY_BAN_MON_AN');
      for (var mon in tatCaMon) {
        int maMon = (mon['ma_mon'] as num).toInt();
        await db.insert('THUC_DON_NGAY', {
          'ma_mon': maMon,
          'ngay_ban': ngayBan,
          'so_luong_cung_cap': 50,
          'so_luong_da_dat': 0,
        });
      }
    } else {
      // 2. Nếu đã có thực đơn:
      // - Đảm bảo mỗi món luôn là 50 phần (chuẩn hóa dữ liệu cũ nếu có)
      // - Tính lại số lượng đã đặt CHỈ TỪ CÁC ĐƠN ĐANG HOẠT ĐỘNG (không tính đơn 'da_huy')
      await db.rawUpdate('''
        UPDATE THUC_DON_NGAY
        SET so_luong_cung_cap = 50,
            so_luong_da_dat = (
              SELECT COALESCE(SUM(CT.so_luong), 0)
              FROM CHI_TIET_DON_HANG CT
              JOIN DON_HANG DH ON CT.ma_don = DH.ma_don
              WHERE CT.ma_thuc_don = THUC_DON_NGAY.ma_thuc_don
                AND DH.trang_thai_don != 'da_huy'
            )
        WHERE ngay_ban = ?
      ''', [ngayBan]);
    }
  }

  // ================= TRANSACTION VÀ NGHIỆP VỤ ĐẶT MÓN =================

  /// Tạo đơn hàng mới trong SQLite:
  /// - Kiểm tra tồn kho
  /// - Thêm DON_HANG
  /// - Thêm CHI_TIET_DON_HANG
  /// - TRỪ số lượng món ăn mỗi ngày (tăng so_luong_da_dat)
  /// - Thêm bản ghi QUAN_LY_BEP (trạng thái: cho_xac_nhan)
  Future<int> taoDonHangMoi({
    required Map<String, dynamic> donHang,
    required List<Map<String, dynamic>> chiTietList,
  }) async {
    final db = await database;
    return await db.transaction<int>((txn) async {
      // 1. Kiểm tra tồn kho từng món
      for (var chiTiet in chiTietList) {
        int maThucDon = (chiTiet['ma_thuc_don'] as num).toInt();
        int soLuongDat = (chiTiet['so_luong'] as num).toInt();

        final res = await txn.rawQuery('''
          SELECT TD.so_luong_cung_cap, TD.so_luong_da_dat, M.ten_mon
          FROM THUC_DON_NGAY TD
          JOIN QUAY_BAN_MON_AN M ON TD.ma_mon = M.ma_mon
          WHERE TD.ma_thuc_don = ?
        ''', [maThucDon]);

        if (res.isNotEmpty) {
          int cungCap = (res.first['so_luong_cung_cap'] as num).toInt();
          int daDat = (res.first['so_luong_da_dat'] as num).toInt();
          String tenMon = res.first['ten_mon']?.toString() ?? 'Món ăn';
          int conLai = cungCap - daDat;

          if (conLai < soLuongDat) {
            throw Exception('Món "$tenMon" chỉ còn $conLai suất, không đủ để đặt $soLuongDat suất!');
          }
        }
      }

      // 2. Chèn vào bảng DON_HANG
      int maDon = await txn.insert('DON_HANG', donHang);

      // 3. Chèn vào bảng CHI_TIET_DON_HANG và TRỪ SỐ LƯỢNG MÓN
      for (var item in chiTietList) {
        int maThucDon = (item['ma_thuc_don'] as num).toInt();
        int soLuong = (item['so_luong'] as num).toInt();

        await txn.insert('CHI_TIET_DON_HANG', {
          'ma_don': maDon,
          'ma_thuc_don': maThucDon,
          'so_luong': soLuong,
          'gia_ban': item['gia_ban'],
        });

        // Trừ số lượng món ăn trong ngày: tăng số lượng đã đặt
        await txn.rawUpdate('''
          UPDATE THUC_DON_NGAY 
          SET so_luong_da_dat = so_luong_da_dat + ?
          WHERE ma_thuc_don = ?
        ''', [soLuong, maThucDon]);
      }

      // 4. Thêm bản ghi QUAN_LY_BEP (khởi tạo: cho_xac_nhan)
      await txn.insert('QUAN_LY_BEP', {
        'ma_don': maDon,
        'trang_thai_bep': 'cho_xac_nhan',
        'ghi_chu_bep': donHang['ghi_chu'] ?? '',
      });

      return maDon;
    });
  }

  /// Bếp xác nhận nhận đơn:
  /// - Cập nhật QUAN_LY_BEP: trang_thai_bep = 'dang_che_bien', thoi_gian_xac_nhan
  /// - Cập nhật DON_HANG: trang_thai_don = 'dang_che_bien'
  Future<void> bepXacNhanDon(int maDon, {String? ghiChuBep}) async {
    final db = await database;
    String now = DateTime.now().toString();
    await db.transaction((txn) async {
      await txn.update(
        'QUAN_LY_BEP',
        {
          'trang_thai_bep': 'dang_che_bien',
          'thoi_gian_xac_nhan': now,
          if (ghiChuBep != null && ghiChuBep.isNotEmpty) 'ghi_chu_bep': ghiChuBep,
        },
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );

      await txn.update(
        'DON_HANG',
        {'trang_thai_don': 'dang_che_bien'},
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );
    });
  }

  /// Bếp bấm hủy không nhận:
  /// - SỐ LƯỢNG MÓN ĂN ĐƯỢC CỘNG TRỞ LẠI VÀO THUC_DON_NGAY
  /// - Cập nhật QUAN_LY_BEP: trang_thai_bep = 'da_huy', ghi_chu_bep = lý do
  /// - Cập nhật DON_HANG: trang_thai_don = 'da_huy'
  Future<void> bepHuyDon(int maDon, {required String lyDoHuy}) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Lấy danh sách món trong đơn hàng để hoàn trả số lượng
      final chiTietList = await txn.query(
        'CHI_TIET_DON_HANG',
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );

      for (var ct in chiTietList) {
        int maThucDon = (ct['ma_thuc_don'] as num).toInt();
        int soLuong = (ct['so_luong'] as num).toInt();

        // CỘNG TRẢ LẠI SỐ LƯỢNG MÓN
        await txn.rawUpdate('''
          UPDATE THUC_DON_NGAY 
          SET so_luong_da_dat = MAX(0, so_luong_da_dat - ?)
          WHERE ma_thuc_don = ?
        ''', [soLuong, maThucDon]);
      }

      // 2. Cập nhật QUAN_LY_BEP
      await txn.update(
        'QUAN_LY_BEP',
        {
          'trang_thai_bep': 'da_huy',
          'ghi_chu_bep': lyDoHuy,
        },
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );

      // 3. Cập nhật DON_HANG
      await txn.update(
        'DON_HANG',
        {'trang_thai_don': 'da_huy'},
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );
    });
  }

  /// Bếp nấu xong -> Báo sinh viên đến lấy:
  /// - Cập nhật QUAN_LY_BEP: trang_thai_bep = 'cho_nhan', thoi_gian_hoan_thanh
  /// - Cập nhật DON_HANG: trang_thai_don = 'cho_nhan'
  Future<void> bepHoanTatNau(int maDon, {String? ghiChuBep}) async {
    final db = await database;
    String now = DateTime.now().toString();
    await db.transaction((txn) async {
      await txn.update(
        'QUAN_LY_BEP',
        {
          'trang_thai_bep': 'cho_nhan',
          'thoi_gian_hoan_thanh': now,
          if (ghiChuBep != null && ghiChuBep.isNotEmpty) 'ghi_chu_bep': ghiChuBep,
        },
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );

      await txn.update(
        'DON_HANG',
        {'trang_thai_don': 'cho_nhan'},
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );
    });
  }

  /// Sinh viên đã đến nhận món / Bếp bấm giao hoàn tất:
  /// - Cập nhật trang_thai_bep = 'da_hoan_thanh'
  /// - Cập nhật trang_thai_don = 'da_hoan_thanh'
  Future<void> bepGiaoXongDon(int maDon) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'QUAN_LY_BEP',
        {'trang_thai_bep': 'da_hoan_thanh'},
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );

      await txn.update(
        'DON_HANG',
        {'trang_thai_don': 'da_hoan_thanh'},
        where: 'ma_don = ?',
        whereArgs: [maDon],
      );
    });
  }

  // ================= QUẢN LÝ TÀI KHOẢN SINH VIÊN =================

  /// Xóa tài khoản sinh viên (đánh dấu da_xoa = 1 để chặn đăng nhập và bảo toàn lịch sử đơn hàng)
  Future<int> xoaSinhVien(String maSv) async {
    final db = await database;
    return await db.update(
      'SINH_VIEN',
      {'da_xoa': 1},
      where: 'ma_sv = ?',
      whereArgs: [maSv.trim()],
    );
  }

  /// Khôi phục tài khoản sinh viên đã xóa (nếu cần thiết)
  Future<int> khoiPhucSinhVien(String maSv) async {
    final db = await database;
    return await db.update(
      'SINH_VIEN',
      {'da_xoa': 0},
      where: 'ma_sv = ?',
      whereArgs: [maSv.trim()],
    );
  }
}
