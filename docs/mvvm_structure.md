# Cấu trúc MVVM của dự án

Dự án đang được chuyển dần sang mô hình MVVM theo từng feature.

## Luồng chính

```txt
View
  -> ViewModel
      -> Repository
          -> Service / Firebase / API
```

## Ý nghĩa từng lớp

### View

View là các màn hình và widget Flutter.

Ví dụ:

```txt
lib/features/auth/screens/login_screen.dart
lib/features/home/screens/admin_home_screen.dart
lib/features/feed/screens/feed_screen.dart
```

View chỉ nên làm các việc:

- Hiển thị giao diện.
- Nhận thao tác từ người dùng.
- Gọi hàm trong ViewModel.
- Điều hướng màn hình khi cần.

View không nên chứa nhiều logic xử lý dữ liệu hoặc gọi Firestore trực tiếp nếu chức năng đó đã lớn.

### ViewModel

ViewModel giữ trạng thái và xử lý hành động của màn hình.

Ví dụ:

```txt
lib/features/auth/view_models/login_view_model.dart
lib/features/auth/view_models/register_view_model.dart
lib/features/home/view_models/role_home_view_model.dart
lib/features/feed/view_models/feed_view_model.dart
```

ViewModel thường chứa:

- `isLoading`
- `errorMessage`
- trạng thái đang chọn
- hàm xử lý như `login`, `register`, `setFilter`, `selectIndex`

Tất cả ViewModel đang kế thừa từ:

```txt
lib/core/view_models/base_view_model.dart
```

### Repository

Repository là lớp trung gian giữa ViewModel và dữ liệu thật.

Ví dụ:

```txt
lib/features/auth/repositories/auth_repository.dart
```

Repository giúp ViewModel không cần biết dữ liệu đến từ Firebase, API hay nguồn khác.

### Service

Service là nơi nói chuyện trực tiếp với Firebase hoặc API.

Ví dụ:

```txt
lib/features/auth/services/auth_service.dart
lib/core/services/app_firestore_service.dart
```

`AppFirestoreService` hiện là nơi gom các collection Firestore như `users`, `buildings`, `chats`, `rooms`, `invoices`.

## Cách tạo feature mới

Khi thêm chức năng mới, nên tạo theo dạng:

```txt
lib/features/example/
  models/
  repositories/
  services/
  screens/
  view_models/
  widgets/
```

Không phải feature nào cũng cần đủ tất cả thư mục. Nếu chức năng nhỏ, có thể chỉ cần `screens` và `view_models`.

## Trạng thái hiện tại

Đã chuyển sang MVVM:

- Auth: đăng nhập, đăng ký.
- Home: chọn giao diện theo role, đăng xuất.
- Role home: thanh điều hướng của admin, quản lý, người thuê.
- Feed: tìm kiếm, lọc, đọc quảng cáo, gửi yêu cầu tham gia, bình luận, mở chat từ trang chủ.
- Messages: danh sách chat, xóa chat riêng, gửi tin nhắn.
- Hóa đơn: danh sách hóa đơn admin/người thuê, tạo hóa đơn, xác nhận/từ chối thanh toán, báo đã thanh toán, tạo thanh toán PayOS.

Còn nên chuyển tiếp:

- Quản lý phòng.
- Quản lý tòa nhà.
- Cài đặt tòa nhà.
