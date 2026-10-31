import 'package:flutter/material.dart';

class FormatUtils {
  /// Định dạng tiền tệ VNĐ: ví dụ 35000 -> 35.000 đ
  static String dinhDangTien(num? soTien) {
    if (soTien == null) return '0 đ';
    String str = soTien.toInt().toString();
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String ketQua = str.replaceAllMapped(reg, (Match match) => '${match[1]}.');
    return '$ketQua đ';
  }

  /// Định dạng ngày giờ hiển thị thân thiện
  static String dinhDangNgayGio(String? thoiGianStr) {
    if (thoiGianStr == null || thoiGianStr.isEmpty) return '--';
    try {
      DateTime dt = DateTime.parse(thoiGianStr);
      String gio = dt.hour.toString().padLeft(2, '0');
      String phut = dt.minute.toString().padLeft(2, '0');
      String ngay = dt.day.toString().padLeft(2, '0');
      String thang = dt.month.toString().padLeft(2, '0');
      String nam = dt.year.toString();
      return '$gio:$phut - $ngay/$thang/$nam';
    } catch (_) {
      return thoiGianStr;
    }
  }

  /// Định dạng ngày theo định dạng YYYY-MM-DD
  static String dinhDangNgayYMD(DateTime dt) {
    String nam = dt.year.toString();
    String thang = dt.month.toString().padLeft(2, '0');
    String ngay = dt.day.toString().padLeft(2, '0');
    return '$nam-$thang-$ngay';
  }

  /// Lấy tên thứ trong tuần (Thứ Hai, Thứ Ba, ...)
  static String layThuTrongTuan(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  /// Màu sắc đại diện cho trạng thái đơn hàng / bếp
  static Color layMauTrangThai(String? trangThai) {
    switch (trangThai) {
      case 'cho_xac_nhan':
        return Colors.orange;
      case 'da_nhan':
      case 'dang_che_bien':
        return Colors.blue;
      case 'cho_nhan':
        return Colors.teal;
      case 'da_hoan_thanh':
        return Colors.green;
      case 'da_huy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Tên tiếng Việt hiển thị cho trạng thái đơn hàng
  static String layTenTrangThai(String? trangThai) {
    switch (trangThai) {
      case 'cho_xac_nhan':
        return 'Chờ Bếp xác nhận';
      case 'da_nhan':
      case 'dang_che_bien':
        return 'Bếp đang nấu';
      case 'cho_nhan':
        return 'Món đã sẵn sàng - Mời lấy';
      case 'da_hoan_thanh':
        return 'Đã hoàn tất';
      case 'da_huy':
        return 'Đơn đã bị hủy';
      default:
        return 'Không xác định';
    }
  }

  /// Icon cho trạng thái
  static IconData layIconTrangThai(String? trangThai) {
    switch (trangThai) {
      case 'cho_xac_nhan':
        return Icons.hourglass_top_rounded;
      case 'da_nhan':
      case 'dang_che_bien':
        return Icons.soup_kitchen_rounded;
      case 'cho_nhan':
        return Icons.notifications_active_rounded;
      case 'da_hoan_thanh':
        return Icons.check_circle_rounded;
      case 'da_huy':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline;
    }
  }
}

