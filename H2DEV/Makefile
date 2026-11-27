include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = H2DEV
H2DEV_FILES = main.m H2DevAppDelegate.m H2DevController.m
H2DEV_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
H2DEV_FRAMEWORKS = UIKit Foundation AdSupport CoreLocation CoreTelephony CoreMotion WebKit
H2DEV_RESOURCE_DIRS = Resources
ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
H2DEV_CODESIGN_FLAGS = -S$(THEOS_PROJECT_DIR)/H2DEV/H2DEV.entitlements
endif

include $(THEOS_MAKE_PATH)/application.mk
