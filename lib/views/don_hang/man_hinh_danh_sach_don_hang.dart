import 'package:flutter/material.dart';
import '../../models/don_hang_model.dart';
import '../../repositories/don_hang_repository.dart';
import '../../core/utils/format_utils.dart';
import 'man_hinh_chi_tiet_don_hang.dart';
import '../thuc_don/man_hinh_thuc_don.dart';

class ManHinhDanhSachDonHang extends StatefulWidget {
  final String maSv;
  const ManHinhDanhSachDonHang({super.key, required this.maSv});

  @override
  State<ManHinhDanhSachDonHang> createState() => _ManHinhDanhSachDonHangState();
}

class _ManHinhDanhSachDonHangState extends State<ManHinhDanhSachDonHang> with SingleTickerProviderStateMixin {
  final _donHangRepo = DonHangRepository();
  late TabController _tabController;
  List<DonHangModel> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orders = await _donHangRepo.getDanhSachDonHang(widget.maSv);
    if (mounted) {
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    }
  }

  List<DonHangModel> _filterOrders(int tabIndex) {
    switch (tabIndex) {
      case 1: // Chờ xác nhận
        return _allOrders.where((d) => (d.trangThaiBep ?? d.trangThaiDon) == 'cho_xac_nhan').toList();
      case 2: // Đang nấu
        return _allOrders
            .where((d) => (d.trangThaiBep ?? d.trangThaiDon) == 'dang_che_bien' || (d.trangThaiBep ?? d.trangThaiDon) == 'da_nhan')
            .toList();
      case 3: // Chờ lấy món
        return _allOrders.where((d) => (d.trangThaiBep ?? d.trangThaiDon) == 'cho_nhan').toList();
      case 4: // Hoàn tất & Đã hủy
        return _allOrders
            .where((d) =>
                (d.trangThaiBep ?? d.trangThaiDon) == 'da_hoan_thanh' ||
                (d.trangThaiBep ?? d.trangThaiDon) == 'da_huy')
            .toList();
      default: // Tất cả
        return _allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Lịch Sử Đặt Món Sinh Viên'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            tooltip: 'Đặt thêm món',
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => ManHinhThucDon(maSv: widget.maSv)),
                (route) => route.isFirst,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Đang nấu'),
            Tab(text: 'Mời lấy món'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(5, (index) {
                final filtered = _filterOrders(index);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text(
                          'Chưa có đơn hàng nào trong mục này.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final don = filtered[idx];
                      return _buildDonHangCard(don);
                    },
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildDonHangCard(DonHangModel don) {
    String trangThai = don.trangThaiBep ?? don.trangThaiDon;
    Color color = FormatUtils.layMauTrangThai(trangThai);
    String tenTrangThai = FormatUtils.layTenTrangThai(trangThai);
    IconData iconData = FormatUtils.layIconTrangThai(trangThai);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManHinhChiTietDonHang(maDon: don.maDon!, maSv: widget.maSv),
            ),
          );
          _loadData();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Mã đơn + Chip trạng thái
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: color.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_rounded, size: 18, color: color),
                      const SizedBox(width: 6),
                      Text(
                        'Đơn hàng #${don.maDon}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconData, size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          tenTrangThai,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nội dung chi tiết
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ngày nhận: ${don.ngayDat}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      Text(
                        FormatUtils.dinhDangTien(don.tongTien),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Thời gian đặt: ${FormatUtils.dinhDangNgayGio(don.thoiGianDat)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (don.ghiChu != null && don.ghiChu!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ghi chú của bạn: ${don.ghiChu}',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade800),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Banner thông báo tiến trình cho Sinh viên
                  _buildStatusNotificationBanner(trangThai, don),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusNotificationBanner(String trangThai, DonHangModel don) {
    if (trangThai == 'cho_xac_nhan') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.hourglass_bottom_rounded, size: 16, color: Colors.orange),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Vui lòng chuyển khoản QR và đợi quầy Bếp bấm nhận đơn.',
                style: TextStyle(fontSize: 11, color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      );
    } else if (trangThai == 'dang_che_bien' || trangThai == 'da_nhan') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.soup_kitchen_rounded, size: 16, color: Colors.blue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Bếp đã nhận đơn${don.thoiGianXacNhan != null ? ' lúc ' + FormatUtils.dinhDangNgayGio(don.thoiGianXacNhan) : ''} và đang chế biến.',
                style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      );
    } else if (trangThai == 'cho_nhan') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, size: 18, color: Colors.teal),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '🔔 Món ăn đã nấu xong! Mời bạn đến quầy cantin nhận món ngay.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
              ),
            ),
          ],
        ),
      );
    } else if (trangThai == 'da_huy') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_rounded, size: 16, color: Colors.red),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Món ăn không đặt được, đơn hàng đã bị hủy. ${don.ghiChuBep != null && don.ghiChuBep!.isNotEmpty ? '(Lý do: ' + don.ghiChuBep! + ')' : ''} Số lượng món đã được hoàn trả lại cantin.',
                style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Đơn hàng đã hoàn thành. Chúc bạn có bữa trưa ngon miệng!',
                style: TextStyle(fontSize: 11, color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }
  }
}
