import 'package:flutter/material.dart';
import '../../models/sinh_vien_model.dart';
import '../../models/thuc_don_ngay_model.dart';
import '../../repositories/thuc_don_repository.dart';
import '../../repositories/sinh_vien_repository.dart';
import '../../core/utils/format_utils.dart';
import '../gio_hang/man_hinh_gio_hang.dart';
import '../don_hang/man_hinh_danh_sach_don_hang.dart';
import '../tai_khoan/man_hinh_thong_tin_sv.dart';
import '../auth/man_hinh_dang_nhap.dart';

class ManHinhThucDon extends StatefulWidget {
  final SinhVienModel? sinhVien;
  final String maSv;

  const ManHinhThucDon({
    super.key,
    this.sinhVien,
    this.maSv = 'SV001',
  });

  @override
  State<ManHinhThucDon> createState() => _ManHinhThucDonState();
}

class _ManHinhThucDonState extends State<ManHinhThucDon> {
  final _thucDonRepo = ThucDonRepository();
  final _sinhVienRepo = SinhVienRepository();

  SinhVienModel? _currentSv;
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  // Giỏ hàng lưu: Map<maThucDon, {thucDon: ThucDonNgayModel, soLuong: int}>
  final Map<int, Map<String, dynamic>> _gioHang = {};

  bool _isLoading = true;
  List<ThucDonNgayModel> _danhSachMon = [];

  @override
  void initState() {
    super.initState();
    _currentSv = widget.sinhVien;
    _initDays();
    _loadSinhVienIfNeeded();
  }

  void _initDays() {
    DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    // Tính thứ 2 của tuần hiện tại
    DateTime monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    // Danh sách 7 ngày từ Thứ 2 đến Chủ Nhật trong tuần
    _weekDays = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  Future<void> _loadSinhVienIfNeeded() async {
    if (_currentSv == null) {
      _currentSv = await _sinhVienRepo.getSinhVien(widget.maSv);
    }
    _taiThucDon();
  }

  Future<void> _taiThucDon() async {
    setState(() => _isLoading = true);
    String dateStr = FormatUtils.dinhDangNgayYMD(_selectedDate);
    final list = await _thucDonRepo.getThucDonTheoNgay(dateStr);

    if (mounted) {
      setState(() {
        _danhSachMon = list;
        _isLoading = false;
      });
    }
  }

  /// Kích hoạt cho phép đặt món: cho phép sinh viên chọn món cho các ngày trong tuần
  bool _choPhepDatMon(DateTime ngayChon) {
    return true;
  }

  Future<void> _moManHinhGioHang() async {
    String currentMaSv = _currentSv?.maSv ?? widget.maSv;
    if (_gioHang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng đang trống! Vui lòng chọn món trước.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final daDat = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ManHinhGioHang(
          maSv: currentMaSv,
          ngayDat: FormatUtils.dinhDangNgayYMD(_selectedDate),
          gioHang: _gioHang.values.toList(),
        ),
      ),
    );

    if (daDat == true) {
      setState(() => _gioHang.clear());
      _taiThucDon();
    }
  }

  void _themVaoGio(ThucDonNgayModel mon) {
    if (mon.daHetMon) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Món này đã hết suất trong ngày!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int id = mon.maThucDon!;
    int soLuongHienTai = _gioHang[id]?['so_luong'] ?? 0;

    if (soLuongHienTai >= mon.soLuongConLai) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ còn ${mon.soLuongConLai} suất cho món ${mon.tenMon}!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _gioHang[id] = {
        'thuc_don': mon,
        'so_luong': soLuongHienTai + 1,
      };
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm "${mon.tenMon}" vào giỏ hàng!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VÀO GIỎ HÀNG',
          textColor: Colors.yellowAccent,
          onPressed: _moManHinhGioHang,
        ),
      ),
    );
  }

  void _giamSoLuong(ThucDonNgayModel mon) {
    int id = mon.maThucDon!;
    if (!_gioHang.containsKey(id)) return;

    setState(() {
      int sl = _gioHang[id]!['so_luong'] as int;
      if (sl > 1) {
        _gioHang[id]!['so_luong'] = sl - 1;
      } else {
        _gioHang.remove(id);
      }
    });
  }

  double get _tongTien {
    double sum = 0;
    _gioHang.forEach((k, v) {
      final mon = v['thuc_don'] as ThucDonNgayModel;
      final sl = v['so_luong'] as int;
      sum += mon.giaMonAn * sl;
    });
    return sum;
  }

  int get _tongSoLuong {
    int sum = 0;
    _gioHang.forEach((k, v) {
      sum += v['so_luong'] as int;
    });
    return sum;
  }

  Future<void> _xacNhanThoat() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Thoát Đặt Món', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn thoát khỏi màn hình đặt món và quay lại trang đăng nhập?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại tiếp tục đặt'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ManHinhDangNhap()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentMaSv = _currentSv?.maSv ?? widget.maSv;
    bool duocPhepDat = _choPhepDatMon(_selectedDate);

    return WillPopScope(
      onWillPop: () async {
        await _xacNhanThoat();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          leading: IconButton(
            tooltip: 'Thoát ra màn hình đăng nhập',
            icon: const Icon(Icons.arrow_back),
            onPressed: _xacNhanThoat,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thực Đơn Cantin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (_currentSv != null)
                Text(
                  '${_currentSv!.hoTen} (${_currentSv!.maSv})',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
          actions: [
            // Nút Giỏ Hàng
            IconButton(
              tooltip: 'Giỏ hàng',
              icon: Badge(
                isLabelVisible: _tongSoLuong > 0,
                label: Text('$_tongSoLuong'),
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              onPressed: _moManHinhGioHang,
            ),
            // Nút Lịch sử đơn hàng
            IconButton(
              tooltip: 'Đơn hàng của tôi',
              icon: const Icon(Icons.receipt_long_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManHinhDanhSachDonHang(maSv: currentMaSv),
                  ),
                );
              },
            ),
            // Nút Thông tin tài khoản
            IconButton(
              tooltip: 'Tài khoản',
              icon: const Icon(Icons.account_circle_rounded),
              onPressed: () {
                if (_currentSv != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManHinhThongTinSv(sinhVien: _currentSv!),
                    ),
                  );
                }
              },
            ),
            // Nút Thoát / Đăng xuất
            IconButton(
              tooltip: 'Thoát / Đăng xuất',
              icon: const Icon(Icons.logout_rounded),
              onPressed: _xacNhanThoat,
            ),
          ],
        ),
      body: Column(
        children: [
          // Thanh chọn ngày Thứ 2 -> Chủ Nhật
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _weekDays.map((date) {
                  bool isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;

                  DateTime now = DateTime.now();
                  bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                  bool isTomorrow = date.year == now.year &&
                      date.month == now.month &&
                      date.day == (now.day + 1);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        if (!isSelected) {
                          setState(() {
                            _selectedDate = date;
                            _gioHang.clear(); // đổi ngày thì làm mới giỏ
                          });
                          _taiThucDon();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepOrange : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.deepOrange
                                : (isToday ? Colors.deepOrange.shade300 : Colors.grey.shade300),
                            width: isSelected || isToday ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.deepOrange.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Text(
                              FormatUtils.layThuTrongTuan(date),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                            if (isToday)
                              Text(
                                'Hôm nay',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.yellowAccent : Colors.deepOrange,
                                ),
                              )
                            else if (isTomorrow)
                              Text(
                                'Ngày mai',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white70 : Colors.blue,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Banner thông báo quy định đặt trước
          if (!duocPhepDat)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.brown, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thực đơn tham khảo. Cantin chỉ nhận đặt trước 1 ngày (Hôm nay hoặc Ngày mai)!',
                      style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
                    ),
                  ),
                ],
              ),
            ),

          // Danh sách món ăn
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _danhSachMon.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_meals_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              'Không có thực đơn cho ngày ${FormatUtils.dinhDangNgayYMD(_selectedDate)}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _taiThucDon,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 90, left: 12, right: 12),
                          itemCount: _danhSachMon.length,
                          itemBuilder: (context, index) {
                            final mon = _danhSachMon[index];
                            final int slTrongGio = _gioHang[mon.maThucDon]?['so_luong'] ?? 0;
                            return _buildMonAnCard(mon, slTrongGio, duocPhepDat);
                          },
                        ),
                      ),
          ),
        ],
      ),

      // Bottom Bar Giỏ Hàng
      bottomNavigationBar: _gioHang.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Badge(
                      label: Text('$_tongSoLuong'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Colors.deepOrange),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tổng thanh toán:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            FormatUtils.dinhDangTien(_tongTien),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Xem Giỏ Hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _moManHinhGioHang,
                    ),
                  ],
                ),
              ),
            )
          : null,
      ),
    );
  }

  Widget _buildMonAnCard(ThucDonNgayModel mon, int slTrongGio, bool duocPhepDat) {
    bool hetMon = mon.daHetMon;
    double tiLeConLai = mon.soLuongCungCap > 0 ? (mon.soLuongConLai / mon.soLuongCungCap) : 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh món ăn
              Container(
                width: 110,
                height: 110,
                color: Colors.grey.shade200,
                child: mon.hinhAnh != null && mon.hinhAnh!.isNotEmpty
                    ? Image.network(
                        mon.hinhAnh!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.fastfood_rounded,
                          size: 40,
                          color: Colors.orange,
                        ),
                      )
                    : const Icon(Icons.fastfood_rounded, size: 40, color: Colors.orange),
              ),

              // Thông tin món
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mon.tenMon,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (mon.moTa != null && mon.moTa!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          mon.moTa!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        FormatUtils.dinhDangTien(mon.giaMonAn),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Phần trạng thái số lượng & nút thêm vào giỏ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Chỉ báo số lượng còn lại
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hetMon ? Icons.cancel : Icons.inventory_2_outlined,
                          size: 15,
                          color: hetMon ? Colors.red : (mon.soLuongConLai <= 5 ? Colors.orange : Colors.green),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hetMon
                              ? 'Đã hết suất hôm nay'
                              : 'Còn ${mon.soLuongConLai} / ${mon.soLuongCungCap} suất',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hetMon
                                ? Colors.red
                                : (mon.soLuongConLai <= 5 ? Colors.orange.shade800 : Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 130,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: tiLeConLai,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            hetMon
                                ? Colors.red
                                : (mon.soLuongConLai <= 5 ? Colors.orange : Colors.green),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Nút chọn món
                if (hetMon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Hết Món',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  )
                else if (slTrongGio > 0)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.deepOrange),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18, color: Colors.deepOrange),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () => _giamSoLuong(mon),
                        ),
                        Text(
                          '$slTrongGio',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18, color: Colors.deepOrange),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () => _themVaoGio(mon),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    label: const Text('Chọn Món', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: () => _themVaoGio(mon),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
