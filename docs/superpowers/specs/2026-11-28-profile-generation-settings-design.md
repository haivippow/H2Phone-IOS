# Profile Generation Settings Design

## Intent

Add an auto-saved settings screen that controls which Profile fields may be randomized and bounds generated iPhone models and iOS versions.

## Chosen design

- A gear button in the Dashboard navigation bar pushes `Cài đặt tạo Profile`.
- Independent toggles control Model iPhone, Phiên bản iOS, Nhà mạng, Vùng, and Ngôn ngữ & múi giờ.
- Model and iOS ranges use minimum and maximum pickers; invalid inverted ranges are normalized immediately.
- Settings auto-save locally through a dedicated `UserDefaults` service. There is no Save button.
- Every native and web fake capability implemented by the tweak appears under one of nine expandable groups. Profile-backed values are configurable; fixed hook behavior is labeled `Cố định hiện tại` rather than exposed as a non-functional toggle.
- Change confirmation summarizes the enabled random fields and chosen ranges.
- The unavailable device backend remains authoritative: the UI never reports that randomization was applied.

## Approaches considered

1. Global auto-saved settings — selected because repeated Change operations should share one predictable policy.
2. Configure inside every Change sheet — rejected because it adds repeated controls to a safety-critical confirmation flow.
3. Per-profile templates — deferred because no backend profile-generation engine exists yet.

## Constraints

- SwiftUI and iOS 16+.
- Compact layout for iPhone XS with vertical scrolling and safe-area support.
- iPhone range: iPhone 7 through the current catalog ending at iPhone 18 Pro Max.
- iOS range: 10.0 through 18.7 and the current 26.0–26.5 release family.
- Every model carries compatible minimum and maximum iOS bounds; random generation must not create impossible model/iOS pairs.
- No standalone Save button.
- No fake success when the backend is unavailable.

