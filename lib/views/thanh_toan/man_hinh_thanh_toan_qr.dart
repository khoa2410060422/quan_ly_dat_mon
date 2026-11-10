import 'package:flutter/material.dart';
import '../../core/widgets/qr_view_widget.dart';
import '../don_hang/man_hinh_chi_tiet_don_hang.dart';
import '../don_hang/man_hinh_danh_sach_don_hang.dart';

class ManHinhThanhToanQr extends StatelessWidget {
  final int maDon;
  final String maSv;
  final double tongTien;
  final String ngayDat;
  final String? ghiChu;

  const ManHinhThanhToanQr({
    super.key,
    required this.maDon,
    required this.maSv,
    required this.tongTien,
    required this.ngayDat,
    this.ghiChu,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Khi bấm nút back của thiết bị, quay về màn hình danh sách đơn hàng
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ManHinhDanhSachDonHang(maSv: maSv)),
          (route) => route.isFirst,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text('Thanh Toán Đơn Hàng #$maDon'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => ManHinhDanhSachDonHang(maSv: maSv)),
                  (route) => route.isFirst,
                );
              },
              child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thông báo trạng thái đặt hàng thành công & Chờ xác nhận
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ĐƠN HÀNG #$maDon - CHỜ BẾP XÁC NHẬN',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã trừ số lượng suất ăn trong ngày. Vui lòng quét mã QR chuyển khoản để cantin tiến hành làm món!',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Thẻ hiển thị mã QR thanh toán ngân hàng
                QrViewWidget(
                  maDon: maDon,
                  maSv: maSv,
                  tongTien: tongTien,
                ),
                const SizedBox(height: 20),

                // Nút "Tôi đã chuyển khoản & Theo dõi đơn"
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Tôi Đã Chuyển Khoản - Theo Dõi Đơn Hàng',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManHinhChiTietDonHang(maDon: maDon, maSv: maSv),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

