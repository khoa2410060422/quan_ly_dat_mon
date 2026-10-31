import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/format_utils.dart';

class QrViewWidget extends StatelessWidget {
  final int maDon;
  final String maSv;
  final double tongTien;
  final String tenNganHang;
  final String soTaiKhoan;
  final String chuTaiKhoan;

  const QrViewWidget({
    super.key,
    required this.maDon,
    required this.maSv,
    required this.tongTien,
    this.tenNganHang = 'MB Bank (Quân Đội)',
    this.soTaiKhoan = '0987654321',
    this.chuTaiKhoan = 'CANTIN TRUONG DAI HOC',
  });

  String get noiDungChuyenKhoan => 'DATMON $maDon $maSv';

  void _saoChep(BuildContext context, String text, String thongBao) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(thongBao),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vietQrUrl =
        'https://img.vietqr.io/image/MB-$soTaiKhoan-compact2.jpg?amount=${tongTien.toInt()}&addInfo=${Uri.encodeComponent(noiDungChuyenKhoan)}&accountName=${Uri.encodeComponent(chuTaiKhoan)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Ngân hàng
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VIETQR / CHUYỂN KHOẢN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    tenNganHang,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Khung hiển thị mã QR
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Image.network(
              vietQrUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback khi không có mạng: Vẽ QR giả lập bằng Canvas
                return CustomPaint(
                  painter: _QrCanvasPainter(seed: maDon * 100 + tongTien.toInt()),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange, width: 1.5),
                      ),
                      child: const Text(
                        'CANTIN QR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quét mã QR bằng ứng dụng Ngân hàng hoặc Ví điện tử',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Divider(height: 24),

          // Thông tin chi tiết thanh toán
          _buildInfoRow(
            context: context,
            label: 'Chủ tài khoản',
            value: chuTaiKhoan,
            showCopy: false,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context: context,
            label: 'Số tài khoản',
            value: soTaiKhoan,
            showCopy: true,
            copyText: soTaiKhoan,
            copyMessage: 'Đã sao chép số tài khoản!',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context: context,
            label: 'Số tiền thanh toán',
            value: FormatUtils.dinhDangTien(tongTien),
            valueColor: Colors.deepOrange,
            isBold: true,
            showCopy: false,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            context: context,
            label: 'Nội dung chuyển khoản',
            value: noiDungChuyenKhoan,
            valueColor: Colors.blue.shade800,
            isBold: true,
            showCopy: true,
            copyText: noiDungChuyenKhoan,
            copyMessage: 'Đã sao chép nội dung chuyển khoản!',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool showCopy = false,
    String? copyText,
    String? copyMessage,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ),
              if (showCopy && copyText != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _saoChep(context, copyText, copyMessage ?? 'Đã sao chép!'),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.copy_rounded, size: 16, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Canvas Painter vẽ mô phỏng mã QR ma trận chuẩn với 3 góc định vị
class _QrCanvasPainter extends CustomPainter {
  final int seed;
  _QrCanvasPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()..color = Colors.black87;
    final paintLight = Paint()..color = Colors.white;

    // Kích thước lưới 21x21 (chuẩn QR version 1)
    const int gridSize = 21;
    final double moduleSize = size.width / gridSize;

    // Nền trắng
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintLight);

    // Vẽ 3 ô vuông định vị (Position Patterns) ở 3 góc
    _drawPositionPattern(canvas, 0, 0, moduleSize, paintDark, paintLight);
    _drawPositionPattern(canvas, (gridSize - 7) * moduleSize, 0, moduleSize, paintDark, paintLight);
    _drawPositionPattern(canvas, 0, (gridSize - 7) * moduleSize, moduleSize, paintDark, paintLight);

    // Vẽ các điểm dữ liệu ma trận
    int currentSeed = seed;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Bỏ qua 3 góc định vị
        if ((r < 7 && c < 7) || (r < 7 && c >= gridSize - 7) || (r >= gridSize - 7 && c < 7)) {
          continue;
        }
        // Timing patterns
        if (r == 6 || c == 6) {
          if ((r + c) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(c * moduleSize, r * moduleSize, moduleSize, moduleSize),
              paintDark,
            );
          }
          continue;
        }

        // Pseudo-random data modules
        currentSeed = (currentSeed * 1103515245 + 12345) & 0x7fffffff;
        if (currentSeed % 3 != 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * moduleSize, r * moduleSize, moduleSize, moduleSize),
            paintDark,
          );
        }
      }
    }
  }

  void _drawPositionPattern(
    Canvas canvas,
    double x,
    double y,
    double mod,
    Paint dark,
    Paint light,
  ) {
    // Ô ngoài 7x7
    canvas.drawRect(Rect.fromLTWH(x, y, 7 * mod, 7 * mod), dark);
    // Ô trắng 5x5
    canvas.drawRect(Rect.fromLTWH(x + mod, y + mod, 5 * mod, 5 * mod), light);
    // Ô đen trung tâm 3x3
    canvas.drawRect(Rect.fromLTWH(x + 2 * mod, y + 2 * mod, 3 * mod, 3 * mod), dark);
  }

  @override
  bool shouldRepaint(covariant _QrCanvasPainter oldDelegate) => oldDelegate.seed != seed;
}

