import SwiftUI

#if !THEOS
@main
struct H2PhoneApp: App {
    @StateObject private var store = H2Store(service: UnavailableDeviceService())
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store) }
    }
}
#endif
