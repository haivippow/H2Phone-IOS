# H2PHONE SwiftUI

`H2PhoneSwiftUI/` chứa giao diện H2PHONE viết bằng SwiftUI cho iOS 16+. Target Theos `H2PHONE` biên dịch các file này và AppDelegate mở `RootView` thông qua `UIHostingController`; controller UIKit cũ vẫn được giữ làm mã tương thích trong repository.

## Cấu trúc

- `App/`: điểm vào ứng dụng `H2PhoneApp`.
- `Models/`: model Profile, ứng dụng mục tiêu và trạng thái thao tác.
- `Core/`: store dùng chung và design system.
- `Services/`: giao thức tích hợp thiết bị cùng implementation chưa khả dụng an toàn.
- `Features/`: Dashboard, lịch sử Profile, ứng dụng mục tiêu và các sheet thao tác.
- `Preview/`: dữ liệu mẫu dành cho preview giao diện.

## Build

Trên macOS có Xcode và XcodeGen:

```sh
xcodegen generate
xcodebuild -project H2PHONE.xcodeproj -scheme H2PHONE -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Để chạy trên iPhone XS iOS 16.1, cần provisioning/signing thích hợp. Máy Windows hiện tại không có Xcode nên chưa kiểm thử build hay thiết bị.

## Dữ liệu và tích hợp

`PreviewData` chỉ dùng để xem giao diện. `UnavailableDeviceService` không quét ứng dụng, backup, reset, thay đổi profile hay rollback; các thao tác này hiển thị **Chưa khả dụng** và không đánh dấu thành công. Cấu hình toggle tồn tại trong bộ nhớ trong phiên UI. Khi tích hợp thật, thay `DeviceService` bằng adapter tới `H2ConfigManager` hoặc controller trên thiết bị; service phải chỉ trả về thành công sau khi xác minh backup/khôi phục và hoàn tất toàn bộ bước, không xóa dữ liệu nếu backup thất bại. Manifest backup cần ghi bundle ID, kích thước, trạng thái xác minh để sheet rollback liệt kê chính xác dữ liệu sẽ khôi phục. Cấu trúc service độc lập cho phép thêm kênh Windows C# sau này.
