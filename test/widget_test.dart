import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_dat_mon/main.dart';

void main() {
  testWidgets('App khởi động thành công', (WidgetTester tester) async {
    // Build app và kích hoạt frame đầu tiên
    await tester.pumpWidget(const MyApp());

    // Kiểm tra tiêu đề hoặc thành phần đăng nhập
    expect(find.text('CANTIN SINH VIÊN'), findsOneWidget);
  });
}
