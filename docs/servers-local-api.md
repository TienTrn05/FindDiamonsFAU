# Servers: dữ liệu localhost trên Android

App lấy danh sách từ `/api/minecraft-servers/catalog` và ghép trạng thái từ
`/api/minecraft-servers` theo `id`. Banner ưu tiên trường `banner` được backend
phục vụ tại `/api/assets/server-banners/`; `bannerSource` chỉ dành cho API cũ.
Giữ kiểu `full`, `logo`, `icon` và GIF động. Không dùng số liệu demo khi API lỗi.

`online: true` hiển thị số người chơi và sức chứa; `false` hiển thị Offline;
`null` hiển thị Unknown nếu chưa từng nhận được trạng thái của server đó. Nếu một
lần kiểm tra riêng lẻ lỗi, giữ trạng thái gần nhất. Mất mạng không xoá dữ liệu cũ.
Trang không có nút refresh hay kéo xuống refresh.

Flutter kiểm tra API theo chu kỳ 60 giây khi app ở foreground. Backend hiện có
`fetchedAt` làm phiên dữ liệu, chưa có WebSocket/SSE hay API thông báo cập nhật.
Vì vậy client dùng polling, chỉ công bố snapshot mới khi `fetchedAt` lớn hơn
phiên đang hiển thị. Cùng phiên hoặc phiên cũ hơn trả về cùng snapshot cache;
không báo UI dựng lại. Các yêu cầu đồng thời được gộp thành một lần tải.

Luồng khởi động chờ nạp xong Find, History, Help, Skins, Servers và Maps/Seeds,
cùng các ảnh mạng của danh mục (banner, ảnh skin và texture, ảnh bìa map/seed).
Chỉ sau khi preload và kiểm tra ảnh thành công mới rời màn loading. Khi lỗi,
giữ loading và tự thử lại sau 60 giây, không hiện khối lỗi/nút Try again. Các trang dùng lại cùng
repository đã chuẩn bị; không tải lại các danh mục khi vừa vào chương trình.

Trong lần đồng bộ sau, dữ liệu cũ vẫn hiển thị trong khi tải dữ liệu/ảnh mới.
Chỉ thay snapshot sau khi ảnh mới sẵn sàng; không reset vị trí cuộn. Cache API
trong RAM có TTL 60 giây. Cache ảnh nén tối đa 64 MiB theo URL giúp Flutter giải
mã lại ảnh từ RAM nếu decoded ImageCache bị thu hồi, không phải gọi HTTP lại.
Ảnh URL không đổi được tái sử dụng giữa các phiên dữ liệu; ảnh đổi URL sẽ nạp
xong trước khi hiển thị. Cache này không phải lưu dữ liệu qua lần đóng app.

Các thẻ Servers được dựng lười và giữ lại sau khi đã xuất hiện, cùng trạng thái
ảnh/GIF và vị trí cuộn. Các thẻ dùng key theo ID để refresh hoặc đổi thứ tự không
gắn nhầm trạng thái. Chỉ thay nội dung thẻ khi dữ liệu hoặc bố cục thay đổi.
Ảnh sử dụng ImageCache của Flutter; không tải lại ảnh khi cuộn về thẻ đã xem.
Các tab giữ nguyên cây trạng thái; animation chuyển tab dùng lại nội dung qua
các frame, chỉ cập nhật chuyển động và thứ tự vẽ.

Android debug mặc định gọi `http://127.0.0.1:8000`. Task Gradle
`connectLocalDebugApi` tự thiết lập `adb reverse tcp:8000 tcp:8000` trên các thiết
bị đang kết nối trước `preDebugBuild`, kể cả sau khi khởi động lại emulator.
Chạy `flutter run` hoặc F5 như bình thường, không cần truyền thêm API_BASE_URL.
Kết nối này tránh lỗi nhận thiếu phản hồi qua gateway `10.0.2.2` trên môi trường
local hiện tại. Trình duyệt và app đều dùng cùng backend localhost của máy tính.

Nếu cài APK đã build sẵn mà không chạy build/debug, thiết lập kết nối thủ công:

```powershell
adb -s emulator-5554 reverse tcp:8000 tcp:8000
```

Cần chạy lại lệnh `adb reverse` khi khởi động lại emulator. Với điện thoại thật,
thay `emulator-5554` bằng ID từ `adb devices`. Cấu hình này chỉ dành cho phát
triển local; bản phát hành cần `API_BASE_URL` của backend được triển khai.

Kiểm thử tích hợp HTTP, trạng thái và tải lại banner:

```powershell
flutter test test/api_servers_repository_test.dart test/server_status_test.dart test/server_network_banner_test.dart test/servers_profile_test.dart test/server_banner_test.dart test/app_translations_test.dart
```

Kiểm tra startup, đồng bộ revision và cache ảnh:

```powershell
flutter test test/app_startup_test.dart test/servers_sync_test.dart test/app_image_cache_test.dart
$env:CHECK_LIVE_API = 'true'
flutter test test/live_api_smoke_test.dart
```
