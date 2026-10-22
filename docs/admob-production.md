# Ghi chú: chuyển AdMob từ test sang quảng cáo thật

Ngày ghi chú: 22/10/2026. Trạng thái: **để làm sau, chưa cấu hình ID thật**.

## Hiện trạng

- Bản debug tự dùng Ad Unit ID test của Google trong `lib/core/monetization/ad_units.dart` và `lib/core/monetization/rewarded_ad_service.dart`, kể cả khi truyền ID thật.
- Android chưa có `ADMOB_APP_ID` trong `android/gradle.properties`, nên Gradle đang dùng App ID mẫu của Google.
- Bản release lấy Ad Unit ID từ `--dart-define`. Thiếu ID thì loại quảng cáo tương ứng không được tải; rewarded không cấp thưởng khi không có quảng cáo.
- Đã tắt bảng **AdMob native ad validator** bằng `com.google.android.gms.ads.flag.NATIVE_AD_DEBUGGER_ENABLED=false` trong `android/app/src/main/AndroidManifest.xml`. Cấu hình này chỉ ẩn bảng kiểm tra, không chuyển sang quảng cáo thật. Thay đổi manifest cần dừng rồi chạy lại app; hot reload chưa đủ.

## Thông tin cần chuẩn bị cho Android

- [ ] Chốt application ID sản phẩm. Hiện `android/app/build.gradle.kts` dùng `com.example.roblox`.
- [ ] Tạo ứng dụng Android tương ứng trong tài khoản AdMob.
- [ ] Lấy **App ID** của ứng dụng, dạng `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`.
- [ ] Tạo và lấy 5 **Ad Unit ID**: Banner, Native, Interstitial, Rewarded, App Open. Mỗi ID có dạng `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`.
- [ ] Cấu hình Privacy & messaging trong AdMob cho UMP đang tích hợp trong app.
- [ ] Kiểm tra yêu cầu xác minh ứng dụng, app-ads.txt và trạng thái xét duyệt trong AdMob trước khi phát hành.

**App ID có dấu `~`; Ad Unit ID có dấu `/`. Hai loại ID không dùng thay nhau.**

## Cấu hình và build Android khi đã có ID

1. Thêm App ID thật vào `android/gradle.properties`:

   ```properties
   ADMOB_APP_ID=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
   ```

   `android/app/build.gradle.kts` đã truyền giá trị này vào manifest qua `${admobAppId}`.

2. Thay toàn bộ giá trị `ID_...` trong lệnh dưới bằng Ad Unit ID thật đúng loại, rồi chạy từ thư mục gốc dự án bằng PowerShell:

   ```powershell
   flutter build appbundle --release `
     --dart-define=ADMOB_BANNER_ANDROID="ID_BANNER" `
     --dart-define=ADMOB_NATIVE_ANDROID="ID_NATIVE" `
     --dart-define=ADMOB_INTERSTITIAL_ANDROID="ID_INTERSTITIAL" `
     --dart-define=ADMOB_REWARDED_ANDROID="ID_REWARDED" `
     --dart-define=ADMOB_APP_OPEN_ANDROID="ID_APP_OPEN"
   ```

   Đây là mẫu lệnh, chưa chạy được với các giá trị giữ chỗ. Kết quả build mặc định: `build/app/outputs/bundle/release/app-release.aab`.

3. Khi chuẩn bị đưa lên Google Play, cấu hình khóa ký release; hiện build release vẫn dùng khóa debug trong `android/app/build.gradle.kts`.

## Kiểm tra sau khi cấu hình

- Khi phát triển vẫn chạy debug để dùng quảng cáo test. Nếu kiểm tra bản release với ID riêng, đăng ký thiết bị test trước; dùng quảng cáo test để kiểm tra tương tác.
- Kiểm tra Banner, Native ở Maps, Interstitial khi đủ điều kiện, Rewarded và App Open theo [tài liệu monetization](monetization.md).
- Xác nhận luồng consent UMP và Ad privacy choices hoạt động trên thiết bị.
- Có ID thật không đảm bảo quảng cáo xuất hiện ngay; kiểm tra trạng thái ứng dụng và lỗi tải quảng cáo trong AdMob/log nếu chưa có quảng cáo.

## Nếu phát hành iOS

Thay App ID mẫu ở `GADApplicationIdentifier` trong `ios/Runner/Info.plist` bằng App ID iOS. Tạo Ad Unit ID riêng cho iOS và build trên macOS/Xcode với các biến `ADMOB_BANNER_IOS`, `ADMOB_NATIVE_IOS`, `ADMOB_INTERSTITIAL_IOS`, `ADMOB_REWARDED_IOS`, `ADMOB_APP_OPEN_IOS`. Xem thêm [monetization.md](monetization.md).

## Tài liệu tham khảo

- [Thiết lập AdMob cho Flutter](https://developers.google.com/admob/flutter/quick-start)
- [Quảng cáo test và thiết bị test](https://developers.google.com/admob/flutter/test-ads)
- [Consent UMP cho Flutter](https://developers.google.com/admob/flutter/privacy)
- [Trạng thái sẵn sàng của ứng dụng](https://support.google.com/admob/answer/10564477)
- [Native ad validator](https://developers.google.com/admob/android/native/validator)
