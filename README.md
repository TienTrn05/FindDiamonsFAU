# Find Diamonds

> Cập nhật Find/Pro/rewarded ads: xem [hướng dẫn test và cấu hình phát hành](docs/monetization.md). Show another đã nối SDK AdMob; thanh toán thật vẫn cần dịch vụ billing và xác minh entitlement.

Flutter UI dựng theo ảnh tham chiếu: onboarding và năm tab Find, History, Skins, Servers, Maps. Dữ liệu JSON được đóng gói trong ứng dụng, không gọi API.

## Chạy

```sh
flutter pub get
flutter run -d chrome
```

Có thể chạy trên Android/iOS bằng thiết bị Flutter tương ứng. Font và hình ảnh được đóng gói trong app, không cần tải ảnh từ mạng lúc chạy.

## Hành vi

- Mỗi lần mở app đều có màn “Please wait…” ít nhất 1,1 giây, đồng thời đọc trạng thái đã xem onboarding. Lần đầu vào hướng dẫn; các lần sau vào Find.
- iOS: nếu ATT chưa được quyết định, hiển thị phần giải thích. Continue gọi hộp thoại quyền hệ thống thật; cả Allow và Ask App Not to Track đều tiếp tục hướng dẫn.
- Nếu quyền đã được quyết định, bị hạn chế hoặc không được hỗ trợ, bỏ qua phần giải thích. Hệ điều hành lưu lựa chọn ATT, app không hỏi lại ở mỗi lần mở.
- Android/web/desktop: đi thẳng từ màn chờ sang hướng dẫn, không gọi ATT và không coi Continue là đồng ý theo dõi.
- Next, vuốt và chấm phân trang chuyển bước.
- Onboarding chỉ hiển thị ở lần chạy đầu; app lưu `onboarding_seen` trước khi hiển thị nên reload hoặc chạy lại giữa chừng cũng vào thẳng Find. Xóa dữ liệu ứng dụng sẽ đặt lại trạng thái lần đầu.
- Skip/Done mở màn gói; cả hai icon đóng và thao tác Back đều kết thúc onboarding, chuyển sang Find.
- Checkbox ở bước 3 có thể bật/tắt, danh sách có thể cuộn.
- View All Plans mở ba gói và cập nhật lựa chọn, giá cùng nút hành động.
- Nút đóng màn gói cho phép hoàn tất mà không đăng ký.
- Khi chạy app, hoàn tất hoặc đóng paywall của onboarding sẽ vào Find. Widget onboarding chạy độc lập vẫn có màn hoàn tất để xem lại hướng dẫn.

## Các feature chính

Mỗi tab có thư mục riêng với `bloc/`, `data/`, `models/`, `presentation/`; không gom các tab vào Home.

| Route | Feature | Dữ liệu JSON |
| --- | --- | --- |
| `/find` | `lib/features/find/` | `assets/data/find/find.json` |
| `/history` | `lib/features/history/` | `assets/data/history/history.json` |
| `/skins` | `lib/features/skins/` | `assets/data/skins/skins.json` |
| `/servers` | `lib/features/servers/` | `assets/data/servers/servers.json` |
| `/maps` | `lib/features/maps/` | `assets/data/maps/maps.json` |
| `/help` | `lib/features/help/` | `assets/data/help/help.json` |

Luồng dữ liệu: JSON asset → repository trong `data/` → model trong `models/` → controller trong `bloc/` → màn hình trong `presentation/`. Các controller dùng `ChangeNotifier` của Flutter, với lifecycle tải/lỗi dùng chung từ `core/bloc/resource_controller.dart`. Repository có interface để thay nguồn JSON bằng API sau này.

`lib/app/navigation/app_shell.dart` ghép các route và giữ trạng thái chuyển tab. `lib/app/app_repositories.dart` nối các dependency và cho phép truyền repository khi kiểm thử. Model tìm kiếm dùng chung giữa Find và History đặt trong `lib/core/models/`. Màu, chữ, input decoration, nút và responsive dùng từ `core`/`common`.

- Find kiểm tra X/Z là số nguyên, seed không rỗng; chọn phiên bản/quặng, xem và đánh dấu tọa độ. Kết quả là fixture JSON cộng với X/Z nhập vào, **chưa phải thuật toán tìm quặng Minecraft**.
- History ban đầu trống; mỗi lần digging lưu một card vào JSON trên thiết bị. Bấm card xem toàn bộ vị trí đã lưu; có thể xóa từng bản ghi. Xem [Digging, History và Seeds](docs/digging-history.md).
- Skins có khung xem nhân vật 3D cố định phía trên, Idle/Walk và grid skin cuộn dọc riêng bên dưới. Kéo trên mô hình để xoay đủ 360° cả ngang lẫn dọc; chạm hai lần để về góc ban đầu. Chọn được skin khóa để xem trước; bấm Share mới mở hộp Watch Ads/Premium. Thưởng quảng cáo mở riêng skin và lưu quyền trên thiết bị. Skin đã mở chia sẻ ảnh PNG của nhân vật qua share sheet hệ thống; chưa xuất/cài texture skin Minecraft. Xem [widget mở khóa dùng chung](docs/unlock-dialog.md).
- Servers hiển thị số người chơi từ JSON; chạm server mở trang Server Info gồm banner, tên/tag, nút thêm Bedrock, copy/chia sẻ địa chỉ, website và mô tả. Nội dung, ảnh banner, port và link là dữ liệu tạm trong `assets/data/servers/servers.json`. Nút thêm hiển thị thông tin kết nối; website mở hộp thoại xem/copy link và chia sẻ mở menu copy. Chưa kết nối server, mở website hay gọi Minecraft.
- Maps có danh mục cuộn ngang, lọc, Favourite, chi tiết/copy seed và paywall cho mục khóa.
- AdMob: App Open khi khởi động, banner adaptive trên thanh điều hướng, Special Offer dạng native trong Maps, interstitial sau khoảng 3 phút sử dụng ở lần chuyển nội dung phù hợp và rewarded cho Show another. Pro ẩn quảng cáo; xem `docs/monetization.md` để test và cấu hình.

Form, vị trí cuộn, skin đang chọn và Favourite được giữ trong phiên chạy bằng `IndexedStack`. History lưu vào file `history.json` trong thư mục riêng của app và được khôi phục khi mở lại; web lưu JSON vào local storage. Route đặt tên có thể mở bằng `Navigator.pushNamed`.

Xem trực tiếp các tab khi phát triển:

```sh
flutter run --dart-define=SKIP_ONBOARDING=true
```

## Nối vào ứng dụng

Nút Help! trên Find mở trang Help với header cố định, FAQ mở từng mục có hình minh họa, danh sách chọn ngôn ngữ và hộp thoại điều khoản cuộn riêng với nút OK cố định. View tutorial mở lại ba bước hướng dẫn rồi trở về Help, không gọi quyền theo dõi hay paywall. Restore purchases có callback `onRestore` để nối billing; hiện hiển thị thông báo khi chưa có dịch vụ. Chọn ngôn ngữ áp dụng toàn ứng dụng trên iOS/Android, có cờ và radio như mẫu, lưu lựa chọn bằng `shared_preferences`. Hỗ trợ English, Español, Português, Türkçe, Français, Deutsch, Bahasa Indonesia và Tiếng Việt; bản dịch dùng offline, còn tên riêng, seed và địa chỉ được giữ nguyên. Nội dung FAQ, điều khoản, link và footer mẫu nằm trong `assets/data/help/help.json`; link có thể xem/copy, chưa mở trình duyệt.

Điểm vào: `lib/features/onboarding/presentation/onboarding_flow.dart`.

Code riêng của onboarding nằm trong thư mục đã tạo: `presentation/` chứa màn hình; `data/tracking_permission_service.dart` xử lý ATT; `models/subscription_plan.dart` chứa loại gói. Thư mục `bloc/` được giữ lại để dùng khi cần quản lý trạng thái riêng.

## Định dạng và responsive dùng chung

| Cần chỉnh | Vị trí |
| --- | --- |
| Màu giao diện | `lib/core/theme/app_colors.dart` |
| Font, cỡ chữ và kiểu chữ | `lib/core/theme/app_text_styles.dart` |
| Khoảng cách, padding và bo góc | `lib/core/theme/app_spacing.dart` |
| Theme Flutter, nút FilledButton và màu thanh hệ thống | `lib/core/theme/app_theme.dart` |
| Giới hạn chiều rộng, chiều cao nút và kích thước layout chung | `lib/core/responsive/app_layout.dart` |
| Bảng màu và chữ riêng cho hình minh họa game/quặng | `lib/core/theme/game_palette.dart`, `game_text_styles.dart`, `ore_palette.dart` |
| Nút, khung trang, căn giữa có cuộn, canvas co giãn, hình quặng | `lib/common/widgets/` |

Các feature dùng `AppColors`, `AppTextStyles`, `AppSpacing`, `AppInsets`, `AppRadii` và các widget chung. Khi thêm định dạng dùng lại, khai báo ở `core` hoặc `common` rồi sử dụng từ feature; tránh tạo theme, bảng màu, font hoặc logic responsive riêng ở từng màn. Kích thước chi tiết của hình minh họa vẫn là tham số bố cục tại nơi dùng, còn việc co giãn thực hiện qua `ResponsiveCanvas`. Nút dùng chiều cao tối thiểu để theo nội dung; `AppCenteredScrollView` cho phép cuộn trên màn ngắn hoặc khi tăng cỡ chữ.

## Callback tích hợp

```dart
OnboardingFlow(
  onPurchase: (plan) async {
    // Mua đúng product ID ứng với SubscriptionPlan.
    // Chỉ trả true sau khi xác minh entitlement.
    return false;
  },
  onRestore: () async {
    // Khôi phục và xác minh entitlement đang có.
    return false;
  },
  onComplete: () {
    // Lưu trạng thái đã xem onboarding và điều hướng về trang chính.
  },
)
```

ATT được gọi bằng `app_tracking_transparency`; `ios/Runner/Info.plist` đã khai báo `NSUserTrackingUsageDescription` và tên Find Diamonds. Hai nút trong hộp thoại quyền do iOS hiển thị và dịch theo ngôn ngữ hệ thống. Không dựng lại hộp thoại này bằng Flutter. Có thể truyền `trackingPermission` vào `OnboardingFlow` để kiểm thử.

Android không có hộp thoại ATT tương đương. AdMob rewarded hiện dùng Google UMP cho quảng cáo production; cần cấu hình Privacy & messaging trong AdMob theo `docs/monetization.md`. Việc bỏ qua ATT trên Android không cấp quyền quảng cáo cá nhân hóa. Tham khảo [ATT](https://developer.apple.com/documentation/apptrackingtransparency) và [Google UMP cho Flutter](https://developers.google.com/admob/flutter/privacy).

Chưa cài SDK thanh toán. Khi chưa truyền callback mua/khôi phục, các nút hiển thị thông báo demo và không tạo giao dịch. Giá, dữ liệu quặng và ưu đãi đang là dữ liệu mẫu từ ảnh; khi tích hợp store cần lấy giá/điều kiện từ sản phẩm thực. Trạng thái hoàn tất onboarding được lưu bằng `shared_preferences` với khóa `onboarding_completed`; xóa dữ liệu app để xem lại luồng lần đầu.

Kiểm tra ATT trên iPhone/iOS với quyền chưa được quyết định: mở app → Continue → chọn Allow hoặc Ask App Not to Track → hướng dẫn. Mở lại app để xác nhận không hỏi lại; kiểm tra thêm trường hợp quyền yêu cầu theo dõi bị tắt trong Settings. Trên Android, xác nhận vào hướng dẫn trực tiếp. Build và kiểm tra hộp thoại iOS cần macOS/Xcode và thiết bị iOS.

## Kiểm tra

```sh
flutter analyze
flutter test
flutter build web
```

Xuất ảnh preview onboarding và năm tab trong PowerShell:

```powershell
$env:CAPTURE_PREVIEWS = 'true'
flutter test
```

Ảnh được ghi vào `output/previews/`. Preview dùng quyền giả lập để chụp phần giải thích iOS. Kiểm thử bao gồm nhánh quyền iOS/Android, chờ phản hồi quyền, từ chối/đồng ý, không hỏi lại, lỗi quyền, luồng đầy đủ, vuốt, quay lại đúng bước, xem lại, chọn gói, callback mua/khôi phục, lỗi dịch vụ và màn hình 320×568 / 844×390 / 768×1024 / 1024×768. Có kiểm tra phần giải thích quyền trên màn 320×390 với cỡ chữ gấp đôi. Widget test giả lập API native; hộp thoại iOS vẫn cần kiểm tra trên thiết bị thật.

Ảnh nhân vật được tạo bằng imagegen; prompt và nguồn asset nằm trong `assets/images/README.md`. Giấy phép font nằm trong `assets/fonts/`.

Preview các tab: `08-find.png`, `09-history.png`, `10-skins.png`, `11-servers.png`, `12-maps.png` trong `output/previews/`. Kiểm thử bổ sung bao gồm đọc JSON, validation, tìm thử sang History, giữ form khi đổi tab, Favourite/filter, chi tiết seed/server, skin miễn phí/khóa, animation, điều hướng onboarding → Find và route đặt tên. Có kiểm tra bố cục ở 320×568, 844×390, 768×1024 và chữ lớn 1,5 lần.
