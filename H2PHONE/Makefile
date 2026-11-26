include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = H2PHONE
H2PHONE_FILES = main.m H2PhoneAppDelegate.m H2PhoneController.m H2PhoneAppListController.m H2ConfigManager.m
H2PHONE_CFLAGS = -fobjc-arc
H2PHONE_FRAMEWORKS = UIKit Foundation
H2PHONE_RESOURCE_DIRS = Resources
H2PHONE_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/H2PHONE/H2PHONE.entitlements

include $(THEOS_MAKE_PATH)/application.mk
