include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = H2PHONE
H2PHONE_FILES = main.m H2PhoneAppDelegate.m H2PhoneController.m H2PhoneAppListController.m H2ConfigManager.m H2InstalledAppService.m
H2PHONE_SWIFT_FILES = \
    ../H2PhoneSwiftUI/App/H2PhoneApp.swift \
    ../H2PhoneSwiftUI/App/H2PhoneRootViewControllerFactory.swift \
    ../H2PhoneSwiftUI/Core/DesignSystem.swift \
    ../H2PhoneSwiftUI/Core/H2Store.swift \
    ../H2PhoneSwiftUI/Features/DashboardAndProfilesViews.swift \
    ../H2PhoneSwiftUI/Features/ProfileSettingsView.swift \
    ../H2PhoneSwiftUI/Features/TargetAppsAndOperationsViews.swift \
    ../H2PhoneSwiftUI/Models/H2Models.swift \
    ../H2PhoneSwiftUI/Models/ProfileGenerationSettings.swift \
    ../H2PhoneSwiftUI/Preview/PreviewData.swift \
    ../H2PhoneSwiftUI/Services/DeviceService.swift \
    ../H2PhoneSwiftUI/Services/ProfileSettingsService.swift
H2PHONE_CFLAGS = -fobjc-arc
H2PHONE_SWIFTFLAGS = -D THEOS
H2PHONE_SWIFT_VERSION = 5
H2PHONE_SWIFT_BRIDGING_HEADER = H2PHONE-Bridging-Header.h
H2PHONE_FRAMEWORKS = UIKit Foundation SwiftUI Combine
H2PHONE_RESOURCE_DIRS = Resources
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
H2PHONE_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/H2PHONE/H2PHONE.roothide.entitlements
else
H2PHONE_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/H2PHONE/H2PHONE.entitlements
endif

include $(THEOS_MAKE_PATH)/application.mk
