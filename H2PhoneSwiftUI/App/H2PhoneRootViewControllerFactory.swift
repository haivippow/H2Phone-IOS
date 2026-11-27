import SwiftUI
import UIKit

@objc(H2PhoneRootViewControllerFactory)
public final class H2PhoneRootViewControllerFactory: NSObject {
    @MainActor
    @objc public static func makeRootViewController() -> UIViewController {
        let store = H2Store(service: InstalledAppDeviceService(), apps: [])
        let rootView = RootView().environmentObject(store)
        return UIHostingController(rootView: rootView)
    }
}
