import 'package:flutter/material.dart';
import '../../models/thuc_don_ngay_model.dart';
import '../../repositories/don_hang_repository.dart';
import '../../core/utils/format_utils.dart';
import '../thanh_toan/man_hinh_thanh_toan_qr.dart';

class ManHinhGioHang extends StatefulWidget {
  final String maSv;
  final String ngayDat;
  final List<Map<String, dynamic>> gioHang;

  const ManHinhGioHang({
    super.key,
    required this.maSv,
    required this.ngayDat,
    required this.gioHang,
  });

  @override
  State<ManHinhGioHang> createState() => _ManHinhGioHangState();
}

class _ManHinhGioHangState extends State<ManHinhGioHang> {
  final _ghiChuController = TextEditingController();
  final _donHangRepo = DonHangRepository();

  late List<Map<String, dynamic>> _danhSachItems;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _danhSachItems = List.from(widget.gioHang);
  }

  double get _tongTien {
    double total = 0;
    for (var item in _danhSachItems) {
      final mon = item['thuc_don'] as ThucDonNgayModel;
      final sl = item['so_luong'] as int;
      total += mon.giaMonAn * sl;
    }
    return total;
  }

  void _tangSoLuong(int index) {
    setState(() {
      final mon = _danhSachItems[index]['thuc_don'] as ThucDonNgayModel;
      int sl = _danhSachItems[index]['so_luong'] as int;
      if (sl < mon.soLuongConLai) {
        _danhSachItems[index]['so_luong'] = sl + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số lượng vượt quá số suất còn lại (${mon.soLuongConLai})!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _giamSoLuong(int index) {
    setState(() {
      int sl = _danhSachItems[index]['so_luong'] as int;
      if (sl > 1) {
        _danhSachItems[index]['so_luong'] = sl - 1;
      } else {
        _danhSachItems.removeAt(index);
      }
    });
  }

  Future<void> _xacNhanDatMon() async {
    if (_danhSachItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giỏ hàng trống!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String thoiGianDat = DateTime.now().toString();

      Map<String, dynamic> donHangMap = {
        'ma_sv': widget.maSv,
        'ngay_dat': widget.ngayDat,
        'thoi_gian_dat': thoiGianDat,
        'tong_tien': _tongTien,
        'trang_thai_don': 'cho_xac_nhan',
        'ghi_chu': _ghiChuController.text.trim(),
        'phuong_thuc_thanh_toan': 'Chuyển khoản QR',
      };

      List<Map<String, dynamic>> chiTietList = _danhSachItems.map((item) {
        final mon = item['thuc_don'] as ThucDonNgayModel;
        return {
          'ma_thuc_don': mon.maThucDon,
          'so_luong': item['so_luong'],
          'gia_ban': mon.giaMonAn,
        };
      }).toList();

      // Lưu đơn vào CSDL và tự động trừ số lượng suất ăn mỗi ngày
      int maDon = await _donHangRepo.taoDonHangMoi(
        donHang: donHangMap,
        chiTietList: chiTietList,
      );

      if (!mounted) return;

      // Chuyển sang Màn hình Thông báo chờ xác nhận và Chuyển khoản QR
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ManHinhThanhToanQr(
            maDon: maDon,
            maSv: widget.maSv,
            tongTien: _tongTien,
            ngayDat: widget.ngayDat,
            ghiChu: _ghiChuController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt món: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Xác Nhận & Đặt Món Ăn'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Thoát giỏ hàng',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Tooltip(
            message: 'Thoát về thực đơn',
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              label: const Text(
                'Thoát',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: _danhSachItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.remove_shopping_cart_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Giỏ hàng của bạn đang trống!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại chọn món'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Danh sách món trong giỏ
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _danhSachItems.length,
                    itemBuilder: (context, index) {
                      final item = _danhSachItems[index];
                      final mon = item['thuc_don'] as ThucDonNgayModel;
                      final int sl = item['so_luong'] as int;

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Ảnh nhỏ
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade200,
                                  child: mon.hinhAnh != null
                                      ? Image.network(mon.hinhAnh!, fit: BoxFit.cover)
                                      : const Icon(Icons.fastfood, color: Colors.orange),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Thông tin món
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mon.tenMon,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Đơn giá: ${FormatUtils.dinhDangTien(mon.giaMonAn)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      'Thành tiền: ${FormatUtils.dinhDangTien(mon.giaMonAn * sl)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Bộ tăng giảm số lượng
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.deepOrange.shade300),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        sl == 1 ? Icons.delete_outline : Icons.remove,
                                        size: 18,
                                        color: sl == 1 ? Colors.red : Colors.deepOrange,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _giamSoLuong(index),
                                    ),
                                    Text(
                                      '$sl',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18, color: Colors.deepOrange),
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _tangSoLuong(index),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Ghi chú & Tổng kết đơn hàng
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ghi chú
                        TextField(
                          controller: _ghiChuController,
                          decoration: InputDecoration(
                            labelText: 'Ghi chú cho bếp (tuỳ chọn)',
                            hintText: 'Ví dụ: Ít cơm, không lấy rau, thêm ớt...',
                            prefixIcon: const Icon(Icons.edit_note, color: Colors.deepOrange),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Thông tin ngày đặt
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ngày nhận phần ăn:', style: TextStyle(color: Colors.grey.shade700)),
                            Text(
                              widget.ngayDat,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Tổng tiền
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng thanh toán:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              FormatUtils.dinhDangTien(_tongTien),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Nút Xác nhận đặt món & Chuyển sang thanh toán QR
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.qr_code_rounded),
                          label: Text(
                            _isSubmitting
                                ? 'Đang gửi đơn hàng...'
                                : 'Xác Nhận Đặt Món & Thanh Toán QR',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isSubmitting ? null : _xacNhanDatMon,
                        ),
                        const SizedBox(height: 8),

                        // Nút Thoát giỏ hàng
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade800,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text(
                            'Thoát giỏ hàng - Tiếp tục chọn món',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

