import 'package:flutter/material.dart';
import '../../models/don_hang_model.dart';
import '../../models/chi_tiet_don_hang_model.dart';
import '../../repositories/bep_repository.dart';
import '../../core/utils/format_utils.dart';
import '../auth/man_hinh_dang_nhap.dart';
import 'man_hinh_danh_sach_sinh_vien.dart';

class ManHinhQuanLyBep extends StatefulWidget {
  const ManHinhQuanLyBep({super.key});

  @override
  State<ManHinhQuanLyBep> createState() => _ManHinhQuanLyBepState();
}

class _ManHinhQuanLyBepState extends State<ManHinhQuanLyBep> with SingleTickerProviderStateMixin {
  final _bepRepo = BepRepository();
  late TabController _tabController;

  List<DonHangModel> _allOrders = [];
  Map<int, List<ChiTietDonHangModel>> _orderItemsMap = {};
  Map<String, int> _counts = {};
  Map<String, dynamic> _thongKeTongQuan = {
    'tong_hoan_thanh': 0,
    'tong_huy': 0,
    'tong_doanh_thu': 0.0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orders = await _bepRepo.getDanhSachDonBep();
    final counts = await _bepRepo.thongKeSoLuongDon();
    final thongKe = await _bepRepo.thongKeTongQuanBep();

    // Tải trước chi tiết món cho từng đơn hàng
    Map<int, List<ChiTietDonHangModel>> itemsMap = {};
    for (var ord in orders) {
      if (ord.maDon != null) {
        itemsMap[ord.maDon!] = await _bepRepo.getChiTietDonChoBep(ord.maDon!);
      }
    }

    if (mounted) {
      setState(() {
        _allOrders = orders;
        _orderItemsMap = itemsMap;
        _counts = counts;
        _thongKeTongQuan = thongKe;
        _isLoading = false;
      });
    }
  }

  List<DonHangModel> _filterOrders(int tabIndex) {
    switch (tabIndex) {
      case 0: // Chờ xác nhận
        return _allOrders.where((d) => (d.trangThaiBep ?? d.trangThaiDon) == 'cho_xac_nhan').toList();
      case 1: // Đang chế biến
        return _allOrders
            .where((d) =>
                (d.trangThaiBep ?? d.trangThaiDon) == 'dang_che_bien' ||
                (d.trangThaiBep ?? d.trangThaiDon) == 'da_nhan')
            .toList();
      case 2: // Chờ nhận món
        return _allOrders.where((d) => (d.trangThaiBep ?? d.trangThaiDon) == 'cho_nhan').toList();
      case 3: // Lịch sử (Hoàn tất / Đã hủy)
        return _allOrders
            .where((d) =>
                (d.trangThaiBep ?? d.trangThaiDon) == 'da_hoan_thanh' ||
                (d.trangThaiBep ?? d.trangThaiDon) == 'da_huy')
            .toList();
      default:
        return _allOrders;
    }
  }

  // 1. Bếp xác nhận nhận đơn
  Future<void> _xacNhanNhanDon(int maDon) async {
    try {
      await _bepRepo.xacNhanNhanDon(maDon, ghiChu: 'Bếp đã nhận đơn và bắt đầu chế biến');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã nhận đơn #$maDon! Bắt đầu chế biến.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 2. Bếp hủy đơn -> TỰ ĐỘNG CỘNG HOÀN TRẢ SỐ LƯỢNG MÓN
  Future<void> _xacNhanHuyDon(int maDon) async {
    final lyDoController = TextEditingController(text: 'Hết nguyên liệu chế biến trong ngày');

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hủy Đơn Hàng & Hoàn Suất', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động này sẽ: \n• Báo hủy đơn cho sinh viên\n• Tự động CỘNG HOÀN TRẢ số lượng suất ăn vào thực đơn ngày!',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: lyDoController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy đơn',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bỏ qua'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác Nhận Hủy Đơn'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bepRepo.huyDonHang(
          maDon,
          lyDoHuy: lyDoController.text.trim().isEmpty
              ? 'Hết suất ăn hoặc trục trặc cantin'
              : lyDoController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đã hủy đơn #$maDon và CỘNG HOÀN TRẢ lại số lượng món ăn!'),
            backgroundColor: Colors.deepOrange,
          ),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy đơn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 3. Bếp nấu xong -> Báo sinh viên đến lấy
  Future<void> _hoanTatNau(int maDon) async {
    try {
      await _bepRepo.hoanTatNau(maDon, ghiChu: 'Món ăn đã nấu xong, sinh viên có thể đến lấy');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 Đã nấu xong đơn #$maDon! Hệ thống đã thông báo cho sinh viên đến lấy.'),
          backgroundColor: Colors.teal,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 4. Hoàn tất giao món
  Future<void> _giaoMonHoanTat(int maDon) async {
    try {
      await _bepRepo.giaoMonHoanTat(maDon);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Hoàn tất giao đơn #$maDon cho sinh viên! Đã lưu trữ.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _dangXuat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng Xuất Admin'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi giao diện Bếp / Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const ManHinhDangNhap()),
                (route) => false,
              );
            },
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );
  }

  void _moDanhSachSinhVien() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManHinhDanhSachSinhVien()),
    );
  }

  Widget _buildThongKeDoanhThuCard() {
    final double tongDoanhThu = (_thongKeTongQuan['tong_doanh_thu'] as num?)?.toDouble() ?? 0.0;
    final int tongHoanThanh = (_thongKeTongQuan['tong_hoan_thanh'] as num?)?.toInt() ?? 0;
    final int tongHuy = (_thongKeTongQuan['tong_huy'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_rounded, size: 20, color: Colors.deepPurple),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TỔNG QUAN DOANH THU & KINH DOANH',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              InkWell(
                onTap: _moDanhSachSinhVien,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.people_alt_rounded, size: 14, color: Colors.deepPurple),
                      SizedBox(width: 4),
                      Text(
                        'DS Sinh Viên',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 1. Tổng doanh thu (Các đơn đã hoàn tất)
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.monetization_on_rounded, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text('Tổng Doanh Thu', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          FormatUtils.dinhDangTien(tongDoanhThu),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Tổng đơn đã hoàn tất
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.check_circle_rounded, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Text('Đã Hoàn Tất', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$tongHoanThanh đơn',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Tổng đơn đã hủy
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.cancel_rounded, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('Đã Hủy', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$tongHuy đơn',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int countChoXacNhan = _counts['cho_xac_nhan'] ?? 0;
    int countDangNau = (_counts['dang_che_bien'] ?? 0) + (_counts['da_nhan'] ?? 0);
    int countChoLay = _counts['cho_nhan'] ?? 0;
    int countLichSu = (_counts['da_hoan_thanh'] ?? 0) + (_counts['da_huy'] ?? 0);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin - Quản Lý Bếp Cantin'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Danh sách sinh viên đã đăng ký',
            icon: const Icon(Icons.people_alt_rounded),
            onPressed: _moDanhSachSinhVien,
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Đăng xuất Admin',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _dangXuat,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Chờ xác nhận ($countChoXacNhan)'),
            Tab(text: 'Đang nấu ($countDangNau)'),
            Tab(text: 'Chờ SV lấy ($countChoLay)'),
            Tab(text: 'Lịch sử ($countLichSu)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildThongKeDoanhThuCard(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTabContent(0, 'Không có đơn nào đang chờ xác nhận.'),
                      _buildTabContent(1, 'Hiện tại không có đơn nào đang nấu.'),
                      _buildTabContent(2, 'Không có đơn nào đang chờ sinh viên đến lấy.'),
                      _buildTabContent(3, 'Chưa có lịch sử đơn hàng.'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabContent(int tabIndex, String emptyMessage) {
    final list = _filterOrders(tabIndex);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.soup_kitchen_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final don = list[index];
          final items = _orderItemsMap[don.maDon] ?? [];
          return _buildOrderCard(don, items);
        },
      ),
    );
  }

  Widget _buildOrderCard(DonHangModel don, List<ChiTietDonHangModel> items) {
    String trangThai = don.trangThaiBep ?? don.trangThaiDon;
    Color color = FormatUtils.layMauTrangThai(trangThai);
    String tenTrangThai = FormatUtils.layTenTrangThai(trangThai);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Đơn hàng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ĐƠN SỐ #${don.maDon}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                    ),
                    Text(
                      'SV: ${don.hoTenSv ?? don.maSv} (${don.maSv})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    tenTrangThai,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: color,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Thông tin thời gian & ghi chú
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ngày ăn: ${don.ngayDat}', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    Text(
                      FormatUtils.dinhDangTien(don.tongTien),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ],
                ),
                Text(
                  'Đặt lúc: ${FormatUtils.dinhDangNgayGio(don.thoiGianDat)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (don.ghiChu != null && don.ghiChu!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.note_alt, size: 16, color: Colors.brown),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Ghi chú của SV: ${don.ghiChu}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (don.thoiGianXacNhan != null) ...[
                  const SizedBox(height: 4),
                  Text('• Bếp nhận lúc: ${FormatUtils.dinhDangNgayGio(don.thoiGianXacNhan)}', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ],
                if (don.thoiGianHoanThanh != null) ...[
                  const SizedBox(height: 2),
                  Text('• Nấu xong lúc: ${FormatUtils.dinhDangNgayGio(don.thoiGianHoanThanh)}', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                ],
                if (don.ghiChuBep != null && don.ghiChuBep!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('• Ghi chú bếp: ${don.ghiChuBep}', style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontStyle: FontStyle.italic)),
                ],

                const Divider(height: 20),

                // Danh sách món cần nấu
                const Text(
                  'Món ăn cần chuẩn bị:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                ...items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.deepPurple.shade200),
                          ),
                          child: Text(
                            'x ${it.soLuong}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            it.tenMon ?? 'Món ăn',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          FormatUtils.dinhDangTien(it.thanhTien),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Nút Thao tác của Bếp theo yêu cầu đề bài
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: _buildActionButtons(trangThai, don.maDon!),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String trangThai, int maDon) {
    if (trangThai == 'cho_xac_nhan') {
      return Row(
        children: [
          // Nút Hủy đơn (Cộng hoàn trả số lượng món)
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Hủy Đơn (Hoàn Suất)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _xacNhanHuyDon(maDon),
            ),
          ),
          const SizedBox(width: 10),

          // Nút Xác nhận nhận đơn
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Nhận Đơn (Nấu)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => _xacNhanNhanDon(maDon),
            ),
          ),
        ],
      );
    } else if (trangThai == 'dang_che_bien' || trangThai == 'da_nhan') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.soup_kitchen_rounded, size: 20),
              label: const Text(
                '🍳 ĐÃ NẤU XONG - BÁO SINH VIÊN ĐẾN LẤY',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _hoanTatNau(maDon),
            ),
          ),
        ],
      );
    } else if (trangThai == 'cho_nhan') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 20),
              label: const Text(
                '🎉 ĐÃ GIAO CHO SINH VIÊN (HOÀN TẤT)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () => _giaoMonHoanTat(maDon),
            ),
          ),
        ],
      );
    } else if (trangThai == 'da_huy') {
      return const Center(
        child: Text(
          'Đơn này đã bị hủy & số lượng đã được cộng hoàn trả lại.',
          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Đơn hàng đã hoàn tất thành công và lưu trữ vĩnh viễn trong CSDL.',
          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }
  }
}

