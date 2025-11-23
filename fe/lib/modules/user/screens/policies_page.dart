// lib/modules/user/screens/policies_page.dart

import 'package:flutter/material.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';

class PoliciesPage extends StatelessWidget {
  const PoliciesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Chính sách', style: AppTextStyles.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPolicySection(
            title: '📜 Điều khoản sử dụng',
            content: '''
1. Chấp nhận điều khoản
Bằng việc truy cập và sử dụng ứng dụng này, bạn đồng ý tuân thủ các điều khoản và điều kiện sử dụng.

2. Tài khoản người dùng
- Bạn có trách nhiệm bảo mật thông tin tài khoản
- Không được chia sẻ tài khoản với người khác
- Thông báo ngay nếu phát hiện truy cập trái phép

3. Nội dung
- Không đăng tải nội dung vi phạm pháp luật
- Tôn trọng bản quyền và sở hữu trí tuệ
- Chúng tôi có quyền xóa nội dung không phù hợp

4. Giao dịch
- Đảm bảo thông tin thanh toán chính xác
- Kiểm tra kỹ đơn hàng trước khi xác nhận
- Tuân thủ chính sách hoàn trả
            ''',
          ),
          _buildPolicySection(
            title: '🔒 Chính sách bảo mật',
            content: '''
1. Thu thập thông tin
Chúng tôi thu thập:
- Thông tin cá nhân (tên, email, số điện thoại)
- Thông tin đơn hàng và thanh toán
- Lịch sử mua hàng

2. Sử dụng thông tin
- Xử lý đơn hàng và giao hàng
- Cải thiện dịch vụ
- Gửi thông báo quan trọng
- Marketing (nếu bạn đồng ý)

3. Bảo vệ thông tin
- Mã hóa dữ liệu nhạy cảm
- Hệ thống bảo mật nhiều lớp
- Không chia sẻ với bên thứ ba không liên quan

4. Quyền của bạn
- Truy cập và chỉnh sửa thông tin
- Xóa tài khoản
- Từ chối nhận email marketing
            ''',
          ),
          _buildPolicySection(
            title: '↩️ Chính sách đổi trả',
            content: '''
1. Điều kiện đổi trả
- Trong vòng 7 ngày kể từ ngày nhận hàng
- Sản phẩm còn nguyên tem mác
- Chưa qua sử dụng hoặc giặt tẩy
- Có hóa đơn mua hàng

2. Trường hợp được đổi trả
- Sản phẩm bị lỗi do nhà sản xuất
- Giao sai sản phẩm
- Sản phẩm không đúng mô tả
- Bị hư hỏng trong quá trình vận chuyển

3. Quy trình đổi trả
- Liên hệ bộ phận CSKH
- Gửi ảnh sản phẩm và hóa đơn
- Đóng gói sản phẩm cẩn thận
- Gửi về địa chỉ được cung cấp

4. Chi phí
- Miễn phí nếu lỗi do shop
- Khách hàng chịu phí ship nếu đổi ý
            ''',
          ),
          _buildPolicySection(
            title: '🚚 Chính sách giao hàng',
            content: '''
1. Phạm vi giao hàng
- Giao hàng toàn quốc
- Ưu tiên nội thành các thành phố lớn

2. Thời gian giao hàng
- Nội thành: 1-3 ngày
- Ngoại thành: 3-7 ngày
- Miền núi, hải đảo: 7-14 ngày

3. Phí giao hàng
- Miễn phí đơn từ 500.000đ
- Phí theo khoảng cách với đơn dưới 500k

4. Theo dõi đơn hàng
- Nhận mã vận đơn qua email/SMS
- Theo dõi trên app
- Thông báo khi giao hàng thành công
            ''',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                content,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}