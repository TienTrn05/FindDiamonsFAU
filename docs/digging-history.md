# Digging, History và giao diện Seeds

## Luồng đã nối

1. Find → Start digging → nhận kết quả từ `FindRepository`.
2. `AppShell` chờ `HistoryBloc.record()` lưu bản ghi rồi mở màn Found Ores.
3. History hiển thị mỗi lần tìm kiếm thành một card: icon loại quặng của kết quả đầu tiên, seed, tọa độ X/Z đã nhập và phiên bản. Bản ghi mới nhất nằm trên cùng.
4. Bấm card History chỉ mở các vị trí đã được mở khóa, không chạy lại digging. Lượt đào miễn phí mở ngẫu nhiên 1–2 vị trí; Show another cần nhận thưởng quảng cáo để mở thêm một vị trí; Show all yêu cầu Pro. `revealedCount` được lưu theo từng bản ghi và giữ nguyên khi khởi động lại.
5. Chạm card quặng mở bảng chọn Found / Not found. Card Found có nền giấy nhạt và dấu mộc FOUND đỏ đóng nghiêng lên vùng icon quặng, giữ rõ tọa độ và số lượng. Không có checkbox hoặc tag bên ngoài. Trạng thái `found` được lưu theo từng vị trí, giữ nguyên khi mở lại History và có thể đổi về Not found để bỏ dấu mộc.

Mỗi lần digging hiện chỉ tìm một loại quặng, nên icon của card cũng là loại quặng xuất hiện ở dòng kết quả đầu tiên.

## JSON làm DB tạm

Android/iOS/desktop dùng file **`history.json` trong thư mục Application Support riêng của ứng dụng**, lấy qua `path_provider`. Đây là file ghi lúc chạy app, không phải `assets/data/history/history.json`; file asset chỉ cung cấp trạng thái ban đầu. Web lưu cùng cấu trúc JSON vào local storage qua SharedPreferences với khóa `digging_history_json_v1`.

Ví dụ một bản ghi:

```json
{
  "schemaVersion": 1,
  "emptyMessage": "No searches made yet!",
  "searches": [
    {
      "id": "example-search",
      "seed": "918272",
      "playerX": 1,
      "playerZ": 2,
      "version": "1.20 Bedrock",
      "oreId": "diamond",
      "oreName": "Diamond",
      "positions": [
        { "x": 63, "y": -54, "z": 34, "count": 3, "found": true },
        { "x": 40, "y": -41, "z": 30, "count": 9, "found": false }
      ],
      "revealedCount": 1,
      "createdAt": "2026-10-22T12:00:00.000Z"
    }
  ]
}
```

Seed luôn là chuỗi để giữ nguyên seed dài hoặc chứa chữ. Lưu đủ danh sách vị trí theo đúng thứ tự của lần tìm kiếm. Các thao tác thêm/xóa được xếp hàng; bản ghi trùng `id` được cập nhật. File được ghi hoàn chỉnh vào `history.json.tmp`, flush rồi thay file chính. Nếu ghi thất bại, app thông báo và vẫn mở kết quả; dữ liệu vừa thay đổi chỉ còn trong bộ nhớ cho đến khi ghi thành công. File JSON hỏng được báo lỗi, không tự ghi đè nội dung cũ.

Lịch sử còn sau khi đóng/mở app; xóa dữ liệu hoặc gỡ app sẽ mất lịch sử trên thiết bị. Chưa có đồng bộ tài khoản. Khi có backend, thay implementation của `HistoryRepository`; giao diện không phụ thuộc cách lưu vật lý.

## Mục Seeds trong Maps

Danh mục hiện tại: Seeds, Favourite, SkyBlock, Horror, Maze, Parkour, Mini game, Challenges. Mở mặc định ở Seeds. The Wings thuộc Challenges; Warehouse I/II thuộc Horror; SkyBlock Islands thuộc SkyBlock; Emerald Valley và Cliffside Village thuộc Seeds. Maze, Parkour và Mini game chưa có dữ liệu. Mục trống hiển thị `there is no item in "<tên danh mục đang chọn>"` ở giữa vùng nội dung bằng font pixel đang dùng, có bản dịch theo ngôn ngữ ứng dụng.

Card **Emerald Valley** (seed `36643745`) là mẫu mô tả dài để xem bố cục: làng gần điểm xuất hiện, núi, thác nước, hang động, hồ và tiền đồn. Đây là nội dung demo chưa xác minh trong thế giới Minecraft thật; đã có bản dịch cho 8 ngôn ngữ của app.

- Seed dùng card dọc chỉ để đọc: ảnh lớn phía trên, tên, seed kèm nút copy, phiên bản và toàn bộ mô tả. Bấm vùng nội dung card không mở màn hình hay bottom sheet; các nút copy/yêu thích vẫn hoạt động riêng.
- Mục Seeds có bộ lọc phiên bản Bedrock/Java, xếp 3 hàng theo thứ tự 4–5–2 nút như ảnh tham chiếu; hàng giữa dài nhất, hàng cuối ngắn nhất. Bộ lọc không cuộn riêng. Bấm lại phiên bản đã chọn để bỏ lọc.
- Header, thanh danh mục và bộ lọc có thể cuộn lên cùng danh sách để dành phần màn hình còn lại cho card. Không cắt mô tả hoặc ép chiều cao card để vừa màn hình.
- Phiên bản hỗ trợ của từng seed được khai báo bằng mảng `versions` trong `assets/data/maps/maps.json`. Thẻ yêu thích vẫn hoạt động; seed vẫn dùng card dọc khi xuất hiện trong Favourite.
- Các mục map khác giữ card ngang và luồng mở khóa hiện có.

Catalog seed, ảnh và dữ liệu vị trí quặng hiện vẫn là **demo**. Nhãn phiên bản trong JSON là dữ liệu mẫu cho bộ lọc, chưa phải xác nhận seed có cấu trúc tương ứng trong Minecraft thật. `JsonFindRepository` hiện tạo tọa độ từ các offset mẫu, chưa tính thế giới Minecraft theo seed. Lịch sử lưu chính xác các kết quả demo mà app đã trả về.

## Kiểm tra

```sh
flutter analyze
flutter test test/history_repository_test.dart test/navigation_test.dart test/app_translations_test.dart
```

Kiểm tra trên thiết bị: đào một lần → mở History → bấm card xem toàn bộ → đóng/mở lại app → xác nhận card còn → xóa card → đóng/mở lại xác nhận đã xóa. Trong Maps → Seeds, chọn phiên bản, copy seed và thêm Favourite.
