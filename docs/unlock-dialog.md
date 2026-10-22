# Hộp mở khóa dùng chung cho Skin và Map

Khung và luồng quảng cáo dùng chung nằm trong `lib/common/widgets/reward_unlock_dialog.dart`:

- `RewardUnlockDialog`: nền trắng, nút đóng, hình minh họa, tiêu đề, Watch Ads, Go Ads Free with Premium và thông báo lỗi. Bố cục cuộn khi màn hình thấp hoặc chữ lớn.
- `UnlockCardIllustration`: ba thẻ minh họa xếp chồng, hai thẻ ngoài nghiêng. Truyền widget `left`, `center`, `right` để thay hình mà giữ bố cục.

Đổi khoảng cách, bo góc, kích thước, font hoặc nút trong file chung sẽ áp dụng cho cả Skin lẫn Map. `AppTextStyles.unlockTitle`, `AppTextStyles.pixelButton` và palette `AppColors` tiếp tục quản lý chữ/màu chung.

## Nội dung riêng của từng tính năng

- `lib/features/maps/presentation/map_unlock_dialog.dart`: tiêu đề World, hình thế giới và callback mở khóa map.
- `lib/features/skins/presentation/skin_unlock_dialog.dart`: tiêu đề Skin, ba nhân vật với skin đang chọn ở giữa và callback mở khóa skin.

Mỗi wrapper truyền `title`, `illustration`, `monetization`, `isLocked`, `onUnlock`, `watchToUnlockMessage`, `saveFailureMessage`, `keyPrefix`. `onUnlock` cấp quyền trong bộ nhớ và trả về việc lưu xuống thiết bị có thành công không. Hộp thoại trả `true` khi chọn Premium để màn gọi mở paywall sau khi hộp thoại đóng.

## Luồng Skins

1. Chạm bất kỳ skin nào để xem trước, kể cả skin khóa. Skin khóa có biểu tượng khóa trên preview và trong danh sách; không tự mở paywall khi chọn.
2. Bấm Share khi skin đang khóa sẽ hiện hộp **Watch Ads to Unlock Skin**.
3. Chỉ kết quả `RewardedAdResult.earned` cấp quyền cho đúng skin đã yêu cầu. Bấm Watch Ads liên tục không tạo thêm yêu cầu; trong lúc chờ quảng cáo, các nút đóng/Premium/Watch Ads đều bị khóa.
4. Đóng sớm, không có quảng cáo, lỗi SDK hoặc nền tảng không hỗ trợ đều giữ khóa và hiện thông báo để thử lại.
5. Quyền mở được lưu qua SharedPreferences với khóa `rewarded_unlocked_skins_v1`. Mở lại app vẫn giữ quyền trên thiết bị. Pro bỏ qua khóa; hết Pro chỉ khóa lại các skin chưa được thưởng.
6. Skin đã mở (miễn phí, đã nhận thưởng hoặc có Pro): Share xuất ảnh PNG của nhân vật ở góc xoay/pose đang xem rồi mở share sheet hệ thống bằng `share_plus`. Ảnh có nền trắng, không chứa tên, huy hiệu khóa, nút Idle/Walk hay giao diện app. Sau khi nhận thưởng, lần bấm Share ban đầu tiếp tục xuất ảnh. Đóng share sheet không hiện thông báo lỗi.
7. Ảnh PNG lấy từ `RepaintBoundary` chỉ bao quanh mô hình, tăng độ phân giải hướng tới cạnh dài 1024 px (tỷ lệ xuất tối đa 4x). `sharePositionOrigin` trỏ vào nút Share để hỗ trợ popover trên iPad. Khóa thao tác Share/chọn skin khi đang xuất và chờ share sheet; nếu hệ thống báo lỗi, hiện thông báo để thử lại.

Đây là ảnh xem trước nhân vật 3D, chưa phải texture skin Minecraft 64×64 để import vào game. Plugin dùng cache tạm của app để gửi ảnh; không tự ghi vào thư viện ảnh. Sau khi thêm `share_plus`, dừng app và chạy lại `flutter run` để nạp phần native; hot reload/hot restart không đủ nếu binary đang chạy chưa có plugin.

Không thay đổi đơn vị quảng cáo: Skin và Map dùng chung rewarded ad service đã có, bao gồm cache và khóa quảng cáo toàn màn hình.
