include $(THEOS)/makefiles/common.mk

TWEAK_NAME = H2PHONEHook
H2PHONEHook_FILES = Tweak.xm H2WebFingerprint.m ../H2PHONE/H2ConfigManager.m
H2PHONEHook_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -I$(THEOS_PROJECT_DIR)/H2PHONE
H2PHONEHook_FRAMEWORKS = UIKit Foundation WebKit AdSupport CoreLocation CoreTelephony CoreMotion SystemConfiguration

include $(THEOS_MAKE_PATH)/tweak.mk
