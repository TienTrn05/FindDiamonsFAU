# Test Pro và quảng cáo thưởng

Ghi chú triển khai sau: [Chuyển AdMob sang quảng cáo thật](admob-production.md) — hiện chưa cấu hình ID thật; có danh sách ID cần chuẩn bị và lệnh build Android đầy đủ 5 loại quảng cáo.

## Hành vi đã nối

- Chạm ngoài input Find hoặc kéo form: bỏ focus, đóng bàn phím.
- Khi entitlement Pro được xác minh: ẩn Go Pro, Help chiếm toàn bộ chiều rộng hàng; kết quả quặng hiện đầy đủ.
- Free: kết quả đầu tiên miễn phí. Khi vào Find, app tải trước một quảng cáo rewarded của AdMob và giữ sẵn trong bộ nhớ, tận dụng thời gian nhập form. Màn kết quả tiếp tục dùng chung cache này. Show another dùng quảng cáo đã tải; chỉ callback `onUserEarnedReward` mới cấp thêm đúng một kết quả, hiển thị sau khi đóng quảng cáo và chạy animation.
- Đóng trước khi nhận thưởng, mất mạng, không có quảng cáo hoặc lỗi SDK: không mở thêm kết quả; có thông báo và cho thử lại. Không yêu cầu người dùng click quảng cáo.
- Trong lúc tải/hiện quảng cáo, nút bị khóa để tránh mở nhiều quảng cáo. Quảng cáo tải xong sau khi rời trang sẽ không tự bật.
- History lưu đầy đủ kết quả mỗi lần digging vào JSON trên thiết bị. Bấm card History mở toàn bộ vị trí đã lưu; luồng digging mới vẫn dùng cơ chế Free/Pro/rewarded. Xem [Digging, History và Seeds](digging-history.md) để biết cấu trúc DB tạm và cách kiểm tra.

## Chạy thử trên Android/iOS

```sh
flutter pub get
flutter devices
flutter run -d <device-id> --dart-define=SKIP_ONBOARDING=true
```

Phải stop rồi chạy lại sau khi thêm plugin native; hot reload không cài được SDK.

1. Nhập X, Z, seed; chạm tiêu đề hoặc vùng ngoài ô để kiểm tra bàn phím đóng, nội dung vẫn còn.
2. Nhập form Find → Start digging → một kết quả. Quảng cáo đã bắt đầu tải nền từ lúc vào Find; bấm Show another. Nếu đã tải xong thì quảng cáo có nhãn Test Ad hiện ngay, không gửi yêu cầu tải lại. Xem đến khi nhận thưởng rồi đóng. Kết quả tăng đúng một, app chuẩn bị quảng cáo tiếp theo nếu còn kết quả để mở.
3. Thử đóng sớm khi quảng cáo cho phép: nếu SDK chưa cấp thưởng thì số kết quả giữ nguyên. Một số mẫu test không cho đóng sớm hoặc cấp thưởng nhanh; dùng widget test để kiểm tra chắc chắn nhánh không nhận thưởng.
4. Tắt mạng rồi thử lại: không mở thêm kết quả. Bật mạng để thử lại.
5. Bấm liên tục khi đang tải: chỉ có một yêu cầu. Quay về Main khi đang tải: quảng cáo không tự hiện sau khi rời trang.
6. Mở lại kết quả qua History: thấy toàn bộ vị trí đã lưu; đóng/mở lại app để kiểm tra lịch sử còn trên thiết bị.

Debug luôn dùng rewarded test unit của Google, không phụ thuộc ID production truyền vào:

| Nền tảng | Rewarded test ad unit |
| --- | --- |
| Android | `ca-app-pub-3940256099942544/5224354917` |
| iOS | `ca-app-pub-3940256099942544/1712485313` |

Không cần tài khoản AdMob để thử các sample ID. SDK này chạy Android/iOS; trên web/desktop nút thông báo không hỗ trợ và không cấp thưởng. Quảng cáo test không tạo doanh thu. Bản debug dùng sample ads nên không yêu cầu UMP cho quảng cáo thật.

## Test giao diện Pro mà không thanh toán

```sh
flutter run -d <device-id> --dart-define=SKIP_ONBOARDING=true --dart-define=DEBUG_PRO=true
```

Help phải rộng bằng tổng hàng Help + Go Pro cũ; Go Pro không còn; màn kết quả hiện toàn bộ. Bỏ `DEBUG_PRO` rồi chạy lại để về Free. Cờ này chỉ có tác dụng trong debug, bị bỏ qua trong profile/release. Đây là mô phỏng entitlement, không tạo giao dịch hay lưu trạng thái đã mua.

## Áp dụng thanh toán thật

App hiện chưa có SDK billing, product ID, tài khoản store hoặc backend xác minh giao dịch. Nút mua mặc định vẫn thông báo chưa kết nối; không tự coi việc bấm mua là thành công.

`MyApp` nhận một `AppMonetization` dùng chung cho onboarding, paywall, Help/Restore, Find và kết quả. Ví dụ nối dịch vụ billing đã có:

```dart
final access = AppMonetization(
  isPro: verifiedInitialEntitlement,
  onPurchase: (plan) async {
    // Ánh xạ SubscriptionPlan sang product ID đã tạo trên store.
    // Mua bằng billing SDK, xác minh receipt/token và entitlement.
    return await billing.purchaseAndVerify(plan);
  },
  onRestore: () async => await billing.restoreAndVerify(),
);
runApp(MyApp(monetization: access));

// Khi store/backend báo hết hạn, hoàn tiền hoặc đổi tài khoản:
access.updateEntitlement(false);
```

`billing` và `verifiedInitialEntitlement` là ví dụ cho dịch vụ của bạn, không phải API có sẵn trong dự án. Callback chỉ trả `true` sau xác minh. App tự cập nhật UI khi callback mua/restore thành công. Lúc khởi động lại, lấy entitlement từ store/backend rồi cập nhật controller; không dùng SharedPreferences làm bằng chứng mua hàng.

Để test mua thật, cần cấu hình sản phẩm và tài khoản thử của Google Play/App Store theo môi trường store; debug Pro ở trên chỉ kiểm tra giao diện.

## Chạy quảng cáo thật khi phát hành

1. Tạo app Android/iOS trong AdMob đúng application ID/bundle ID thực tế và tạo ad unit loại **Rewarded** cho mỗi nền tảng. Android hiện vẫn dùng `com.example.roblox`, cần đổi thành ID sản phẩm trước phát hành.
2. App ID chứa dấu `~`, ad unit ID chứa dấu `/`; không dùng lẫn.
3. Android: thêm `ADMOB_APP_ID=ca-app-pub-...~...` vào `android/gradle.properties`. Manifest nhận giá trị qua Gradle; mặc định hiện là Google sample App ID.
4. iOS: thay giá trị `GADApplicationIdentifier` trong `ios/Runner/Info.plist` bằng App ID iOS. Hoàn thiện cấu hình SKAdNetwork theo hướng dẫn Google cho SDK đang dùng; cần macOS/Xcode để build/test iOS.
5. Cấu hình Privacy & messaging trong AdMob. Bản production gọi UMP trước yêu cầu quảng cáo đầu tiên của phiên và kiểm tra `canRequestAds()`. Help hiện nút Ad privacy choices khi UMP yêu cầu. ATT hiện có là quyền riêng của iOS, không thay thế UMP.
6. Build với ad unit thật tương ứng:

```sh
flutter build appbundle --release --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-.../...
flutter build ipa --release --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-.../...
```

Thiếu ad unit production: ứng dụng báo chưa có quảng cáo và không cấp kết quả. Trước khi test bằng unit thật, đăng ký thiết bị test trong AdMob. Luôn dùng quảng cáo test khi phát triển.

SDK đang dùng yêu cầu Android API 24 trở lên; cấu hình minSdk đã cập nhật. Quảng cáo rewarded được tải trước ngay từ Find và sau mỗi lần xem, nhưng chỉ hiển thị khi người dùng chủ động bấm Show another.

## Banner, Special Offer và interstitial

### Quảng cáo khi vừa mở app

App dùng **App Open Ad** ngay trên màn loading khi khởi động, trước Find/onboarding. Bắt đầu khởi tạo và tải sau frame đầu tiên; quảng cáo hiện ngay khi SDK tải xong trong thời gian chờ. Chỉ thử một lần mỗi lần khởi động; hot reload, chuyển tab hoặc quay lại từ quảng cáo không làm hiện lại. Pro và các nền tảng web/desktop bỏ qua.

Màn loading giữ phía dưới cho đến khi quảng cáo được đóng. App chỉ chờ khởi tạo/tải tối đa **5 giây**, dùng chung khoảng thời gian splash 3 giây hiện có; thời gian xem quảng cáo không bị giới hạn bởi timer này. Nếu mạng lỗi, không có quảng cáo, app chuyển nền hoặc đã rời màn khởi động, đi tiếp vào ứng dụng và hủy callback tải muộn. Thời điểm nút đóng của quảng cáo vẫn do SDK quyết định.

Debug dùng App Open test ID: Android `ca-app-pub-3940256099942544/9257395921`, iOS `ca-app-pub-3940256099942544/5575463023`. Stop rồi F5 để test quảng cáo khi mở app; hot reload không tạo lần khởi động mới. Khi release, cấu hình ad unit loại **App Open** và truyền `--dart-define=ADMOB_APP_OPEN_ANDROID=ca-app-pub-.../...` hoặc `--dart-define=ADMOB_APP_OPEN_IOS=ca-app-pub-.../...` cùng các ID quảng cáo khác. Thiếu ID production thì bỏ qua.

Sau khi đóng quảng cáo khởi động, bộ đếm interstitial bắt đầu từ đầu; hai loại quảng cáo không hiện chồng nhau. Nội dung và banner chỉ được dựng sau khi xử lý xong quảng cáo khởi động. Tham khảo [App Open Flutter](https://developers.google.com/admob/flutter/app-open).

### Các vị trí trong ứng dụng

- Banner adaptive nằm ngay trên thanh điều hướng dưới ở cả năm tab, có khoảng cách với các nút nav. Ẩn khi bàn phím đang mở, không có quảng cáo hoặc tài khoản có Pro. SDK tự chọn chiều cao theo màn hình, và quản lý refresh theo cấu hình AdMob.
- Maps chèn thẻ **Special Offer** sau hai mục đầu. Nội dung, biểu tượng, thông tin app, nút cài đặt và AdChoices do **native ad template của Google** hiển thị. Khi người dùng bấm phần tương tác của quảng cáo, SDK xử lý đích đến thật: có thể là trang App Store/Google Play hoặc website do mẫu quảng cáo quyết định. Trên iOS, SDK có thể mở trang sản phẩm trong sheet như ảnh tham chiếu. Không dựng trang App Store giả hay hardcode app Block Craft. Với màn quá hẹp cho template (vùng quảng cáo dưới 320 dp), thẻ native được ẩn.
- Interstitial được tải trước và đủ điều kiện sau **180 giây sử dụng ở foreground**. Chỉ hiện ở lần chuyển tab hoặc hoàn tất tìm kiếm tiếp theo; không bật giữa lúc đang nhập form/đọc nội dung, không hiện khi mở hay thoát app.
- Thời gian app ở nền, đang có quảng cáo toàn màn hình hoặc đang có Pro không được tính. Sau khi đóng một quảng cáo toàn màn hình, bắt đầu tính lại ba phút, tránh hai loại quảng cáo bật liền nhau. **Không có cooldown 15 giây.**
- Nếu interstitial chưa tải xong, bị lỗi hay đã hết hạn, điều hướng vẫn chạy ngay. Quảng cáo tải xong muộn chỉ dùng ở lần chuyển tiếp theo, không tự bật sau khi nội dung mới đã hiện. Rewarded và interstitial dùng chung khóa để không chồng lên nhau.
- **15 giây để đóng** là yêu cầu về nút đóng, không phải tần suất. SDK/mẫu quảng cáo quyết định nút đóng; Flutter không thể đặt chính xác 15 giây, thêm lớp chặn nút đóng hoặc tự đóng interstitial. Tham khảo [AdMob về thời điểm được đóng quảng cáo](https://support.google.com/admob/answer/6066980) và [high-engagement ads](https://support.google.com/admob/answer/15525707). Đây là cấu hình của AdMob, không có `closeAfter=15` trong code.

Để thử nhanh, Stop phiên debug, chọn **Flutter Ads (quick test)** trong Run and Debug rồi F5. Profile này bỏ onboarding và rút mốc đủ điều kiện xuống **10 giây**, chỉ ở debug. Chờ 10 giây rồi chuyển tab để thử interstitial. Cấu hình **Flutter** dùng ba phút như bình thường; **Flutter Pro (test)** ẩn banner, Special Offer và interstitial. Profile test không thay đổi thời điểm nút đóng của SDK.

Các ID test hiện dùng:

| Loại | Android | iOS |
| --- | --- | --- |
| Adaptive banner | `ca-app-pub-3940256099942544/9214589741` | `ca-app-pub-3940256099942544/2435281174` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` | `ca-app-pub-3940256099942544/4411468910` |
| Native Special Offer | `ca-app-pub-3940256099942544/2247696110` | `ca-app-pub-3940256099942544/3986624511` |

Khi release, truyền thêm ad unit ID thật. Thiếu ID của loại nào thì loại đó được ẩn/bỏ qua:

```sh
flutter build appbundle --release --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-.../... --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-.../... --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-.../... --dart-define=ADMOB_NATIVE_ANDROID=ca-app-pub-.../...
```

iOS dùng các biến tương ứng `ADMOB_REWARDED_IOS`, `ADMOB_BANNER_IOS`, `ADMOB_INTERSTITIAL_IOS`, `ADMOB_NATIVE_IOS`. Tất cả loại quảng cáo dùng chung consent/khởi tạo SDK; Help vẫn là nơi mở Ad privacy choices khi UMP yêu cầu. Banner, native và interstitial không hỗ trợ web/desktop và được ẩn ở những nền tảng đó.

Kiểm tra trên thiết bị: banner nằm phía trên nav và không che nội dung; mở Maps để thấy Special Offer; bấm CTA của quảng cáo test để kiểm tra đích đến SDK; thử chuyển nền rồi quay lại để xác nhận bộ đếm tạm dừng; thử Pro để xác nhận không còn quảng cáo. Không dùng quảng cáo thật để test tương tác.

## Cache quảng cáo và thời gian chờ

- Chỉ giữ tối đa một quảng cáo đã tải trong bộ nhớ qua SDK; không tự lưu file video. Mỗi quảng cáo chỉ được hiển thị một lần. Cache được dùng chung trong phiên ứng dụng.
- Nếu nhiều nơi cùng yêu cầu tải hoặc người dùng bấm trong lúc tải trước, app dùng chung một yêu cầu tải.
- Nếu quảng cáo chưa sẵn sàng, mỗi lần bấm chỉ chờ tối đa 5 giây rồi báo thử lại. Quá trình tải nền có thể tiếp tục (tối đa 20 giây cho lượt tải quảng cáo); khi tải xong sẽ đợi lần bấm tiếp theo, không tự bật muộn.
- Quảng cáo giữ quá 55 phút bị hủy và tải mới ở lần chuẩn bị/hiển thị tiếp theo, trước giới hạn hết hạn một giờ theo hướng dẫn Google. Không có vòng lặp tải liên tục khi không dùng.
- Chuyển sang Pro hoặc hủy controller sẽ xóa cache; callback tải cũ không thể khôi phục cache đã hủy. Đổi tùy chọn quyền riêng tư cũng xóa quảng cáo đã chuẩn bị.
- Lần vào trang đầu tiên, mạng yếu hoặc AdMob chưa có quảng cáo vẫn có thể phải chờ. Cache giảm thời gian chờ khi bấm bằng cách bắt đầu tải sớm; không thay đổi tốc độ server hay thời lượng video.

## Mở khóa map bằng rewarded ads

Skin và Map hiện dùng chung `RewardUnlockDialog` cùng bố cục ba thẻ minh họa; mỗi tính năng truyền tiêu đề, hình và callback cấp quyền riêng. Với Skin: chọn skin khóa để xem trước → Share → Watch Ads hoặc Premium; quyền thưởng lưu tại `rewarded_unlocked_skins_v1`. Xem [hướng dẫn widget dùng chung](unlock-dialog.md) để thay hình/chữ/bố cục.

Chạm map khóa trong Maps để mở trang chi tiết (ảnh, mô tả, yêu thích), rồi bấm **Unlock World**. Hộp thoại có **Watch Ads** để mở riêng map đang xem và **Go Ads Free with Premium** để tới paywall. Rewarded dùng chung cache với Show another, bắt đầu tải trước khi vào trang chi tiết. Chỉ kết quả `RewardedAdResult.earned` từ SDK mới cấp quyền; đóng sớm, không có quảng cáo, lỗi mạng hoặc nền tảng không hỗ trợ đều giữ khóa. Trong lúc chờ, các nút bị vô hiệu hóa để tránh yêu cầu trùng.

Quyền mở từng map được lưu bằng `shared_preferences` tại `rewarded_unlocked_maps_v1`, còn dùng được sau khi khởi động lại. Xóa dữ liệu/gỡ app sẽ xóa quyền này; chưa có đồng bộ tài khoản. Nếu ghi bộ nhớ thất bại, map vẫn mở trong phiên hiện tại và app thông báo không lưu được. Pro truy cập tất cả map mà không cần xem quảng cáo; Pro hết hạn chỉ khóa lại những map chưa từng nhận thưởng.

Test Android/iOS bằng cấu hình **Flutter Ads (quick test)**: Maps → map khóa → Unlock World → Watch Ads → hoàn thành quảng cáo test → xác nhận World Unlocked, trở lại danh sách và mở lại app. Thử đóng sớm để xác nhận vẫn khóa; dùng **Flutter Pro (test)** để kiểm tra bỏ qua quảng cáo. Xóa dữ liệu app nếu muốn thử lại map đã mở. Web/desktop chỉ kiểm tra được giao diện và thông báo không hỗ trợ rewarded.

Catalog hiện là dữ liệu demo, chưa chứa file `.mcworld` hay URL tải map. Vì vậy sau khi mở khóa, UI hiện **World Unlocked** và thông báo chưa có bản tải xuống; chưa thực hiện cài/import map. `gallery` và `features` trong JSON là các danh sách tùy chọn cho ảnh và mô tả gạch đầu dòng; thiếu chúng thì dùng ảnh bìa và mô tả có sẵn. Hiện mỗi map chỉ có một ảnh bìa mẫu; có thể thêm ảnh thật vào `gallery` để cuộn ngang nhiều ảnh.

## Kiểm thử tự động

```sh
flutter analyze
flutter test
```

Widget test dùng dịch vụ quảng cáo giả để kiểm tra việc cấp kết quả mà không tải quảng cáo thật. Việc hiển thị video, vòng đời native và consent cần kiểm tra thêm trên thiết bị Android/iOS.

Tài liệu: [Rewarded ads](https://developers.google.com/admob/flutter/rewarded), [Test ads](https://developers.google.com/admob/flutter/test-ads), [UMP Flutter](https://developers.google.com/admob/flutter/privacy), [SDK setup](https://developers.google.com/admob/flutter/quick-start).
