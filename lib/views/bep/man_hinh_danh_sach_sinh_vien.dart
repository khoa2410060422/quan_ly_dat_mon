import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/sinh_vien_model.dart';
import '../../repositories/sinh_vien_repository.dart';
import '../../core/utils/format_utils.dart';

class ManHinhDanhSachSinhVien extends StatefulWidget {
  const ManHinhDanhSachSinhVien({super.key});

  @override
  State<ManHinhDanhSachSinhVien> createState() => _ManHinhDanhSachSinhVienState();
}

class _ManHinhDanhSachSinhVienState extends State<ManHinhDanhSachSinhVien> {
  final _sinhVienRepo = SinhVienRepository();
  final _searchController = TextEditingController();

  List<SinhVienModel> _danhSachSv = [];
  List<SinhVienModel> _danhSachLoc = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSinhVien();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSinhVien() async {
    setState(() => _isLoading = true);
    try {
      final list = await _sinhVienRepo.getTatCaSinhVien();
      if (mounted) {
        setState(() {
          _danhSachSv = list;
          _danhSachLoc = list;
          _isLoading = false;
        });
        _filterList(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSearchChanged() {
    _filterList(_searchController.text);
  }

  void _filterList(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _danhSachLoc = _danhSachSv);
    } else {
      setState(() {
        _danhSachLoc = _danhSachSv.where((sv) {
          return sv.maSv.toLowerCase().contains(q) ||
              sv.hoTen.toLowerCase().contains(q) ||
              sv.soDienThoai.toLowerCase().contains(q) ||
              sv.email.toLowerCase().contains(q) ||
              sv.khoaLop.toLowerCase().contains(q);
        }).toList();
      });
    }
  }

  /// Xuất danh sách tài khoản sinh viên thành văn bản để sao chép vào Excel / Word / In ấn
  void _xuatDanhSach() {
    if (_danhSachSv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có tài khoản sinh viên nào để xuất!')),
      );
      return;
    }

    final nowStr = FormatUtils.dinhDangNgayGio(DateTime.now().toString());
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('========================================================================');
    buffer.writeln('          DANH SÁCH TÀI KHOẢN SINH VIÊN ĐÃ ĐĂNG KÝ CANTIN               ');
    buffer.writeln('========================================================================');
    buffer.writeln('Thời gian xuất: $nowStr');
    buffer.writeln('Tổng số lượng sinh viên: ${_danhSachSv.length}');
    buffer.writeln('------------------------------------------------------------------------');
    buffer.writeln('STT\tMã SV\tHọ và Tên\tSố điện thoại\tEmail\tKhoa / Lớp');
    buffer.writeln('------------------------------------------------------------------------');

    for (int i = 0; i < _danhSachSv.length; i++) {
      final sv = _danhSachSv[i];
      buffer.writeln('${i + 1}\t${sv.maSv}\t${sv.hoTen}\t${sv.soDienThoai}\t${sv.email}\t${sv.khoaLop}');
    }
    buffer.writeln('========================================================================');

    final exportText = buffer.toString();

    // Hiển thị dialog xem trước & sao chép
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.description_outlined, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Xuất Danh Sách Sinh Viên', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đã định dạng sẵn dạng bảng (phân tách Tab) tương thích dán trực tiếp vào Excel, Word, Google Sheets.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Container(
                height: 220,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    exportText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Sao Chép Toàn Bộ'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: exportText));
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 Đã sao chép danh sách sinh viên vào bộ nhớ tạm!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Danh Sách Sinh Viên Đã Đăng Ký'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadSinhVien,
          ),
          IconButton(
            tooltip: 'Xuất danh sách (Excel/Word)',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _xuatDanhSach,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Thống kê & Ô Tìm Kiếm
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.deepPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tài Khoản Sinh Viên Đăng Ký',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Tổng cộng: ${_danhSachSv.length} sinh viên trên hệ thống',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Xuất DS', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _xuatDanhSach,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Ô tìm kiếm sinh viên
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo Mã SV, Họ tên, SĐT, Khoa/Lớp...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.deepPurple),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách Sinh viên
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _danhSachLoc.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Không tìm thấy sinh viên nào phù hợp'
                                  : 'Chưa có sinh viên nào đăng ký tài khoản.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSinhVien,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          itemCount: _danhSachLoc.length,
                          itemBuilder: (context, index) {
                            final sv = _danhSachLoc[index];
                            return _buildSinhVienCard(sv, index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinhVienCard(SinhVienModel sv, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar với số thứ tự
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.deepPurple.shade50,
              child: Text(
                sv.hoTen.isNotEmpty ? sv.hoTen.trim().split(' ').last[0].toUpperCase() : 'SV',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Thông tin sinh viên
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sv.hoTen,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sv.maSv,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // SĐT
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        sv.soDienThoai.isNotEmpty ? sv.soDienThoai : '--',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sv.email.isNotEmpty ? sv.email : '--',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Khoa / Lớp
                  Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 14, color: Colors.indigo),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sv.khoaLop.isNotEmpty ? sv.khoaLop : '--',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

