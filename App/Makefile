include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = H2Changer
H2Changer_FILES = main.m H2AppDelegate.m H2MainController.m H2AppListController.m H2BrowserController.m H2ConfigManager.m
H2Changer_CFLAGS = -fobjc-arc
H2Changer_FRAMEWORKS = UIKit Foundation WebKit
H2Changer_RESOURCE_DIRS = Resources
H2Changer_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/App/H2Changer.entitlements

include $(THEOS_MAKE_PATH)/application.mk
