import 'package:flutter/material.dart';
import '../../models/don_hang_model.dart';
import '../../models/chi_tiet_don_hang_model.dart';
import '../../repositories/don_hang_repository.dart';
import '../../core/utils/format_utils.dart';
import '../../core/widgets/qr_view_widget.dart';

class ManHinhChiTietDonHang extends StatefulWidget {
  final int maDon;
  final String maSv;

  const ManHinhChiTietDonHang({
    super.key,
    required this.maDon,
    required this.maSv,
  });

  @override
  State<ManHinhChiTietDonHang> createState() => _ManHinhChiTietDonHangState();
}

class _ManHinhChiTietDonHangState extends State<ManHinhChiTietDonHang> {
  final _donHangRepo = DonHangRepository();
  DonHangModel? _donHang;
  List<ChiTietDonHangModel> _chiTietList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChiTiet();
  }

  Future<void> _loadChiTiet() async {
    setState(() => _isLoading = true);
    final don = await _donHangRepo.getDonHangById(widget.maDon);
    final chiTiets = await _donHangRepo.getChiTietDonHang(widget.maDon);

    if (mounted) {
      setState(() {
        _donHang = don;
        _chiTietList = chiTiets;
        _isLoading = false;
      });
    }
  }

  Future<void> _xacNhanHuyDonBoiSinhVien(int maDon) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hủy Đơn Hàng', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn hủy đơn hàng này?\nSố lượng các suất ăn đã đặt sẽ được cộng hoàn trả lại ngay lập tức cho thực đơn cantin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không hủy'),
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
        await _donHangRepo.huyDonHang(maDon, lyDoHuy: 'Sinh viên chủ động hủy đơn');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Đã hủy đơn hàng và CỘNG HOÀN TRẢ lại số lượng món ăn!'),
            backgroundColor: Colors.deepOrange,
          ),
        );
        _loadChiTiet();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy đơn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Chi Tiết Đơn #${widget.maDon}'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_donHang == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Đơn Hàng')),
        body: const Center(child: Text('Không tìm thấy thông tin đơn hàng!')),
      );
    }

    final don = _donHang!;
    String trangThai = don.trangThaiBep ?? don.trangThaiDon;
    Color statusColor = FormatUtils.layMauTrangThai(trangThai);
    String tenTrangThai = FormatUtils.layTenTrangThai(trangThai);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Đơn Hàng #${don.maDon}'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadChiTiet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChiTiet,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thẻ Tiến Trình / Trạng Thái Đơn Hàng
              _buildProgressCard(trangThai, don, statusColor, tenTrangThai),
              const SizedBox(height: 16),

              // Thẻ Thông tin sinh viên & Đơn hàng
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông Tin Đơn Hàng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      _buildRow('Mã sinh viên:', don.maSv),
                      if (don.hoTenSv != null) _buildRow('Họ tên sinh viên:', don.hoTenSv!),
                      if (don.soDienThoaiSv != null) _buildRow('Số điện thoại:', don.soDienThoaiSv!),
                      _buildRow('Ngày ăn:', don.ngayDat),
                      _buildRow('Thời gian đặt:', FormatUtils.dinhDangNgayGio(don.thoiGianDat)),
                      if (don.ghiChu != null && don.ghiChu!.isNotEmpty)
                        _buildRow('Ghi chú của bạn:', don.ghiChu!, isItalic: true),
                      if (don.ghiChuBep != null && don.ghiChuBep!.isNotEmpty)
                        _buildRow('Ghi chú từ Bếp:', don.ghiChuBep!, valueColor: Colors.deepPurple, isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Danh sách các món ăn đã đặt
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Món Ăn Đã Đặt',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ..._chiTietList.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: Colors.grey.shade200,
                                  child: item.hinhAnh != null
                                      ? Image.network(item.hinhAnh!, fit: BoxFit.cover)
                                      : const Icon(Icons.fastfood, color: Colors.orange),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.tenMon ?? 'Món ăn',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${FormatUtils.dinhDangTien(item.giaBan)}  x  ${item.soLuong}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                FormatUtils.dinhDangTien(item.thanhTien),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TỔNG TIỀN THANH TOÁN:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            FormatUtils.dinhDangTien(don.tongTien),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nếu đơn đang chờ xác nhận -> Hiển thị lại mã QR thanh toán để tiện kiểm tra
              if (trangThai == 'cho_xac_nhan') ...[
                QrViewWidget(
                  maDon: don.maDon!,
                  maSv: don.maSv,
                  tongTien: don.tongTien,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  label: const Text(
                    'Hủy Đơn Hàng Này (Cộng Hoàn Suất Ăn)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => _xacNhanHuyDonBoiSinhVien(don.maDon!),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(String trangThai, DonHangModel don, Color statusColor, String tenTrangThai) {
    if (trangThai == 'da_huy') {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade300, width: 1.5),
        ),
        child: Column(
          children: [
            const Icon(Icons.cancel_rounded, size: 50, color: Colors.red),
            const SizedBox(height: 8),
            const Text(
              'MÓN ĂN KHÔNG ĐẶT ĐƯỢC - ĐÃ BỊ HỦY',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 6),
            Text(
              'Bếp cantin không thể tiếp nhận đơn này. Số lượng món ăn đã được cộng hoàn trả lại trên hệ thống.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.red.shade800),
            ),
            if (don.ghiChuBep != null && don.ghiChuBep!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Text('Lý do hủy từ bếp: ${don.ghiChuBep}', style: const TextStyle(fontSize: 13, color: Colors.red)),
              ),
            ]
          ],
        ),
      );
    }

    int currentStep = 0;
    if (trangThai == 'dang_che_bien' || trangThai == 'da_nhan') currentStep = 1;
    if (trangThai == 'cho_nhan') currentStep = 2;
    if (trangThai == 'da_hoan_thanh') currentStep = 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiến Trình Đơn Hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
                child: Text(tenTrangThai, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Timeline
          _buildStepRow(
            stepNumber: 1,
            title: 'Chờ xác nhận & Thanh toán QR',
            subtitle: 'Đơn đã tạo, chờ cantin xác nhận',
            isActive: currentStep >= 0,
            isCompleted: currentStep > 0,
          ),
          _buildStepConnector(isCompleted: currentStep > 0),
          _buildStepRow(
            stepNumber: 2,
            title: 'Bếp đã nhận & Đang chế biến',
            subtitle: don.thoiGianXacNhan != null
                ? 'Bếp bắt đầu nấu lúc: ${FormatUtils.dinhDangNgayGio(don.thoiGianXacNhan)}'
                : 'Đầu bếp chuẩn bị nguyên liệu và nấu món',
            isActive: currentStep >= 1,
            isCompleted: currentStep > 1,
          ),
          _buildStepConnector(isCompleted: currentStep > 1),
          _buildStepRow(
            stepNumber: 3,
            title: 'Món đã sẵn sàng - Mời đến lấy!',
            subtitle: don.thoiGianHoanThanh != null
                ? 'Nấu xong lúc: ${FormatUtils.dinhDangNgayGio(don.thoiGianHoanThanh)}. Vui lòng đến quầy lấy!'
                : 'Chờ bếp nấu xong và báo lấy món',
            isActive: currentStep >= 2,
            isCompleted: currentStep > 2,
            highlight: currentStep == 2,
          ),
          _buildStepConnector(isCompleted: currentStep > 2),
          _buildStepRow(
            stepNumber: 4,
            title: 'Hoàn tất đơn hàng',
            subtitle: 'Sinh viên đã nhận phần ăn',
            isActive: currentStep >= 3,
            isCompleted: currentStep >= 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 15),
      width: 2,
      height: 20,
      color: isCompleted ? Colors.green : Colors.grey.shade300,
    );
  }

  Widget _buildStepRow({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    bool highlight = false,
  }) {
    Color circleColor = isCompleted
        ? Colors.green
        : (isActive ? (highlight ? Colors.teal : Colors.orange) : Colors.grey.shade300);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text('$stepNumber', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: highlight ? Colors.teal.shade800 : Colors.grey.shade600,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isItalic = false, bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

