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
  int _selectedFilterTab = 0; // 0: Hoạt động, 1: Đã xóa, 2: Tất cả

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
      final list = await _sinhVienRepo.getTatCaSinhVien(baoGomDaXoa: true);
      if (mounted) {
        setState(() {
          _danhSachSv = list;
          _isLoading = false;
        });
        _filterList();
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
    _filterList();
  }

  void _filterList() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _danhSachLoc = _danhSachSv.where((sv) {
        // Lọc theo trạng thái tab:
        // 0: Hoạt động (chưa xóa)
        // 1: Đã xóa
        // 2: Tất cả
        if (_selectedFilterTab == 0 && sv.isDaXoa) return false;
        if (_selectedFilterTab == 1 && !sv.isDaXoa) return false;

        // Lọc theo từ khóa tìm kiếm
        if (q.isEmpty) return true;
        return sv.maSv.toLowerCase().contains(q) ||
            sv.hoTen.toLowerCase().contains(q) ||
            sv.soDienThoai.toLowerCase().contains(q) ||
            sv.email.toLowerCase().contains(q) ||
            sv.khoaLop.toLowerCase().contains(q);
      }).toList();
    });
  }

  /// Xác nhận và xóa tài khoản sinh viên (nếu admin thấy không phù hợp)
  Future<void> _xacNhanXoaSinhVien(SinhVienModel sv) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xóa Tài Khoản Sinh Viên',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin có chắc chắn muốn xóa tài khoản này vì thông tin không phù hợp?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Họ và tên: ${sv.hoTen}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('• Mã SV: ${sv.maSv}'),
                  const SizedBox(height: 4),
                  Text('• Email: ${sv.email}'),
                  const SizedBox(height: 4),
                  Text('• Khoá / Lớp: ${sv.khoaLop}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, size: 18, color: Colors.deepOrange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Khi đăng nhập, hệ thống sẽ thông báo "Tài khoản đã bị xóa" và không cho phép đăng nhập hay đặt món.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );

    if (xacNhan == true) {
      try {
        await _sinhVienRepo.xoaSinhVien(sv.maSv);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ Đã xóa tài khoản sinh viên ${sv.hoTen} (${sv.maSv}) thành công!'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        _loadSinhVien();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Khôi phục tài khoản sinh viên đã xóa
  Future<void> _xacNhanKhoiPhucSinhVien(SinhVienModel sv) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.restore_rounded, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Khôi Phục Tài Khoản',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn mở lại quyền truy cập cho sinh viên ${sv.hoTen} (Mã SV: ${sv.maSv})? Sinh viên sẽ có thể đăng nhập bình thường.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );

    if (xacNhan == true) {
      try {
        await _sinhVienRepo.khoiPhucSinhVien(sv.maSv);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã khôi phục tài khoản ${sv.hoTen} (${sv.maSv}) thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSinhVien();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi khôi phục: $e'), backgroundColor: Colors.red),
        );
      }
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
    final int countHoatDong = _danhSachSv.where((s) => !s.isDaXoa).length;
    final int countDaXoa = _danhSachSv.where((s) => s.isDaXoa).length;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('========================================================================================');
    buffer.writeln('                 DANH SÁCH TÀI KHOẢN SINH VIÊN ĐÃ ĐĂNG KÝ CANTIN                        ');
    buffer.writeln('========================================================================================');
    buffer.writeln('Thời gian xuất: $nowStr');
    buffer.writeln('Tổng số: ${_danhSachSv.length} tài khoản (Đang hoạt động: $countHoatDong, Đã xóa: $countDaXoa)');
    buffer.writeln('----------------------------------------------------------------------------------------');
    buffer.writeln('STT\tMã SV\tHọ và Tên\tSố điện thoại\tEmail\tKhoa / Lớp\tTrạng thái');
    buffer.writeln('----------------------------------------------------------------------------------------');

    for (int i = 0; i < _danhSachSv.length; i++) {
      final sv = _danhSachSv[i];
      final trangThai = sv.isDaXoa ? 'ĐÃ XÓA' : 'Hoạt động';
      buffer.writeln('${i + 1}\t${sv.maSv}\t${sv.hoTen}\t${sv.soDienThoai}\t${sv.email}\t${sv.khoaLop}\t$trangThai');
    }
    buffer.writeln('========================================================================================');

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
                height: 240,
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
    final int countHoatDong = _danhSachSv.where((s) => !s.isDaXoa).length;
    final int countDaXoa = _danhSachSv.where((s) => s.isDaXoa).length;

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
                            'Quản Lý Sinh Viên Đăng Ký',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'Hoạt động: $countHoatDong | Đã xóa: $countDaXoa',
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

                const SizedBox(height: 10),

                // Bộ lọc trạng thái (Hoạt động / Đã xóa / Tất cả)
                Row(
                  children: [
                    _buildFilterChip('Hoạt động', 0, countHoatDong, Colors.green),
                    const SizedBox(width: 8),
                    _buildFilterChip('Đã xóa', 1, countDaXoa, Colors.red),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tất cả', 2, _danhSachSv.length, Colors.deepPurple),
                  ],
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
                                  : _selectedFilterTab == 1
                                      ? 'Không có tài khoản nào bị xóa.'
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

  Widget _buildFilterChip(String label, int tabIndex, int count, Color color) {
    final isSelected = _selectedFilterTab == tabIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterTab = tabIndex;
          });
          _filterList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinhVienCard(SinhVienModel sv, int index) {
    final bool isDaXoa = sv.isDaXoa;

    return Card(
      elevation: isDaXoa ? 1 : 2,
      color: isDaXoa ? Colors.grey.shade50 : Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDaXoa ? Colors.red.shade200 : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: isDaXoa ? Colors.grey.shade300 : Colors.deepPurple.shade50,
              child: Text(
                sv.hoTen.isNotEmpty ? sv.hoTen.trim().split(' ').last[0].toUpperCase() : 'SV',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDaXoa ? Colors.grey.shade600 : Colors.deepPurple,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDaXoa ? Colors.grey.shade600 : Colors.black87,
                            decoration: isDaXoa ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (isDaXoa)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Đã xóa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDaXoa ? Colors.grey.shade200 : Colors.deepPurple.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sv.maSv,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDaXoa ? Colors.grey.shade700 : Colors.deepPurple,
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

            // Nút Thao tác: Xóa / Khôi phục
            Column(
              children: [
                if (!isDaXoa)
                  Tooltip(
                    message: 'Xóa tài khoản nếu không phù hợp',
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _xacNhanXoaSinhVien(sv),
                    ),
                  )
                else
                  Tooltip(
                    message: 'Khôi phục tài khoản',
                    child: IconButton(
                      icon: const Icon(Icons.restore_rounded, color: Colors.green),
                      onPressed: () => _xacNhanKhoiPhucSinhVien(sv),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
